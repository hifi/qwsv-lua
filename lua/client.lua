--[[
    client.qc

    client functions

    Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to:

        Free Software Foundation, Inc.
        59 Temple Place - Suite 330
        Boston, MA  02111-1307, USA

]]

local modelindex_eyes, modelindex_player

--[[
=============================================================================

                LEVEL CHANGING / INTERMISSION

=============================================================================
]]

local nextmap

intermission_running = 0 -- used in player.lua
local intermission_exittime = 0

--[[
QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
]]
function info_intermission()
    self.angles = self.mangle -- so C can get at it
end


function SetChangeParms()
    if self.health <= 0 then
        SetNewParms ()
        return;
    end

    -- remove items
    self.items = self.items - (self.items &
    (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD) )

    -- cap super health
    if self.health > 100 then
        self.health = 100
    elseif self.health < 50 then
        self.health = 50
    end

    parm1 = self.items
    parm2 = self.health
    parm3 = self.armorvalue
    if self.ammo_shells < 25 then
        parm4 = 25
    else
        parm4 = self.ammo_shells
    end
    parm5 = self.ammo_nails
    parm6 = self.ammo_rockets
    parm7 = self.ammo_cells
    parm8 = self.weapon
    parm9 = self.armortype * 100
end

function SetNewParms()
    parm1 = IT_SHOTGUN | IT_AXE
    parm2 = 100
    parm3 = 0
    parm4 = 25
    parm5 = 0
    parm6 = 0
    parm7 = 0
    parm8 = 1
    parm9 = 0
end

function DecodeLevelParms()
    if serverflags > 0 then
        if world.model == "maps/start.bsp" then
            SetNewParms () -- take away all stuff on starting new episode
        end
    end

    self.items = parm1
    self.health = parm2
    self.armorvalue = parm3
    self.ammo_shells = parm4
    self.ammo_nails = parm5
    self.ammo_rockets = parm6
    self.ammo_cells = parm7
    self.weapon = parm8
    self.armortype = parm9 * 0.01
end

--[[
============
FindIntermission

Returns the entity to view from
============
]]
function FindIntermission()
    local spot
    local cyc

    -- look for info_intermission first
    spot = find (world, "classname", "info_intermission")
    if spot then
        -- pick a random one
        cyc = random() * 4
        while cyc > 1 do
            spot = find (spot, "classname", "info_intermission")
            if not spot then
                spot = find (spot, "classname", "info_intermission")
            end
            cyc = cyc - 1
        end
        return spot
    end

    -- then look for the start position
    spot = find (world, "classname", "info_player_start")
    if spot then
        return spot
    end

    objerror ("FindIntermission: no spot")
end

function GotoNextMap()
    local newmap

    --ZOID: 12-13-96, samelevel is overloaded, only 1 works for same level
    if cvar("samelevel") == 1 then
        -- if samelevel is set, stay on same level
        changelevel (mapname)
    else
        -- configurable map lists, see if the current map exists as a
        -- serverinfo/localinfo var
        newmap = infokey(world, mapname)
        if newmap and #newmap > 0 then
            changelevel (newmap)
        else
            changelevel (nextmap)
        end
    end
end

--[[
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
]]
function IntermissionThink()
    if time < intermission_exittime then
        return
    end

    if self.button0 == 0 and self.button1 == 0 and self.button2 == 0 then
        return
    end

    GotoNextMap ()
end

--[[
============
execute_changelevel

The global "nextmap" has been set previously.
Take the players to the intermission spot
============
]]
function execute_changelevel()
    local pos

    intermission_running = 1

    -- enforce a wait time before allowing changelevel
    intermission_exittime = time + 5

    pos = FindIntermission ()

    -- play intermission music
    WriteByte (MSG_ALL, SVC_CDTRACK)
    WriteByte (MSG_ALL, 3)

    WriteByte (MSG_ALL, SVC_INTERMISSION)
    WriteCoord (MSG_ALL, pos.origin.x)
    WriteCoord (MSG_ALL, pos.origin.y)
    WriteCoord (MSG_ALL, pos.origin.z)
    WriteAngle (MSG_ALL, pos.mangle.x)
    WriteAngle (MSG_ALL, pos.mangle.y)
    WriteAngle (MSG_ALL, pos.mangle.z)

    other = find (world, "classname", "player")
    while other and other ~= world do
        other.takedamage = DAMAGE_NO
        other.solid = SOLID_NOT
        other.movetype = MOVETYPE_NONE
        other.modelindex = 0
        other = find (other, "classname", "player")
    end
end

function changelevel_touch()
    local pos

    if other.classname ~= "player" then
        return
    end

    -- if "noexit" is set, blow up the player trying to leave
    --ZOID, 12-13-96, noexit isn't supported in QW.  Overload samelevel
    if cvar("samelevel") == 2 or (cvar("samelevel") == 3 and mapname ~= "start") then
        T_Damage (other, self, self, 50000)
        return
    end

    bprint (PRINT_HIGH, other.netname)
    bprint (PRINT_HIGH," exited the level\n")

    nextmap = self.map

    SUB_UseTargets ()

    self.touch = SUB_Null

    -- we can't move people right now, because touch functions are called
    -- in the middle of C movement code, so set a think time to do it
    self.think = execute_changelevel
    self.nextthink = time + 0.1
end

--[[
QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
]]
function trigger_changelevel()
    if not self.map or #self.map == 0 then
        objerror ("chagnelevel trigger doesn't have map")
    end

    InitTrigger ()
    self.touch = changelevel_touch
end

--[[
=============================================================================

                PLAYER GAME EDGE FUNCTIONS

=============================================================================
]]

-- called by ClientKill and DeadThink
function respawn()
    -- make a copy of the dead body for appearances sake
    CopyToBodyQue (self)
    -- set default spawn parms
    SetNewParms ()
    -- respawn
    PutClientInServer ()
end


--[[
============
ClientKill

Player entered the suicide command
============
]]
function ClientKill()
    bprint (PRINT_MEDIUM, self.netname)
    bprint (PRINT_MEDIUM, " suicides\n")
    set_suicide_frame ()
    self.modelindex = modelindex_player
    logfrag (self, self)
    self.frags = self.frags - 2 -- extra penalty
    respawn ()
end

--[[
============
SelectSpawnPoint

Returns the entity to spawn at
============
]]
function SelectSpawnPoint()
    local spot, newspot, thing
    local numspots, totalspots
    local rnum, pcount
    local rs
    local spots

    numspots = 0
    totalspots = 0

    -- testinfo_player_start is only found in regioned levels
    spot = find (world, "classname", "testplayerstart");
    if spot then
        return spot
    end

    -- choose a info_player_deathmatch point
    -- ok, find all spots that don't have players nearby

    spots = world
    spot = find (world, "classname", "info_player_deathmatch")
    while spot do
        totalspots = totalspots + 1
        pcount = 0

        for thing in findradius(spot.origin, 84) do
            if thing.classname == "player" then
                pcount = pcount + 1
            end
        end

        if pcount == 0 then
            spot.goalentity = spots
            spots = spot
            numspots = numspots + 1
        end

        -- Get the next spot in the chain
        spot = find (spot, "classname", "info_player_deathmatch")
    end

    totalspots = totalspots - 1;
    if numspots == 0 then
        -- ack, they are all full, just pick one at random
        -- bprint (PRINT_HIGH, "Ackk! All spots are full. Selecting random spawn spot\n");
        totalspots = rint((random() * totalspots))
        spot = find (world, "classname", "info_player_deathmatch")
        while totalspots > 0 do
            totalspots = totalspots - 1
            spot = find (spot, "classname", "info_player_deathmatch")
        end
        return spot
    end

    -- We now have the number of spots available on the map in numspots
    -- Generate a random number between 1 and numspots

    numspots = numspots - 1

    numspots = rint((random() * numspots ) )

    spot = spots
    while numspots > 0 do
        spot = spot.goalentity
        numspots = numspots - 1
    end

    return spot
end

--[[
===========
PutClientInServer

called each time a player enters a new level
============
--]]
function PutClientInServer()
    local spot;
    local s;

    self.classname = "player"
    self.health = 100
    self.takedamage = DAMAGE_AIM
    self.solid = SOLID_SLIDEBOX
    self.movetype = MOVETYPE_WALK
    self.show_hostile = 0
    self.max_health = 100
    self.flags = FL_CLIENT
    self.air_finished = time + 12
    self.dmg = 2 -- initial water damage
    self.super_damage_finished = 0
    self.radsuit_finished = 0
    self.invisible_finished = 0
    self.invincible_finished = 0
    self.effects = 0
    self.invincible_time = 0

    -- fields from original defs that need a default value
    self.walkframe = 0
    self.jump_flag = 0
    self.super_time = 0
    self.super_sound = 0
    self.dmgtime = 0
    self.swim_flag = 0
    self.pain_finished = 0
    self.invisible_sound = 0
    self.invincible_sound = 0

    DecodeLevelParms ()

    W_SetCurrentAmmo ()

    self.attack_finished = time
    self.th_pain = player_pain
    self.th_die = PlayerDie

    self.deadflag = DEAD_NO
    -- paustime is set by teleporters to keep the player from moving a while
    self.pausetime = 0

    spot = SelectSpawnPoint ()

    self.origin = spot.origin + vec3(0,0,1)
    self.angles = spot.angles
    self.fixangle = true -- turn this way immediately

    -- oh, this is a hack!
    setmodel (self, "progs/eyes.mdl")
    modelindex_eyes = self.modelindex

    setmodel (self, "progs/player.mdl")
    modelindex_player = self.modelindex

    setsize (self, VEC_HULL_MIN, VEC_HULL_MAX)

    self.view_ofs = vec3(0,0,22)

    -- Mod - Xian (May.20.97)
    -- Bug where player would have velocity from their last kill

    self.velocity = vec3(0,0,0)

    player_stand1 ()

    spawn_tfog (self.origin + (makevectors(self.angles)) * 20)

    spawn_tdeath (self.origin, self)

    -- Set Rocket Jump Modifiers
    if tonumber(infokey(world, "rj")) then
        rj = tonumber(infokey(world, "rj"))
    end

    if deathmatch == 4 then
        self.ammo_shells = 0
        if (tonumber(infokey(world, "axe")) or 0) == 0 then
            self.ammo_nails = 255
            self.ammo_shells = 255
            self.ammo_rockets = 255
            self.ammo_cells = 255
            self.items = self.items | IT_NAILGUN
            self.items = self.items | IT_SUPER_NAILGUN
            self.items = self.items | IT_SUPER_SHOTGUN
            self.items = self.items | IT_ROCKET_LAUNCHER
            self.items = self.items | IT_LIGHTNING
        end
        self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3
        self.armorvalue = 200
        self.armortype = 0.8
        self.health = 250
        self.items = self.items | IT_INVULNERABILITY
        self.invincible_time = 1
        self.invincible_finished = time + 3
    elseif deathmatch == 5 then
        self.ammo_nails = 80
        self.ammo_shells = 30
        self.ammo_rockets = 10
        self.ammo_cells = 30
        self.items = self.items | IT_NAILGUN
        self.items = self.items | IT_SUPER_NAILGUN
        self.items = self.items | IT_SUPER_SHOTGUN
        self.items = self.items | IT_ROCKET_LAUNCHER
        self.items = self.items | IT_GRENADE_LAUNCHER
        self.items = self.items | IT_LIGHTNING
        self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3
        self.armorvalue = 200
        self.armortype = 0.8
        self.health = 200
        self.items = self.items | IT_INVULNERABILITY
        self.invincible_time = 1
        self.invincible_finished = time + 3
    end
end


--[[
=============================================================================

                QUAKED FUNCTIONS

=============================================================================
--]]


--[[
QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
]]
function info_player_start()
end


--[[
QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
]]
function info_player_start2()
end

--[[
QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
]]
function info_player_deathmatch()
end

--[[
QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
]]
function info_player_coop()
end

--[[
===============================================================================

RULES

===============================================================================
==
]]

--[[
go to the next level for deathmatch
]]
function NextLevel()
    local o
    local newmap

    if nextmap and #nextmap > 0 then
        return -- already done
    end

    if mapname == "start" then
        if cvar("registered") == 0 then
            mapname = "e1m1";
        elseif (serverflags & 1) == 0 then
            mapname = "e1m1"
            serverflags = serverflags | 1
        elseif (serverflags & 2) == 0 then
            mapname = "e2m1"
            serverflags = serverflags | 2
        elseif (serverflags & 4) == 0 then
            mapname = "e3m1"
            serverflags = serverflags | 4
        elseif (serverflags & 8) == 0 then
            mapname = "e4m1"
            serverflags = serverflags - 7
        end

        o = spawn()
        o.map = mapname
    else
        -- find a trigger changelevel
        o = find(world, "classname", "trigger_changelevel")
        if not o or mapname == "start" then
            -- go back to same map if no trigger_changelevel
            o = spawn()
            o.map = mapname
        end
    end

    nextmap = o.map

    if o.nextthink < time then
        o.think = execute_changelevel
        o.nextthink = time + 0.1
    end
end

--[[
============
CheckRules

Exit deathmatch games upon conditions
============
]]
function CheckRules()
    if timelimit > 0 and time >= timelimit then
        NextLevel ()
    end

    if fraglimit > 0 and self.frags >= fraglimit then
        NextLevel ()
    end
end

--============================================================================

function PlayerDeathThink()
    local old_self
    local forward

    if (self.flags & FL_ONGROUND) > 0 then
        forward = #self.velocity
        forward = forward - 20
        if forward <= 0 then
            self.velocity = vec3(0,0,0)
        else
            self.velocity = forward * normalize(self.velocity)
        end
    end

    -- wait for all buttons released
    if self.deadflag == DEAD_DEAD then
        if self.button2 > 0 or self.button1 > 0 or self.button0 > 0 then
            return
        end
        self.deadflag = DEAD_RESPAWNABLE
        return
    end

    -- wait for any button down
    if self.button2 == 0 and self.button1 == 0 and self.button0 == 0 then
        return
    end

    self.button0 = 0
    self.button1 = 0
    self.button2 = 0
    respawn()
end

function PlayerJump()
    if (self.flags & FL_WATERJUMP) > 0 then
        return
    end

    if self.waterlevel >= 2 then
        -- play swiming sound
        if self.swim_flag < time then
            self.swim_flag = time + 1
            if (random() < 0.5) then
                sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM)
            else
                sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM)
            end
        end

        return
    end

    if (self.flags & FL_ONGROUND) == 0 then
        return
    end

    if (self.flags & FL_JUMPRELEASED) == 0 then
        return -- don't pogo stick
    end

    self.flags = self.flags - (self.flags & FL_JUMPRELEASED)
    self.button2 = 0

    -- player jumping sound
    sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM)
end

--[[
===========
WaterMove

============
]]
function WaterMove()
    if self.movetype == MOVETYPE_NOCLIP then
        return
    end
    if self.health < 0 then
        return
    end

    if self.waterlevel ~= 3 then
        if self.air_finished < time then
            sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM)
        elseif self.air_finished < time + 9 then
            sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM)
        end
        self.air_finished = time + 12
        self.dmg = 2
    elseif self.air_finished < time then
        -- drown!
        if self.pain_finished < time then
            self.dmg = self.dmg + 2
            if self.dmg > 15 then
                self.dmg = 10
            end
            T_Damage (self, world, world, self.dmg)
            self.pain_finished = time + 1
        end
    end

    if self.waterlevel == 0 then
        if (self.flags & FL_INWATER) > 0 then
            -- play leave water sound
            sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM)
            self.flags = self.flags - FL_INWATER
        end
        return
    end

    if self.watertype == CONTENT_LAVA then
        -- do damage
        if self.dmgtime < time then
            if self.radsuit_finished > time then
                self.dmgtime = time + 1
            else
                self.dmgtime = time + 0.2
            end

            T_Damage (self, world, world, 10*self.waterlevel)
        end
    elseif self.watertype == CONTENT_SLIME then
        -- do damage
        if self.dmgtime < time and self.radsuit_finished < time then
            self.dmgtime = time + 1
            T_Damage (self, world, world, 4*self.waterlevel)
        end
    end

    if (self.flags & FL_INWATER) == 0 then
        -- player enter water sound

        if self.watertype == CONTENT_LAVA then
            sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM)
        elseif self.watertype == CONTENT_WATER then
            sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM)
        elseif self.watertype == CONTENT_SLIME then
            sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM)
        end

        self.flags = self.flags + FL_INWATER
        self.dmgtime = 0
    end
end

--[[
================
PlayerPreThink

Called every frame before physics are run
================
]]
function PlayerPreThink()
    local mspeed, aspeed
    local r

    if intermission_running > 0 then
        IntermissionThink() -- otherwise a button could be missed between
        return -- the think tics
    end

    if self.view_ofs == vec3(0,0,0) then
        return -- intermission or finale
    end

    self.deathtype = ""

    CheckRules ()
    WaterMove ()

    if self.deadflag >= DEAD_DEAD then
        PlayerDeathThink ()
        return
    end

    if self.deadflag == DEAD_DYING then
        return -- dying, so do nothing
    end

    if self.button2 > 0 then
        PlayerJump ()
    else
        self.flags = self.flags | FL_JUMPRELEASED
    end

    -- teleporters can force a non-moving pause time
    if time < self.pausetime then
        self.velocity = vec3(0,0,0)
    end

    if time > self.attack_finished and self.currentammo == 0 and self.weapon ~= IT_AXE then
        self.weapon = W_BestWeapon ()
        W_SetCurrentAmmo ()
    end
end

--[[
================
CheckPowerups

Check for turning off powerups
================
]]
function CheckPowerups()
    if self.health <= 0 then
        return
    end

    -- invisibility
    if self.invisible_finished > 0 then
        -- sound and screen flash when items starts to run out
        if self.invisible_sound < time then
            sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE)
            self.invisible_sound = time + ((random() * 3) + 1)
        end

        if self.invisible_finished < time + 3 then
            if self.invisible_time == 1 then
                sprint (self, PRINT_HIGH, "Ring of Shadows magic is fading\n")
                stuffcmd (self, "bf\n")
                sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM)
                self.invisible_time = time + 1
            end

            if self.invisible_time < time then
                self.invisible_time = time + 1
                stuffcmd (self, "bf\n")
            end
        end

        if self.invisible_finished < time then
            -- just stopped
            self.items = self.items - IT_INVISIBILITY
            self.invisible_finished = 0
            self.invisible_time = 0
        end

        -- use the eyes
        self.frame = 0
        self.modelindex = modelindex_eyes
    else
        -- don't use eyes
        self.modelindex = modelindex_player
    end

    -- invincibility
    if self.invincible_finished > 0 then
        -- sound and screen flash when items starts to run out
        if self.invincible_finished < time + 3 then
            if self.invincible_time == 1 then
                sprint (self, PRINT_HIGH, "Protection is almost burned out\n")
                stuffcmd (self, "bf\n")
                sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM)
                self.invincible_time = time + 1
            end

            if self.invincible_time < time then
                self.invincible_time = time + 1
                stuffcmd (self, "bf\n")
            end
        end

        if self.invincible_finished < time then
            -- just stopped
            self.items = self.items - IT_INVULNERABILITY
            self.invincible_time = 0
            self.invincible_finished = 0
        end

        if self.invincible_finished > time then
            self.effects = self.effects | EF_DIMLIGHT
            self.effects = self.effects | EF_RED
        else
            self.effects = self.effects - (self.effects & EF_DIMLIGHT)
            self.effects = self.effects - (self.effects & EF_RED)
        end
    end

    -- super damage
    if self.super_damage_finished > 0 then
        -- sound and screen flash when items starts to run out
        if self.super_damage_finished < time + 3 then
            if self.super_time == 1 then
                if deathmatch == 4 then
                    sprint (self, PRINT_HIGH, "OctaPower is wearing off\n")
                else
                    sprint (self, PRINT_HIGH, "Quad Damage is wearing off\n")
                end
                stuffcmd (self, "bf\n")
                sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM)
                self.super_time = time + 1
            end

            if self.super_time < time then
                self.super_time = time + 1
                stuffcmd (self, "bf\n")
            end
        end

        if self.super_damage_finished < time then
            -- just stopped
            self.items = self.items - IT_QUAD
            if deathmatch == 4 then
                self.ammo_cells = 255
                self.armorvalue = 1
                self.armortype = 0.8
                self.health = 100
            end
            self.super_damage_finished = 0
            self.super_time = 0
        end

        if self.super_damage_finished > time then
            self.effects = self.effects | EF_DIMLIGHT
            self.effects = self.effects | EF_BLUE
        else
            self.effects = self.effects - (self.effects & EF_DIMLIGHT)
            self.effects = self.effects - (self.effects & EF_BLUE)
        end
    end

    -- suit
    if self.radsuit_finished > 0 then
        self.air_finished = time + 12 -- don't drown

        -- sound and screen flash when items starts to run out
        if self.radsuit_finished < time + 3 then
            if self.rad_time == 1 then
                sprint (self, PRINT_HIGH, "Air supply in Biosuit expiring\n")
                stuffcmd (self, "bf\n")
                sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM)
                self.rad_time = time + 1
            end

            if self.rad_time < time then
                self.rad_time = time + 1
                stuffcmd (self, "bf\n")
            end
        end

        if self.radsuit_finished < time then
            -- just stopped
            self.items = self.items - IT_SUIT
            self.rad_time = 0
            self.radsuit_finished = 0
        end
    end
end

--[[
================
PlayerPostThink

Called every frame after physics are run
================
]]
function PlayerPostThink()
    local mspeed, aspeed
    local r

    --dprint ("post think\n");
    if self.view_ofs == vec3(0,0,0) then
        return -- intermission or finale
    end
    if self.deadflag > 0 then
        return
    end

    -- check to see if player landed and play landing sound
    if (self.jump_flag < -300) and (self.flags & FL_ONGROUND) > 0 then
        if self.watertype == CONTENT_WATER then
            sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM)
        elseif self.jump_flag < -650 then
            self.deathtype = "falling"
            T_Damage (self, world, world, 5)
            sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM)
        else
            sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM)
        end
    end

    self.jump_flag = self.velocity.z

    CheckPowerups ()

    W_WeaponFrame ()
end

--[[
===========
ClientConnect

called when a player connects to a server
============
]]
function ClientConnect()
    bprint (PRINT_HIGH, self.netname)
    bprint (PRINT_HIGH, " entered the game\n")

    -- a client connecting during an intermission can cause problems
    if intermission_running > 0 then
        GotoNextMap ()
    end
end


--[[
===========
ClientDisconnect

called when a player disconnects from a server
============
]]
function ClientDisconnect()
    -- let everyone else know
    bprint (PRINT_HIGH, self.netname)
        bprint (PRINT_HIGH, " left the game with ")
        bprint (PRINT_HIGH, tostring(math.floor(self.frags)))
        bprint (PRINT_HIGH, " frags\n")
    sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE)
    set_suicide_frame ()
end

--[[
===========
ClientObituary

called when a player dies
============
]]
function ClientObituary(targ, attacker)
    local rnum
    local deathstring, deathstring2
    local s
    local attackerteam, targteam

    rnum = random()
    --ZOID 12-13-96: self.team doesn't work in QW.  Use keys
    attackerteam = infokey(attacker, "team")
    targteam = infokey(targ, "team")

    if targ.classname == "player" then
        if deathmatch > 3 then
            if targ.deathtype == "selfwater" then
                bprint (PRINT_MEDIUM, targ.netname)
                bprint (PRINT_MEDIUM," electrocutes himself.\n ")
                targ.frags = targ.frags - 1
                return
            end
        end

        if attacker.classname == "teledeath" then
            bprint (PRINT_MEDIUM,targ.netname)
            bprint (PRINT_MEDIUM," was telefragged by ")
            bprint (PRINT_MEDIUM,attacker.owner.netname)
            bprint (PRINT_MEDIUM,"\n")
            logfrag (attacker.owner, targ)

            attacker.owner.frags = attacker.owner.frags + 1
            return
        end

        if attacker.classname == "teledeath2" then
            bprint (PRINT_MEDIUM,"Satan's power deflects ")
            bprint (PRINT_MEDIUM,targ.netname)
            bprint (PRINT_MEDIUM,"'s telefrag\n")

            targ.frags = targ.frags - 1
            logfrag (targ, targ)
            return
        end

        -- double 666 telefrag (can happen often in deathmatch 4)
        if attacker.classname == "teledeath3" then
            bprint (PRINT_MEDIUM,targ.netname)
            bprint (PRINT_MEDIUM," was telefragged by ")
            bprint (PRINT_MEDIUM,attacker.owner.netname)
            bprint (PRINT_MEDIUM, "'s Satan's power\n")
            targ.frags = targ.frags - 1
            logfrag (targ, targ)
            return
        end

        if targ.deathtype == "squish" then
            if teamplay > 0 and targteam == attackerteam and attackerteam ~= "" and targ ~= attacker then
                logfrag (attacker, attacker)
                attacker.frags = attacker.frags - 1;
                bprint (PRINT_MEDIUM,attacker.netname)
                bprint (PRINT_MEDIUM," squished a teammate\n")
                return
            elseif attacker.classname == "player" and attacker ~= targ then
                bprint (PRINT_MEDIUM, attacker.netname)
                bprint (PRINT_MEDIUM," squishes ")
                bprint (PRINT_MEDIUM,targ.netname)
                bprint (PRINT_MEDIUM,"\n")
                logfrag (attacker, targ)
                attacker.frags = attacker.frags + 1
                return
            else
                logfrag (targ, targ)
                targ.frags = targ.frags - 1 -- killed self
                bprint (PRINT_MEDIUM,targ.netname)
                bprint (PRINT_MEDIUM," was squished\n")
                return
            end
        end

        if attacker.classname == "player" then
            if targ == attacker then
                -- killed self
                logfrag (attacker, attacker)
                attacker.frags = attacker.frags - 1
                bprint (PRINT_MEDIUM,targ.netname)
                if targ.deathtype == "grenade" then
                    bprint (PRINT_MEDIUM," tries to put the pin back in\n")
                elseif targ.deathtype == "rocket" then
                    bprint (PRINT_MEDIUM," becomes bored with life\n")
                elseif targ.weapon == 64 and targ.waterlevel > 1 then
                    if targ.watertype == CONTENT_SLIME then
                        bprint (PRINT_MEDIUM," discharges into the slime\n")
                    elseif targ.watertype == CONTENT_LAVA then
                        bprint (PRINT_MEDIUM," discharges into the lava\n")
                    else
                        bprint (PRINT_MEDIUM," discharges into the water.\n")
                    end
                else
                    bprint (PRINT_MEDIUM," becomes bored with life\n")
                end
                return
            elseif teamplay == 2 and targteam == attackerteam and attackerteam ~= "" then
                if rnum < 0.25 then
                    deathstring = " mows down a teammate\n"
                elseif rnum < 0.50 then
                    deathstring = " checks his glasses\n"
                elseif rnum < 0.75 then
                    deathstring = " gets a frag for the other team\n"
                else
                    deathstring = " loses another friend\n"
                end
                bprint (PRINT_MEDIUM, attacker.netname)
                bprint (PRINT_MEDIUM, deathstring)
                attacker.frags = attacker.frags - 1
                --ZOID 12-13-96:  killing a teammate logs as suicide
                logfrag (attacker, attacker)
                return
            else
                logfrag (attacker, targ)
                attacker.frags = attacker.frags + 1

                rnum = attacker.weapon
                if targ.deathtype == "nail" then
                    deathstring = " was nailed by "
                    deathstring2 = "\n"
                elseif targ.deathtype == "supernail" then
                    deathstring = " was punctured by "
                    deathstring2 = "\n"
                elseif targ.deathtype == "grenade" then
                    deathstring = " eats "
                    deathstring2 = "'s pineapple\n"
                    if targ.health < -40 then
                        deathstring = " was gibbed by "
                        deathstring2 = "'s grenade\n"
                    end
                elseif targ.deathtype == "rocket" then
                    if attacker.super_damage_finished > 0 and targ.health < -40 then
                        rnum = random()
                        if rnum < 0.3 then
                            deathstring = " was brutalized by "
                        elseif rnum < 0.6 then
                            deathstring = " was smeared by "
                        else
                            bprint (PRINT_MEDIUM, attacker.netname)
                            bprint (PRINT_MEDIUM, " rips ")
                            bprint (PRINT_MEDIUM, targ.netname)
                            bprint (PRINT_MEDIUM, " a new one\n")
                            return
                        end
                        deathstring2 = "'s quad rocket\n"
                    else
                        deathstring = " rides "
                        deathstring2 = "'s rocket\n"
                        if targ.health < -40 then
                            deathstring = " was gibbed by "
                            deathstring2 = "'s rocket\n"
                        end
                    end
                elseif rnum == IT_AXE then
                    deathstring = " was ax-murdered by "
                    deathstring2 = "\n"
                elseif rnum == IT_SHOTGUN then
                    deathstring = " chewed on "
                    deathstring2 = "'s boomstick\n"
                elseif rnum == IT_SUPER_SHOTGUN then
                    deathstring = " ate 2 loads of "
                    deathstring2 = "'s buckshot\n"
                elseif rnum == IT_LIGHTNING then
                    deathstring = " accepts "
                    if attacker.waterlevel > 1 then
                        deathstring2 = "'s discharge\n"
                    else
                        deathstring2 = "'s shaft\n"
                    end
                end
                bprint (PRINT_MEDIUM,targ.netname)
                bprint (PRINT_MEDIUM,deathstring)
                bprint (PRINT_MEDIUM,attacker.netname)
                bprint (PRINT_MEDIUM,deathstring2)
            end
            return
        else
            logfrag (targ, targ)
            targ.frags = targ.frags - 1 -- killed self
            rnum = targ.watertype

            bprint (PRINT_MEDIUM,targ.netname)
            if rnum == -3 then
                if random() < 0.5 then
                    bprint (PRINT_MEDIUM," sleeps with the fishes\n")
                else
                    bprint (PRINT_MEDIUM," sucks it down\n")
                end
                return
            elseif rnum == -4 then
                if random() < 0.5 then
                    bprint (PRINT_MEDIUM," gulped a load of slime\n")
                else
                    bprint (PRINT_MEDIUM," can't exist on slime alone\n")
                end
                return
            elseif rnum == -5 then
                if targ.health < -15 then
                    bprint (PRINT_MEDIUM," burst into flames\n");
                    return
                end
                if random() < 0.5 then
                    bprint (PRINT_MEDIUM," turned into hot slag\n")
                else
                    bprint (PRINT_MEDIUM," visits the Volcano God\n")
                end
                return
            end

            if attacker.classname == "explo_box" then
                bprint (PRINT_MEDIUM," blew up\n")
                return
            end

            if targ.deathtype == "falling" then
                bprint (PRINT_MEDIUM," fell to his death\n")
                return
            end

            if targ.deathtype == "nail" or targ.deathtype == "supernail" then
                bprint (PRINT_MEDIUM," was spiked\n")
                return
            end

            if targ.deathtype == "laser" then
                bprint (PRINT_MEDIUM," was zapped\n")
                return
            end

            if attacker.classname == "fireball" then
                bprint (PRINT_MEDIUM," ate a lavaball\n")
                return
            end

            if attacker.classname == "trigger_changelevel" then
                bprint (PRINT_MEDIUM," tried to leave\n")
                return
            end

            bprint (PRINT_MEDIUM," died\n")
        end
    end
end
