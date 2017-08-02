--[[
    doors.qc

    door functions

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

--]]

local DOOR_START_OPEN = 1
local DOOR_DONT_LINK = 4
local DOOR_GOLD_KEY = 8
local DOOR_SILVER_KEY = 16
local DOOR_TOGGLE = 32

--[[

Doors are similar to buttons, but can spawn a fat trigger field around them
to open without a touch, and they link together to form simultanious
double/quad doors.
 
Door.owner is the master door.  If there is only one door, it points to itself.
If multiple doors, all will point to a single one.

Door.enemy chains from the master door through all doors linked in the chain.

--]]

--[[
=============================================================================

THINK FUNCTIONS

=============================================================================
--]]

function door_blocked()
    other.deathtype = "squish"
    T_Damage (other, self, self.goalentity, self.dmg)

    -- if a door has a negative wait, it would never come back if blocked,
    -- so let it just squash the object to death real fast
    if self.wait >= 0 then
        if self.state == STATE_DOWN then
            door_go_up ()
        else
            door_go_down ()
        end
    end
end

function door_hit_top()
    sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self.noise1, 1, ATTN_NORM)
    self.state = STATE_TOP
    if (self.spawnflags & DOOR_TOGGLE) > 0 then
        return -- don't come down automatically
    end
    self.think = door_go_down
    self.nextthink = self.ltime + self.wait
end

function door_hit_bottom()
    sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self.noise1, 1, ATTN_NORM)
    self.state = STATE_BOTTOM
end

function door_go_down()
    sound (self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    if self.max_health > 0 then
        self.takedamage = DAMAGE_YES
        self.health = self.max_health
    end
    
    self.state = STATE_DOWN
    SUB_CalcMove (self.pos1, self.speed, door_hit_bottom)
end

function door_go_up()
    if self.state == STATE_UP then
        return -- allready going up
    end

    if self.state == STATE_TOP then
        -- reset top wait time
        self.nextthink = self.ltime + self.wait
        return
    end
    
    sound (self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    self.state = STATE_UP
    SUB_CalcMove (self.pos2, self.speed, door_hit_top)

    SUB_UseTargets()
end


--[[
=============================================================================

ACTIVATION FUNCTIONS

=============================================================================
--]]

function door_fire()
    local oself
    local starte

    if self.owner ~= self then
        objerror ("door_fire: self.owner != self")
    end

    -- play use key sound
    if self.items > 0 then
        sound (self, CHAN_VOICE, self.noise4, 1, ATTN_NORM)
    end

    self.message = string_null -- no more message
    oself = self

    if (self.spawnflags & DOOR_TOGGLE) > 0 then
        if self.state == STATE_UP or self.state == STATE_TOP then
            starte = self;
            --[[ XXX: check this
            do
            {
                door_go_down ()
                self = self.enemy
            } while ( (self != starte) && (self != world) )
            --]]
            door_go_down()
            self = self.enemy
            while self ~= starte and self ~= world do
                door_go_down ()
                self = self.enemy
            end
            self = oself
            return
        end
    end
    
    -- trigger all paired doors
    starte = self
    
    --[[ XXX: check this
    do
    {
        self.goalentity = activator;        // Who fired us
        door_go_up ();
        self = self.enemy;
    } while ( (self != starte) && (self != world) );
    --]]
    self.goalentity = activator -- Who fired us
    door_go_up ()
    self = self.enemy
    while self ~= starte and self ~= world do
        self.goalentity = activator -- Who fired us
        door_go_up ()
        self = self.enemy
    end
    self = oself
end


function door_use()
    local oself

    self.message = ""  -- door message are for touch only
    self.owner.message = ""        
    self.enemy.message = ""

    oself = self
    self = self.owner
    door_fire ()
    self = oself
end


function door_trigger_touch()
    if other.health <= 0 then
        return
    end

    if time < self.attack_finished then
        return
    end
    self.attack_finished = time + 1

    activator = other

    self = self.owner
    door_use ()
end


function door_killed()
    local oself
    
    oself = self
    self = self.owner
    self.health = self.max_health
    self.takedamage = DAMAGE_NO -- wil be reset upon return
    door_use ()
    self = oself
end


--[[
================
door_touch

Prints messages and opens key doors
================
--]]
function door_touch()
    if other.classname ~= "player" then
        return
    end
    if self.owner.attack_finished > time then
        return
    end

    self.owner.attack_finished = time + 2

    if self.owner.message and #self.owner.message > 0 then
        centerprint (other, self.owner.message)
        sound (other, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NORM)
    end
    
    -- key door stuff
    if self.items == 0 then
        return
    end

    -- FIXME: blink key on player's status bar
    if (self.items & other.items) ~= self.items then
        if self.owner.items == IT_KEY1 then
            if world.worldtype == 2 then
                centerprint (other, "You need the silver keycard")
                sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            elseif world.worldtype == 1 then
                centerprint (other, "You need the silver runekey")
                sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            elseif world.worldtype == 0 then
                centerprint (other, "You need the silver key")
                sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            end
        else
            if world.worldtype == 2 then
                centerprint (other, "You need the gold keycard")
                sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            elseif world.worldtype == 1 then
                centerprint (other, "You need the gold runekey")
                sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)                    
            elseif world.worldtype == 0 then
                centerprint (other, "You need the gold key")
                sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            end
        end
        return
    end

    other.items = other.items - self.items
    self.touch = SUB_Null
    if self.enemy then
        self.enemy.touch = SUB_Null -- get paired door
    end
    door_use ()
end

--[[
=============================================================================

SPAWNING FUNCTIONS

=============================================================================
--]]

function spawn_field(fmins, fmaxs)
    local trigger
    local t1, t2

    trigger = spawn()
    trigger.movetype = MOVETYPE_NONE
    trigger.solid = SOLID_TRIGGER
    trigger.owner = self
    trigger.touch = door_trigger_touch

    t1 = fmins
    t2 = fmaxs
    setsize (trigger, t1 - vec3(60,60,8), t2 + vec3(60,60,8))
    return (trigger)
end

function EntitiesTouching(e1, e2)
    if e1.mins.x > e2.maxs.x then
        return false
    end
    if e1.mins.y > e2.maxs.y then
        return false
    end
    if e1.mins.z > e2.maxs.z then
        return false
    end
    if e1.maxs.x < e2.mins.x then
        return false
    end
    if e1.maxs.y < e2.mins.y then
        return false
    end
    if e1.maxs.z < e2.mins.z then
        return false
    end

    return true
end


--[[
=============
LinkDoors


=============
--]]
function LinkDoors()
    local t, starte
    local cmins, cmaxs

    if self.enemy then
        return -- already linked by another door
    end

    if (self.spawnflags & 4) > 0 then
        self.enemy = self
        self.owner = self.enemy
        return -- don't want to link this door
    end

    cmins = self.mins
    cmaxs = self.maxs
    
    starte = self
    t = self
    
    while true do
        self.owner = starte -- master door

        if self.health > 0 then
            starte.health = self.health
        end
        if self.targetname and #self.targetname > 0 then
            starte.targetname = self.targetname
        end
        if not self.message and self.message ~= "" then
            starte.message = self.message
        end

        t = find (t, "classname", self.classname)
        if not t then
            self.enemy = starte -- make the chain a loop

            -- shootable, fired, or key doors just needed the owner/enemy links,
            -- they don't spawn a field
    
            self = self.owner;

            if self.health > 0 then
                return
            end
            if self.targetname and #self.targetname > 0 then
                return
            end
            if self.items > 0 then
                return
            end

            self.owner.trigger_field = spawn_field(cmins, cmaxs)

            return
        end

        if EntitiesTouching(self, t) then
            if t.enemy then
                objerror ("cross connected doors");
            end
            
            self.enemy = t
            self = t

            if t.mins.x < cmins.x then
                cmins.x = t.mins.x
            end
            if t.mins.y < cmins.y then
                cmins.y = t.mins.y
            end
            if t.mins.z < cmins.z then
                cmins.z = t.mins.z
            end
            if t.maxs.x > cmaxs.x then
                cmaxs.x = t.maxs.x
            end
            if t.maxs.y > cmaxs.y then
                cmaxs.y = t.maxs.y
            end
            if t.maxs.z > cmaxs.z then
                cmaxs.z = t.maxs.z
            end
        end
    end
end

--[[
QUAKED func_door (0 .5 .8) ? START_OPEN x DOOR_DONT_LINK GOLD_KEY SILVER_KEY TOGGLE
if two doors touch, they are assumed to be connected and operate as a unit.

TOGGLE causes the door to wait in both the start and end states for a trigger event.

START_OPEN causes the door to move to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not usefull for touch or takedamage doors).

Key doors are allways wait -1.

"message"       is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"         determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"        if set, door must be shot open
"speed"         movement speed (100 default)
"wait"          wait before returning (3 default, -1 = never return)
"lip"           lip remaining at end of move (8 default)
"dmg"           damage to inflict when blocked (2 default)
"sounds"
0)      no sound
1)      stone
2)      base
3)      stone chain
4)      screechy metal
--]]
function func_door()
    if world.worldtype == 0 then
        precache_sound ("doors/medtry.wav")
        precache_sound ("doors/meduse.wav")
        self.noise3 = "doors/medtry.wav"
        self.noise4 = "doors/meduse.wav"
    elseif world.worldtype == 1 then
        precache_sound ("doors/runetry.wav")
        precache_sound ("doors/runeuse.wav")
        self.noise3 = "doors/runetry.wav"
        self.noise4 = "doors/runeuse.wav"
    elseif world.worldtype == 2 then
        precache_sound ("doors/basetry.wav")
        precache_sound ("doors/baseuse.wav")
        self.noise3 = "doors/basetry.wav"
        self.noise4 = "doors/baseuse.wav"
    else
        dprint ("no worldtype set!\n")
    end
    if self.sounds == 0 then
        precache_sound ("misc/null.wav")
        precache_sound ("misc/null.wav")
        self.noise1 = "misc/null.wav"
        self.noise2 = "misc/null.wav"
    elseif self.sounds == 1 then
        precache_sound ("doors/drclos4.wav")
        precache_sound ("doors/doormv1.wav")
        self.noise1 = "doors/drclos4.wav"
        self.noise2 = "doors/doormv1.wav"
    elseif self.sounds == 2 then
        precache_sound ("doors/hydro1.wav")
        precache_sound ("doors/hydro2.wav")
        self.noise2 = "doors/hydro1.wav"
        self.noise1 = "doors/hydro2.wav"
    elseif self.sounds == 3 then
        precache_sound ("doors/stndr1.wav")
        precache_sound ("doors/stndr2.wav")
        self.noise2 = "doors/stndr1.wav"
        self.noise1 = "doors/stndr2.wav"
    elseif self.sounds == 4 then
        precache_sound ("doors/ddoor1.wav")
        precache_sound ("doors/ddoor2.wav")
        self.noise1 = "doors/ddoor2.wav"
        self.noise2 = "doors/ddoor1.wav"
    end

    SetMovedir ()

    self.max_health = self.health
    self.solid = SOLID_BSP
    self.movetype = MOVETYPE_PUSH
    setorigin (self, self.origin)  
    setmodel (self, self.model)
    self.classname = "door"

    self.blocked = door_blocked
    self.use = door_use
    
    if (self.spawnflags & DOOR_SILVER_KEY) > 0 then
        self.items = IT_KEY1
    end
    if (self.spawnflags & DOOR_GOLD_KEY) > 0 then
        self.items = IT_KEY2
    end
    
    if not self.speed or self.speed == 0 then
        self.speed = 100
    end
    if not self.wait or self.wait == 0 then
        self.wait = 3
    end
    if not self.lip or self.lip == 0 then
        self.lip = 8
    end
    if not self.dmg or self.dmg == 0 then
        self.dmg = 2
    end

    self.pos1 = self.origin
    self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip)

    -- DOOR_START_OPEN is to allow an entity to be lighted in the closed position
    -- but spawn in the open position
    if (self.spawnflags & DOOR_START_OPEN) > 0 then
        setorigin (self, self.pos2)
        self.pos2 = self.pos1
        self.pos1 = self.origin
    end

    self.state = STATE_BOTTOM

    if self.health > 0 then
        self.takedamage = DAMAGE_YES
        self.th_die = door_killed
    end
    
    if self.items > 0 then
        self.wait = -1
    end
        
    self.touch = door_touch

    -- LinkDoors can't be done until all of the doors have been spawned, so
    -- the sizes can be detected properly.
    self.think = LinkDoors;
    self.nextthink = self.ltime + 0.1
end

--[[
=============================================================================

SECRET DOORS

=============================================================================
--]]

local SECRET_OPEN_ONCE = 1;  -- stays open
local SECRET_1ST_LEFT  = 2;  -- 1st move is left of arrow
local SECRET_1ST_DOWN  = 4;  -- 1st move is down from arrow
local SECRET_NO_SHOOT  = 8;  -- only opened by trigger
local SECRET_YES_SHOOT = 16; -- shootable even if targeted

function fd_secret_use()
    local temp
    
    self.health = 10000

    -- exit if still moving around...
    if self.origin ~= self.oldorigin then
        return
    end
    
    self.message = string_null -- no more message

    SUB_UseTargets() -- fire all targets / killtargets
    
    if (self.spawnflags & SECRET_NO_SHOOT) == 0 then
        self.th_pain = SUB_Null
        self.takedamage = DAMAGE_NO
    end
    self.velocity = vec3(0,0,0)

    -- Make a sound, wait a little...
    sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM)
    self.nextthink = self.ltime + 0.1

    temp = 1 - (self.spawnflags & SECRET_1ST_LEFT) -- 1 or -1
    makevectors(self.mangle)
    
    if not self.t_width or self.t_width == 0 then
        if (self.spawnflags & SECRET_1ST_DOWN) > 0 then
            self.t_width = fabs(v_up * self.size)
        else
            self.t_width = fabs(v_right * self.size)
        end
    end
        
    if not self.t_length or self.t_length == 0 then
        self.t_length = fabs(v_forward * self.size)
    end

    if (self.spawnflags & SECRET_1ST_DOWN) > 0 then
        self.dest1 = self.origin - v_up * self.t_width
    else
        self.dest1 = self.origin + v_right * (self.t_width * temp)
    end
        
    self.dest2 = self.dest1 + v_forward * self.t_length
    SUB_CalcMove(self.dest1, self.speed, fd_secret_move1)
    sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
end

-- Wait after first movement...
function fd_secret_move1()
    self.nextthink = self.ltime + 1.0
    self.think = fd_secret_move2
    sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
end

-- Start moving sideways w/sound...
function fd_secret_move2()
    sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    SUB_CalcMove(self.dest2, self.speed, fd_secret_move3)
end

-- Wait here until time to go back...
function fd_secret_move3()
    sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
    if (self.spawnflags & SECRET_OPEN_ONCE) == 0 then
        self.nextthink = self.ltime + self.wait
        self.think = fd_secret_move4
    end
end

-- Move backward...
function fd_secret_move4()
    sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    SUB_CalcMove(self.dest1, self.speed, fd_secret_move5)
end

-- Wait 1 second...
function fd_secret_move5()
    self.nextthink = self.ltime + 1.0
    self.think = fd_secret_move6
    sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
end

function fd_secret_move6()
    sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    SUB_CalcMove(self.oldorigin, self.speed, fd_secret_done)
end

function fd_secret_done()
    if not self.targetname or #self.targetname == 0 or (self.spawnflags & SECRET_YES_SHOOT) > 0 then
        self.health = 10000
        self.takedamage = DAMAGE_YES
        self.th_pain = fd_secret_use
        self.th_die = fd_secret_use
    end
    sound(self, CHAN_NO_PHS_ADD+CHAN_VOICE, self.noise3, 1, ATTN_NORM)
end

function secret_blocked()
    if time < self.attack_finished then
        return
    end
    self.attack_finished = time + 0.5
    other.deathtype = "squish"
    T_Damage (other, self, self, self.dmg)
end

--[[
================
secret_touch

Prints messages
================
--]]
function secret_touch()
    if other.classname ~= "player" then
        return
    end
    if self.attack_finished > time then
        return
    end

    self.attack_finished = time + 2
    
    if self.message and #self.message > 0 then
        centerprint (other, self.message)
        sound (other, CHAN_BODY, "misc/talk.wav", 1, ATTN_NORM)
    end
end

--[[
QUAKED func_door_secret (0 .5 .8) ? open_once 1st_left 1st_down no_shoot always_shoot
Basic secret door. Slides back, then to the side. Angle determines direction.
wait  = # of seconds before coming back
1st_left = 1st move is left of arrow
1st_down = 1st move is down from arrow
always_shoot = even if targeted, keep shootable
t_width = override WIDTH to move back (or height if going down)
t_length = override LENGTH to move sideways
"dmg"           damage to inflict when blocked (2 default)

If a secret door has a targetname, it will only be opened by it's botton or trigger, not by damage.
"sounds"
1) medieval
2) metal
3) base
--]]
function func_door_secret()
    if not self.sounds or self.sounds == 0 then
        self.sounds = 3
    end
    if self.sounds == 1 then
        precache_sound ("doors/latch2.wav")
        precache_sound ("doors/winch2.wav")
        precache_sound ("doors/drclos4.wav")
        self.noise1 = "doors/latch2.wav"
        self.noise2 = "doors/winch2.wav"
        self.noise3 = "doors/drclos4.wav"
    end
    if self.sounds == 2 then
        precache_sound ("doors/airdoor1.wav")
        precache_sound ("doors/airdoor2.wav")
        self.noise2 = "doors/airdoor1.wav"
        self.noise1 = "doors/airdoor2.wav"
        self.noise3 = "doors/airdoor2.wav"
    end
    if self.sounds == 3 then
        precache_sound ("doors/basesec1.wav")
        precache_sound ("doors/basesec2.wav")
        self.noise2 = "doors/basesec1.wav"
        self.noise1 = "doors/basesec2.wav"
        self.noise3 = "doors/basesec2.wav"
    end

    if not self.dmg or self.dmg == 0 then
        self.dmg = 2
    end
        
    -- Magic formula...
    self.mangle = self.angles
    self.angles = vec3(0,0,0)
    self.solid = SOLID_BSP
    self.movetype = MOVETYPE_PUSH
    self.classname = "door"
    setmodel (self, self.model)
    setorigin (self, self.origin)  
    
    self.touch = secret_touch
    self.blocked = secret_blocked
    self.speed = 50
    self.use = fd_secret_use
    if not self.targetname or #self.targetname == 0 or (self.spawnflags & SECRET_YES_SHOOT) > 0 then
        self.health = 10000
        self.takedamage = DAMAGE_YES
        self.th_pain = fd_secret_use
    end
    self.oldorigin = self.origin
    if not self.wait or self.wait == 0 then
        self.wait = 5 -- 5 seconds before closing
    end
end
