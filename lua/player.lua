--[[
    player.qc

    player functions/definitions

    Copyright (C) 1996-1997    Id Software, Inc.

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
        Boston, MA    02111-1307, USA
]]--

--[[
==============================================================================

PLAYER

==============================================================================
]]

--
-- running
--
axrun1,axrun2,axrun3,axrun4,axrun5,axrun6 = 0,1,2,3,4,5

rockrun1,rockrun2,rockrun3,rockrun4,rockrun5,rockrun6 = 0,1,2,3,4,5

--
-- standing
--
stand1,stand2,stand3,stand4,stand5 = 0,1,2,3,4

axstnd1,axstnd2,axstnd3,axstnd4,axstnd5,axstnd6 = 0,1,2,3,4,5
axstnd7,axstnd8,axstnd9,axstnd10,axstnd11,axstnd12 = 0,1,2,3,4,5

--
-- pain
--
axpain1,axpain2,axpain3,axpain4,axpain5,axpain6 = 0,1,2,3,4,5

pain1,pain2,pain3,pain4,pain5,pain6 = 0,1,2,3,4,5


--
-- death
--

axdeth1,axdeth2,axdeth3,axdeth4,axdeth5,axdeth6 = 0,1,2,3,4,5
axdeth7,axdeth8,axdeth9 = 0,1,2

deatha1,deatha2,deatha3,deatha4,deatha5,deatha6,deatha7,deatha8 = 0,1,2,3,4,5,6,7
deatha9,deatha10,deatha11 = 0,1,2

deathb1,deathb2,deathb3,deathb4,deathb5,deathb6,deathb7,deathb8 = 0,1,2,3,4,5,6,7
deathb9 = 0

deathc1,deathc2,deathc3,deathc4,deathc5,deathc6,deathc7,deathc8 = 0,1,2,3,4,5,6,7
deathc9,deathc10,deathc11,deathc12,deathc13,deathc14,deathc15 = 0,1,2,3,4,5,6,7

deathd1,deathd2,deathd3,deathd4,deathd5,deathd6,deathd7 = 0,1,2,3,4,5,6
deathd8,deathd9 = 0,1

deathe1,deathe2,deathe3,deathe4,deathe5,deathe6,deathe7 = 0,1,2,3,4,5,6
deathe8,deathe9 = 0,1

--
-- attacks
--
nailatt1,nailatt2 = 0,1

light1,light2 = 0,1

rockatt1,rockatt2,rockatt3,rockatt4,rockatt5,rockatt6 = 0,1,2,3,4,5

shotatt1,shotatt2,shotatt3,shotatt4,shotatt5,shotatt6 = 0,1,2,3,4,5

axatt1,axatt2,axatt3,axatt4,axatt5,axatt6 = 0,1,2,3,4,5

axattb1,axattb2,axattb3,axattb4,axattb5,axattb6 = 0,1,2,3,4,5

axattc1,axattc2,axattc3,axattc4,axattc5,axattc6 = 0,1,2,3,4,5

axattd1,axattd2,axattd3,axattd4,axattd5,axattd6 = 0,1,2,3,4,5


--[[
==============================================================================
PLAYER
==============================================================================
]]

player_stand1 = ffunc(axstnd1, "player_stand1", function()
    self.weaponframe = 0

    if self.velocity.x > 0 or self.velocity.y > 0 then
        self.walkframe = 0
        player_run()
        return
    end

    if self.weapon == IT_AXE then
        if self.walkframe >= 12 then
            self.walkframe = 0
        end
        self.frame = axstnd1 + self.walkframe
    else
        if self.walkframe >= 5 then
            self.walkframe = 0
        end
        self.frame = stand1 + self.walkframe
    end
    self.walkframe = self.walkframe + 1
end)

player_run = ffunc(rockrun1, "player_run", function()
    self.weaponframe = 0

    if self.velocity.x == 0 and self.velocity.y == 0 then
        self.walkframe=0
        player_stand1()
        return
    end

    if self.weapon == IT_AXE then
        if self.walkframe == 6 then
            self.walkframe = 0
        end
        self.frame = axrun1 + self.walkframe
    else
        if self.walkframe == 6 then
            self.walkframe = 0
        end
        self.frame = self.frame + self.walkframe
    end

    self.walkframe = self.walkframe + 1
end)

function muzzleflash()
    WriteByte (MSG_MULTICAST, SVC_MUZZLEFLASH)
    WriteEntity (MSG_MULTICAST, self)
    multicast (self.origin, MULTICAST_PVS)
end

player_shot1 = ffunc(shotatt1, "player_shot2", function() self.weaponframe = 1 muzzleflash() end)
player_shot2 = ffunc(shotatt2, "player_shot3", function() self.weaponframe = 2 end)
player_shot3 = ffunc(shotatt3, "player_shot4", function() self.weaponframe = 3 end)
player_shot4 = ffunc(shotatt4, "player_shot5", function() self.weaponframe = 4 end)
player_shot5 = ffunc(shotatt5, "player_shot6", function() self.weaponframe = 5 end)
player_shot6 = ffunc(shotatt6, "player_run",   function() self.weaponframe = 6 end)

player_axe1 = ffunc(axatt1, "player_axe2", function() self.weaponframe=1 end)
player_axe2 = ffunc(axatt2, "player_axe3", function() self.weaponframe=2 end)
player_axe3 = ffunc(axatt3, "player_axe4", function() self.weaponframe=3 W_FireAxe() end)
player_axe4 = ffunc(axatt4, "player_run",  function() self.weaponframe=4 end)

player_axeb4 = ffunc(axattb4, "player_run",   function() self.weaponframe = 8 end)
player_axeb3 = ffunc(axattb3, "player_axeb4", function() self.weaponframe = 7 W_FireAxe() end)
player_axeb2 = ffunc(axattb2, "player_axeb3", function() self.weaponframe = 6 end)
player_axeb1 = ffunc(axattb1, "player_axeb2", function() self.weaponframe = 5 end)

player_axec1 = ffunc(axattc1, "player_axec2", function() self.weaponframe = 1 end)
player_axec2 = ffunc(axattc2, "player_axec3", function() self.weaponframe = 2 end)
player_axec3 = ffunc(axattc3, "player_axec4", function() self.weaponframe = 3 W_FireAxe() end)
player_axec4 = ffunc(axattc4, "player_run",   function() self.weaponframe = 4 end)

player_axed1 = ffunc(axattd1, "player_axed2", function() self.weaponframe = 5 end)
player_axed2 = ffunc(axattd2, "player_axed3", function() self.weaponframe = 6 end)
player_axed3 = ffunc(axattd3, "player_axed4", function() self.weaponframe = 7 W_FireAxe() end)
player_axed4 = ffunc(axattd4, "player_run",   function() self.weaponframe = 8 end)


--============================================================================

player_nail1 = ffunc(nailatt1, "player_nail2", function()
    muzzleflash()

    if self.button0 == 0 or intermission_running > 0 or self.impulse > 0 then
        player_run ()
        return
    end

    self.weaponframe = self.weaponframe + 1

    if self.weaponframe == 9 then
        self.weaponframe = 1
    end

    SuperDamageSound()
    W_FireSpikes (4)
    self.attack_finished = time + 0.2
end)

player_nail2 = ffunc(nailatt2, "player_nail1", function()
    muzzleflash()

    if self.button0 == 0 or intermission_running > 0 or self.impulse > 0 then
        player_run ()
        return
    end

    self.weaponframe = self.weaponframe + 1

    if self.weaponframe == 9 then
        self.weaponframe = 1
    end

    SuperDamageSound()
    W_FireSpikes (-4)
    self.attack_finished = time + 0.2
end)

--============================================================================

player_light1 = ffunc(light1, "player_light2", function()
    muzzleflash()

    if self.button0 == 0 or intermission_running > 0 then
        player_run ()
        return
    end

    self.weaponframe = self.weaponframe + 1

    if self.weaponframe == 5 then
        self.weaponframe = 1
    end

    SuperDamageSound()
    W_FireLightning()
    self.attack_finished = time + 0.2
end)

player_light2  = ffunc(light2, "player_light1", function()
    muzzleflash()

    if self.button0 == 0 or intermission_running > 0 then
        player_run ()
        return
    end

    self.weaponframe = self.weaponframe + 1

    if self.weaponframe == 5 then
        self.weaponframe = 1
    end

    SuperDamageSound()
    W_FireLightning()
    self.attack_finished = time + 0.2
end)

--============================================================================

player_rocket1 = ffunc(rockatt1, "player_rocket2", function() self.weaponframe = 1 muzzleflash() end)
player_rocket2 = ffunc(rockatt2, "player_rocket3", function() self.weaponframe = 2 end)
player_rocket3 = ffunc(rockatt3, "player_rocket4", function() self.weaponframe = 3 end)
player_rocket4 = ffunc(rockatt4, "player_rocket5", function() self.weaponframe = 4 end)
player_rocket5 = ffunc(rockatt5, "player_rocket6", function() self.weaponframe = 5 end)
player_rocket6 = ffunc(rockatt6, "player_run", function() self.weaponframe = 6 end)

function PainSound()
    local rs

    if self.health < 0 then
        return
    end

    if damage_attacker.classname == "teledeath" then
        sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE)
        return
    end

    -- water pain sounds
    if self.watertype == CONTENT_WATER and self.waterlevel == 3 then
        DeathBubbles(1)
        if random() > 0.5 then
            sound (self, CHAN_VOICE, "player/drown1.wav", 1, ATTN_NORM)
        else
            sound (self, CHAN_VOICE, "player/drown2.wav", 1, ATTN_NORM)
        end
        return
    end

    -- slime pain sounds
    if self.watertype == CONTENT_SLIME then
        -- FIX ME: put in some steam here
        if random() > 0.5 then
            sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM)
        else
            sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM)
        end
        return
    end

    if self.watertype == CONTENT_LAVA then
        if random() > 0.5 then
            sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM)
        else
            sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM)
        end
        return
    end

    if self.pain_finished > time then
        self.axhitme = 0
        return
    end
    self.pain_finished = time + 0.5

    -- don't make multiple pain sounds right after each other

    -- ax pain sound
    if self.axhitme == 1 then
        self.axhitme = 0
        sound (self, CHAN_VOICE, "player/axhit1.wav", 1, ATTN_NORM)
        return
    end

    rs = rint((random() * 5) + 1)

    self.noise = ""
    if rs == 1 then
        self.noise = "player/pain1.wav"
    elseif rs == 2 then
        self.noise = "player/pain2.wav"
    elseif rs == 3 then
        self.noise = "player/pain3.wav"
    elseif rs == 4 then
        self.noise = "player/pain4.wav"
    elseif rs == 5 then
        self.noise = "player/pain5.wav"
    else
        self.noise = "player/pain6.wav"
    end

    sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM)
    return
end

player_pain1 = ffunc(pain1, "player_pain2", function() PainSound() self.weaponframe=0 end)
player_pain2 = ffunc(pain2, "player_pain3", function() end)
player_pain3 = ffunc(pain3, "player_pain4", function() end)
player_pain4 = ffunc(pain4, "player_pain5", function() end)
player_pain5 = ffunc(pain5, "player_pain6", function() end)
player_pain6 = ffunc(pain6, "player_run", function() end)

player_axpain1 = ffunc(axpain1, "player_axpain2", function() PainSound() self.weaponframe=0 end)
player_axpain2 = ffunc(axpain2, "player_axpain3", function() end)
player_axpain3 = ffunc(axpain3, "player_axpain4", function() end)
player_axpain4 = ffunc(axpain4, "player_axpain5", function() end)
player_axpain5 = ffunc(axpain5, "player_axpain6", function() end)
player_axpain6 = ffunc(axpain6, "player_run", function() end)

function player_pain()
    if self.weaponframe > 0 then
        return
    end

    if self.invisible_finished > time then
        return -- eyes don't have pain frames
    end

    if self.weapon == IT_AXE then
        player_axpain1()
    else
        player_pain1()
    end
end

function DeathBubblesSpawn()
    local bubble

    if self.owner.waterlevel ~= 3 then
        return
    end
    bubble = spawn()
    setmodel(bubble, "progs/s_bubble.spr")
    setorigin(bubble, self.owner.origin + vec3(0,0,24))
    bubble.movetype = MOVETYPE_NOCLIP
    bubble.solid = SOLID_NOT
    bubble.velocity = vec3(0,0,15)
    bubble.nextthink = time + 0.5
    bubble.think = bubble_bob
    bubble.classname = "bubble"
    bubble.frame = 0
    bubble.cnt = 0
    setsize(bubble, vec3(-8,-8,-8), vec3(8,8,8))
    self.nextthink = time + 0.1
    self.think = DeathBubblesSpawn
    self.air_finished = self.air_finished + 1
    if self.air_finished >= self.bubble_count then
        remove(self)
    end
end

function DeathBubbles(num_bubbles)
    local bubble_spawner

    bubble_spawner = spawn()
    setorigin(bubble_spawner, self.origin)
    bubble_spawner.movetype = MOVETYPE_NONE
    bubble_spawner.solid = SOLID_NOT
    bubble_spawner.nextthink = time + 0.1
    bubble_spawner.think = DeathBubblesSpawn
    bubble_spawner.air_finished = 0
    bubble_spawner.owner = self
    bubble_spawner.bubble_count = num_bubbles
end

function DeathSound()
    local rs

    -- water death sounds
    if self.waterlevel == 3 then
        DeathBubbles(5)
        sound(self, CHAN_VOICE, "player/h2odeath.wav", 1, ATTN_NONE)
        return
    end

    rs = rint((random() * 4) + 1)
    if rs == 1 then
        self.noise = "player/death1.wav"
    elseif rs == 2 then
        self.noise = "player/death2.wav"
    elseif rs == 3 then
        self.noise = "player/death3.wav"
    elseif rs == 4 then
        self.noise = "player/death4.wav"
    elseif rs == 5 then
        self.noise = "player/death5.wav"
    end

    sound(self, CHAN_VOICE, self.noise, 1, ATTN_NONE)
end


function PlayerDead()
    self.nextthink = -1
    -- allow respawn after a certain time
    self.deadflag = DEAD_DEAD
end

function VelocityForDamage(dm)
    local v

    if vlen(damage_inflictor.velocity) > 0 then
        v = 0.5 * damage_inflictor.velocity
        v = v + (25 * normalize(self.origin-damage_inflictor.origin))
        v_z = 100 + 240 * random()
        v_x = v_x + (200 * crandom())
        v_y = v_y + (200 * crandom())
        --dprint ("Velocity gib\n")
    else
        v_x = 100 * crandom()
        v_y = 100 * crandom()
        v_z = 200 + 100 * random()
    end

    --v_x = 100 * crandom()
    --v_y = 100 * crandom()
    --v_z = 200 + 100 * random()

    if dm > -50 then
        --dprint ("level 1\n")
        v = v * 0.7
    elseif dm > -200 then
        --dprint ("level 3\n")
        v = v * 2
    else
        v = v * 10
    end

    return v
end

function ThrowGib(gibname, dm)
    local new

    new = spawn()
    new.origin = self.origin
    setmodel(new, gibname)
    setsize(new, vec3(0,0,0), vec3(0,0,0))
    new.velocity = VelocityForDamage (dm)
    new.movetype = MOVETYPE_BOUNCE
    new.solid = SOLID_NOT
    new.avelocity_x = random()*600
    new.avelocity_y = random()*600
    new.avelocity_z = random()*600
    new.think = SUB_Remove
    new.ltime = time
    new.nextthink = time + 10 + random()*10
    new.frame = 0
    new.flags = 0
end

function ThrowHead(gibname, dm)
    setmodel(self, gibname)
    self.frame = 0
    self.nextthink = -1
    self.movetype = MOVETYPE_BOUNCE
    self.takedamage = DAMAGE_NO
    self.solid = SOLID_NOT
    self.view_ofs = vec3(0,0,8)
    setsize(self, vec3(-16,-16,0), vec3(16,16,56))
    self.velocity = VelocityForDamage (dm)
    self.origin_z = self.origin_z - 24
    self.flags = self.flags - (self.flags & FL_ONGROUND)
    self.avelocity = crandom() * '0 600 0'
end

function GibPlayer()
    ThrowHead("progs/h_player.mdl", self.health)
    ThrowGib("progs/gib1.mdl", self.health)
    ThrowGib("progs/gib2.mdl", self.health)
    ThrowGib("progs/gib3.mdl", self.health)

    self.deadflag = DEAD_DEAD

    if damage_attacker.classname == "teledeath" then
        sound(self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE)
        return
    elseif damage_attacker.classname == "teledeath2" then
        sound(self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE)
        return
    end

    if random() < 0.5 then
        sound(self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE)
    else
        sound(self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE)
    end
end

function PlayerDie()
    local i
    local s

    self.items = self.items - (self.items & IT_INVISIBILITY)

    if tonumber(infokey(world,"dq")) ~= 0 and self.super_damage_finished > 0 then
        DropQuad(self.super_damage_finished - time)
        bprint(PRINT_LOW, self.netname)
        if deathmatch == 4 then
            bprint(PRINT_LOW, " lost an OctaPower with ")
        else
            bprint(PRINT_LOW, " lost a quad with ")
        end
        s = tostring(rint(self.super_damage_finished - time))
        bprint(PRINT_LOW, s)
        bprint(PRINT_LOW, " seconds remaining\n")
    end

    if tonumber(infokey(world,"dr")) ~= 0 and self.invisible_finished > 0 then
        bprint(PRINT_LOW, self.netname)
        bprint(PRINT_LOW, " lost a ring with ")
        s = tostring(rint(self.invisible_finished - time))
        bprint(PRINT_LOW, s)
        bprint(PRINT_LOW, " seconds remaining\n")
        DropRing(self.invisible_finished - time)
    end

    self.invisible_finished = 0 -- don't die as eyes
    self.invincible_finished = 0
    self.super_damage_finished = 0
    self.radsuit_finished = 0
    self.modelindex = modelindex_player -- don't use eyes

    DropBackpack()

    self.weaponmodel = ""
    self.view_ofs = vec3(0,0,-8)
    self.deadflag = DEAD_DYING
    self.solid = SOLID_NOT
    self.flags = self.flags - (self.flags & FL_ONGROUND)
    self.movetype = MOVETYPE_TOSS
    if self.velocity.z < 10 then
        self.velocity.z = self.velocity.z + random()*300
    end

    if self.health < -40 then
        GibPlayer()
        return
    end

    DeathSound()

    self.angles_x = 0
    self.angles_z = 0

    if self.weapon == IT_AXE then
        player_die_ax1 ()
        return
    end

    i = cvar("temp1")
    if not i or i ~= 0 then
        i = 1 + floor(random()*6)
    end

    if i == 1 then
        player_diea1()
    elseif i == 2 then
        player_dieb1()
    elseif i == 3 then
        player_diec1()
    elseif i == 4 then
        player_died1()
    else
        player_diee1()
    end
end

function set_suicide_frame()
    -- used by kill command and disconnect commands
    if self.model ~= "progs/player.mdl" then
        return; -- already gibbed
    end
    self.frame = deatha11
    self.solid = SOLID_NOT
    self.movetype = MOVETYPE_TOSS
    self.deadflag = DEAD_DEAD
    self.nextthink = -1
end

player_diea1 = ffunc(deatha1, "player_diea2", function() end)
player_diea2 = ffunc(deatha2, "player_diea3", function() end)
player_diea3 = ffunc(deatha3, "player_diea4", function() end)
player_diea4 = ffunc(deatha4, "player_diea5", function() end)
player_diea5 = ffunc(deatha5, "player_diea6", function() end)
player_diea6 = ffunc(deatha6, "player_diea7", function() end)
player_diea7 = ffunc(deatha7, "player_diea8", function() end)
player_diea8 = ffunc(deatha8, "player_diea9", function() end)
player_diea9 = ffunc(deatha9, "player_diea10", function() end)
player_diea10 = ffunc(deatha10, "player_diea11", function() end)
player_diea11 = ffunc(deatha11, "player_diea11", function() PlayerDead() end)

player_dieb1 = ffunc(deathb1, "player_dieb2", function() end)
player_dieb2 = ffunc(deathb2, "player_dieb3", function() end)
player_dieb3 = ffunc(deathb3, "player_dieb4", function() end)
player_dieb4 = ffunc(deathb4, "player_dieb5", function() end)
player_dieb5 = ffunc(deathb5, "player_dieb6", function() end)
player_dieb6 = ffunc(deathb6, "player_dieb7", function() end)
player_dieb7 = ffunc(deathb7, "player_dieb8", function() end)
player_dieb8 = ffunc(deathb8, "player_dieb9", function() end)
player_dieb9 = ffunc(deathb9, "player_dieb9", function() PlayerDead() end)

player_diec1 = ffunc(deathc1, "player_diec2", function() end)
player_diec2 = ffunc(deathc2, "player_diec3", function() end)
player_diec3 = ffunc(deathc3, "player_diec4", function() end)
player_diec4 = ffunc(deathc4, "player_diec5", function() end)
player_diec5 = ffunc(deathc5, "player_diec6", function() end)
player_diec6 = ffunc(deathc6, "player_diec7", function() end)
player_diec7 = ffunc(deathc7, "player_diec8", function() end)
player_diec8 = ffunc(deathc8, "player_diec9", function() end)
player_diec9 = ffunc(deathc9, "player_diec10", function() end)
player_diec10 = ffunc(deathc10, "player_diec11", function() end)
player_diec11 = ffunc(deathc11, "player_diec12", function() end)
player_diec12 = ffunc(deathc12, "player_diec13", function() end)
player_diec13 = ffunc(deathc13, "player_diec14", function() end)
player_diec14 = ffunc(deathc14, "player_diec15", function() end)
player_diec15 = ffunc(deathc15, "player_diec15", function() PlayerDead() end)

player_died1 = ffunc(deathd1, "player_died2", function() end)
player_died2 = ffunc(deathd2, "player_died3", function() end)
player_died3 = ffunc(deathd3, "player_died4", function() end)
player_died4 = ffunc(deathd4, "player_died5", function() end)
player_died5 = ffunc(deathd5, "player_died6", function() end)
player_died6 = ffunc(deathd6, "player_died7", function() end)
player_died7 = ffunc(deathd7, "player_died8", function() end)
player_died8 = ffunc(deathd8, "player_died9", function() end)
player_died9 = ffunc(deathd9, "player_died9", function() PlayerDead() end)

player_diee1 = ffunc(deathe1, "player_diee2", function() end)
player_diee2 = ffunc(deathe2, "player_diee3", function() end)
player_diee3 = ffunc(deathe3, "player_diee4", function() end)
player_diee4 = ffunc(deathe4, "player_diee5", function() end)
player_diee5 = ffunc(deathe5, "player_diee6", function() end)
player_diee6 = ffunc(deathe6, "player_diee7", function() end)
player_diee7 = ffunc(deathe7, "player_diee8", function() end)
player_diee8 = ffunc(deathe8, "player_diee9", function() end)
player_diee9 = ffunc(deathe9, "player_diee9", function() PlayerDead() end)

player_die_ax1 = ffunc(axdeth1, "player_die_ax2", function() end)
player_die_ax2 = ffunc(axdeth2, "player_die_ax3", function() end)
player_die_ax3 = ffunc(axdeth3, "player_die_ax4", function() end)
player_die_ax4 = ffunc(axdeth4, "player_die_ax5", function() end)
player_die_ax5 = ffunc(axdeth5, "player_die_ax6", function() end)
player_die_ax6 = ffunc(axdeth6, "player_die_ax7", function() end)
player_die_ax7 = ffunc(axdeth7, "player_die_ax8", function() end)
player_die_ax8 = ffunc(axdeth8, "player_die_ax9", function() end)
player_die_ax9 = ffunc(axdeth9, "player_die_ax9", function() PlayerDead() end)
