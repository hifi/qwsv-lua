--[[
    misc.qc

    pretty much everything else

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

--[[
QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
--]]
function info_null()
    remove(self)
end

--[[
QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
--]]
function info_notnull()
end

-- ============================================================================

local START_OFF = 1

function light_use()
    if (self.spawnflags & START_OFF) > 0 then
        lightstyle(self.style, "m")
        self.spawnflags = self.spawnflags - START_OFF
    else
        lightstyle(self.style, "a")
        self.spawnflags = self.spawnflags + START_OFF
    end
end

--[[
QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
--]]
function light()
    if not self.targetname then
        -- inert light
        remove(self)
        return
    end

    if self.style and self.style >= 32 then
        self.use = light_use
        if (self.spawnflags & START_OFF) > 0 then
            lightstyle(self.style, "a")
        else
            lightstyle(self.style, "m")
        end
    end
end

--[[
QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
Makes steady fluorescent humming sound
--]]
function light_fluoro()
    if self.style and self.style >= 32 then
        self.use = light_use
        if (self.spawnflags & START_OFF) > 0 then
            lightstyle(self.style, "a")
        else
            lightstyle(self.style, "m")
        end
    end

    precache_sound ("ambience/fl_hum1.wav")
    ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC)
end

--[[
QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
--]]
function light_fluorospark()
    if not self.style then
        self.style = 10
    end

    precache_sound ("ambience/buzz1.wav")
    ambientsound (self.origin, "ambience/buzz1.wav", 0.5, ATTN_STATIC)
end

--[[
QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
--]]
function light_globe()
    precache_model ("progs/s_light.spr")
    setmodel (self, "progs/s_light.spr")
    makestatic (self)
end

function FireAmbient()
    precache_sound ("ambience/fire1.wav")
    -- attenuate fast
    ambientsound (self.origin, "ambience/fire1.wav", 0.5, ATTN_STATIC)
end

--[[
QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0
--]]
function light_torch_small_walltorch()
    precache_model ("progs/flame.mdl")
    setmodel (self, "progs/flame.mdl")
    FireAmbient ()
    makestatic (self)
end

--[[
QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball
--]]
function light_flame_large_yellow()
    precache_model ("progs/flame2.mdl")
    setmodel (self, "progs/flame2.mdl")
    self.frame = 1
    FireAmbient ()
    makestatic (self)
end

--[[
QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball
--]]
function light_flame_small_yellow()
    precache_model ("progs/flame2.mdl")
    setmodel (self, "progs/flame2.mdl")
    FireAmbient ()
    makestatic (self)
end

--[[
QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball
--]]
function light_flame_small_white()
    precache_model ("progs/flame2.mdl")
    setmodel (self, "progs/flame2.mdl")
    FireAmbient ()
    makestatic (self)
end

--============================================================================

--[[
QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls
--]]

function misc_fireball()
    precache_model ("progs/lavaball.mdl")
    self.classname = "fireball"
    self.nextthink = time + (random() * 5)
    self.think = fire_fly
    if not self.speed or self.speed == 0 then
        self.speed = 1000
    end
end

function fire_fly()
    local fireball

    fireball = spawn()
    fireball.solid = SOLID_TRIGGER
    fireball.movetype = MOVETYPE_TOSS
    fireball.velocity = vec3(0, 0, 1000)
    fireball.velocity.x = (random() * 100) - 50
    fireball.velocity.y = (random() * 100) - 50
    fireball.velocity.z = self.speed + (random() * 200)
    fireball.classname = "fireball"
    setmodel (fireball, "progs/lavaball.mdl")
    setsize (fireball, vec3(0, 0, 0), vec3(0, 0, 0))
    setorigin (fireball, self.origin)
    fireball.nextthink = time + 5
    fireball.think = SUB_Remove
    fireball.touch = fire_touch

    self.nextthink = time + (random() * 5) + 3
    self.think = fire_fly
end

function fire_touch()
    T_Damage (other, self, self, 20)
    remove(self)
end

--============================================================================

function barrel_explode()
    self.takedamage = DAMAGE_NO
    self.classname = "explo_box"
    -- did say self.owner
    T_RadiusDamage (self, self, 160, world, "")
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
    WriteByte (MSG_MULTICAST, TE_EXPLOSION)
    WriteCoord (MSG_MULTICAST, self.origin.x)
    WriteCoord (MSG_MULTICAST, self.origin.y)
    WriteCoord (MSG_MULTICAST, self.origin.z+32)
    multicast (self.origin, MULTICAST_PHS)
    remove (self)
end

--[[
QUAKED misc_explobox (0 .5 .8) (0 0 0) (32 32 64)
TESTING THING
--]]
function misc_explobox()
    local oldz

    self.solid = SOLID_BBOX
    self.movetype = MOVETYPE_NONE
    precache_model ("maps/b_explob.bsp")
    setmodel (self, "maps/b_explob.bsp")
    setsize (self, vec3(0,0,0), vec3(32,32,64))
    precache_sound ("weapons/r_exp3.wav")
    self.health = 20
    self.th_die = barrel_explode
    self.takedamage = DAMAGE_AIM

    self.origin.z = self.origin.z + 2
    oldz = self.origin.z
    droptofloor()
    if oldz - self.origin.z > 250 then
        dprint ("item fell out of level at ")
        dprint (vtos(self.origin))
        dprint ("\n")
        remove(self)
    end
end


--[[
QUAKED misc_explobox2 (0 .5 .8) (0 0 0) (32 32 64)
Smaller exploding box, REGISTERED ONLY
--]]
function misc_explobox2()
    local oldz

    self.solid = SOLID_BBOX
    self.movetype = MOVETYPE_NONE
    precache_model2 ("maps/b_exbox2.bsp")
    setmodel (self, "maps/b_exbox2.bsp")
    setsize (self, vec3(0,0,0), vec3(32,32,32))
    precache_sound ("weapons/r_exp3.wav")
    self.health = 20
    self.th_die = barrel_explode
    self.takedamage = DAMAGE_AIM

    self.origin.z = self.origin.z + 2
    oldz = self.origin.z
    droptofloor()
    if oldz - self.origin.z > 250 then
        dprint ("item fell out of level at ")
        dprint (vtos(self.origin))
        dprint ("\n")
        remove(self)
    end
end

--============================================================================

local SPAWNFLAG_SUPERSPIKE = 1
local SPAWNFLAG_LASER      = 2

function Laser_Touch()
    local org

    if other == self.owner then
        return -- don't explode on owner
    end

    if pointcontents(self.origin) == CONTENT_SKY then
        remove(self)
        return
    end

    sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC)
    org = self.origin - 8*normalize(self.velocity)

    if other.health then
        SpawnBlood (org, 15)
        other.deathtype = "laser"
        T_Damage (other, self, self.owner, 15)
    else
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
        WriteByte (MSG_MULTICAST, TE_GUNSHOT)
        WriteByte (MSG_MULTICAST, 5)
        WriteCoord (MSG_MULTICAST, org.x)
        WriteCoord (MSG_MULTICAST, org.y)
        WriteCoord (MSG_MULTICAST, org.z)
        multicast (org, MULTICAST_PVS)
    end

    remove(self)
end

function LaunchLaser(org, vec)
    if self.classname == "monster_enforcer" then
        sound (self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM)
    end

    vec = normalize(vec)

    newmis = spawn()
    newmis.owner = self
    newmis.movetype = MOVETYPE_FLY
    newmis.solid = SOLID_BBOX
    newmis.effects = EF_DIMLIGHT

    setmodel (newmis, "progs/laser.mdl")
    setsize (newmis, vec3(0,0,0), vec3(0,0,0))

    setorigin (newmis, org)

    newmis.velocity = vec * 600
    newmis.angles = vectoangles(newmis.velocity)

    newmis.nextthink = time + 5
    newmis.think = SUB_Remove
    newmis.touch = Laser_Touch
end

function spikeshooter_use()
    if (self.spawnflags & SPAWNFLAG_LASER) > 0 then
        sound (self, CHAN_VOICE, "enforcer/enfire.wav", 1, ATTN_NORM)
        LaunchLaser (self.origin, self.movedir)
    else
        sound (self, CHAN_VOICE, "weapons/spike2.wav", 1, ATTN_NORM)
        launch_spike (self.origin, self.movedir)
        newmis.velocity = self.movedir * 500
        if (self.spawnflags & SPAWNFLAG_SUPERSPIKE) > 0 then
            newmis.touch = superspike_touch
        end
    end
end

function shooter_think()
    spikeshooter_use()
    self.nextthink = time + self.wait
    newmis.velocity = self.movedir * 500
end

--[[
QUAKED trap_spikeshooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
When triggered, fires a spike in the direction set in QuakeEd.
Laser is only for REGISTERED.
--]]

function trap_spikeshooter()
    SetMovedir()
    self.use = spikeshooter_use
    if (self.spawnflags & SPAWNFLAG_LASER) > 0 then
        precache_model2("progs/laser.mdl")
        precache_sound2("enforcer/enfire.wav")
        precache_sound2("enforcer/enfstop.wav")
    else
        precache_sound("weapons/spike2.wav")
    end
end

--[[
QUAKED trap_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
Continuously fires spikes.
"wait" time between spike (1.0 default)
"nextthink" delay before firing first spike, so multiple shooters can be stagered.
--]]
function trap_shooter()
    trap_spikeshooter()

    if self.wait == 0 then
        self.wait = 1
    end

    self.nextthink = self.nextthink + self.wait + self.ltime
    self.think = shooter_think
end

--[[
===============================================================================


===============================================================================
--]]

--[[
QUAKED air_bubbles (0 .5 .8) (-8 -8 -8) (8 8 8)

testing air bubbles
--]]
function air_bubbles()
    remove (self)
end

function make_bubbles()
    local bubble

    bubble = spawn()
    setmodel (bubble, "progs/s_bubble.spr")
    setorigin (bubble, self.origin)
    bubble.movetype = MOVETYPE_NOCLIP
    bubble.solid = SOLID_NOT
    bubble.velocity = vec3(0,0,15)
    bubble.nextthink = time + 0.5
    bubble.think = bubble_bob
    bubble.touch = bubble_remove
    bubble.classname = "bubble"
    bubble.frame = 0
    bubble.cnt = 0
    setsize (bubble, vec3(-8,-8,-8), vec3(8,8,8))
    self.nextthink = time + random() + 0.5
    self.think = make_bubbles
end

function bubble_split()
    local bubble
    bubble = spawn()
    setmodel (bubble, "progs/s_bubble.spr")
    setorigin (bubble, self.origin)
    bubble.movetype = MOVETYPE_NOCLIP
    bubble.solid = SOLID_NOT
    bubble.velocity = self.velocity
    bubble.nextthink = time + 0.5
    bubble.think = bubble_bob
    bubble.touch = bubble_remove
    bubble.classname = "bubble"
    bubble.frame = 1
    bubble.cnt = 10
    setsize (bubble, vec3(-8,-8,-8), vec3(8,8,8))
    self.frame = 1
    self.cnt = 10
    if self.waterlevel ~= 3 then
        remove (self)
    end
end

function bubble_remove()
    if other.classname == self.classname then
        -- dprint ("bump")
        return
    end
    remove(self)
end

function bubble_bob()
    local rnd1, rnd2, rnd3
    local vtmp1, modi

    self.cnt = self.cnt + 1
    if self.cnt == 4 then
        bubble_split()
    end
    if self.cnt == 20 then
        remove(self)
    end

    rnd1 = self.velocity.x + (-10 + (random() * 20))
    rnd2 = self.velocity.y + (-10 + (random() * 20))
    rnd3 = self.velocity.z + 10 + random() * 10

    if rnd1 > 10 then
        rnd1 = 5
    end
    if rnd1 < -10 then
        rnd1 = -5
    end

    if rnd2 > 10 then
        rnd2 = 5
    end
    if rnd2 < -10 then
        rnd2 = -5
    end

    if rnd3 < 10 then
        rnd3 = 15
    end
    if rnd3 > 30 then
        rnd3 = 25
    end

    self.velocity.x = rnd1
    self.velocity.y = rnd2
    self.velocity.z = rnd3

    self.nextthink = time + 0.5
    self.think = bubble_bob
end

--[[
~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>
~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~
--]]

--[[
QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)

Just for the debugging level.  Don't use
--]]
function viewthing()
    self.movetype = MOVETYPE_NONE
    self.solid = SOLID_NOT
    precache_model ("progs/player.mdl")
    setmodel (self, "progs/player.mdl")
end

--[[
==============================================================================

SIMPLE BMODELS

==============================================================================
--]]

function func_wall_use()
    -- change to alternate textures
    self.frame = 1 - self.frame
end

--[[
QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
--]]
function func_wall()
    self.angles = vec3(0,0,0)
    self.movetype = MOVETYPE_PUSH -- so it doesn't get pushed by anything
    self.solid = SOLID_BSP
    self.use = func_wall_use
    setmodel (self, self.model)
end

--[[
QUAKED func_illusionary (0 .5 .8) ?
A simple entity that looks solid but lets you walk through it.
--]]
function func_illusionary()
    self.angles = vec3(0,0,0)
    self.movetype = MOVETYPE_NONE
    self.solid = SOLID_NOT
    setmodel (self, self.model)
    makestatic (self)
end

--[[
QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
This bmodel will appear if the episode has allready been completed, so players can't reenter it.
--]]
function func_episodegate()
    if (serverflags & self.spawnflags) == 0 then
        return -- can still enter episode
    end

    self.angles = vec3(0,0,0)
    self.movetype = MOVETYPE_PUSH -- so it doesn't get pushed by anything
    self.solid = SOLID_BSP
    self.use = func_wall_use
    setmodel (self, self.model)
end

--[[
QUAKED func_bossgate (0 .5 .8) ?
This bmodel appears unless players have all of the episode sigils.
--]]
function func_bossgate()
    if (serverflags & 15) == 15 then
        return -- all episodes completed
    end
    self.angles = vec3(0,0,0)
    self.movetype = MOVETYPE_PUSH -- so it doesn't get pushed by anything
    self.solid = SOLID_BSP
    self.use = func_wall_use
    setmodel (self, self.model)
end

--============================================================================

--[[
QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
--]]
function ambient_suck_wind()
    precache_sound ("ambience/suck1.wav")
    ambientsound (self.origin, "ambience/suck1.wav", 1, ATTN_STATIC)
end

--[[
QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
--]]
function ambient_drone()
    precache_sound ("ambience/drone6.wav")
    ambientsound (self.origin, "ambience/drone6.wav", 0.5, ATTN_STATIC)
end

--[[
QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
--]]
function ambient_flouro_buzz()
    precache_sound ("ambience/buzz1.wav")
    ambientsound (self.origin, "ambience/buzz1.wav", 1, ATTN_STATIC)
end

--[[
QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
--]]
function ambient_drip()
    precache_sound ("ambience/drip1.wav")
    ambientsound (self.origin, "ambience/drip1.wav", 0.5, ATTN_STATIC)
end

--[[
QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
--]]
function ambient_comp_hum()
    precache_sound ("ambience/comp1.wav")
    ambientsound (self.origin, "ambience/comp1.wav", 1, ATTN_STATIC)
end

--[[
QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
--]]
function ambient_thunder()
    precache_sound ("ambience/thunder1.wav")
    ambientsound (self.origin, "ambience/thunder1.wav", 0.5, ATTN_STATIC)
end

--[[
QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
--]]
function ambient_light_buzz()
    precache_sound ("ambience/fl_hum1.wav")
    ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC)
end

--[[
QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
--]]
function ambient_swamp1()
    precache_sound ("ambience/swamp1.wav")
    ambientsound (self.origin, "ambience/swamp1.wav", 0.5, ATTN_STATIC)
end

--[[
QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
--]]
function ambient_swamp2()
    precache_sound ("ambience/swamp2.wav")
    ambientsound (self.origin, "ambience/swamp2.wav", 0.5, ATTN_STATIC)
end

--============================================================================

function noise_think()
    self.nextthink = time + 0.5
    sound (self, 1, "enforcer/enfire.wav", 1, ATTN_NORM)
    sound (self, 2, "enforcer/enfstop.wav", 1, ATTN_NORM)
    sound (self, 3, "enforcer/sight1.wav", 1, ATTN_NORM)
    sound (self, 4, "enforcer/sight2.wav", 1, ATTN_NORM)
    sound (self, 5, "enforcer/sight3.wav", 1, ATTN_NORM)
    sound (self, 6, "enforcer/sight4.wav", 1, ATTN_NORM)
    sound (self, 7, "enforcer/pain1.wav", 1, ATTN_NORM)
end

--[[
QUAKED misc_noisemaker (1 0.5 0) (-10 -10 -10) (10 10 10)

For optimzation testing, starts a lot of sounds.
--]]
function misc_noisemaker()
    precache_sound2 ("enforcer/enfire.wav")
    precache_sound2 ("enforcer/enfstop.wav")
    precache_sound2 ("enforcer/sight1.wav")
    precache_sound2 ("enforcer/sight2.wav")
    precache_sound2 ("enforcer/sight3.wav")
    precache_sound2 ("enforcer/sight4.wav")
    precache_sound2 ("enforcer/pain1.wav")
    precache_sound2 ("enforcer/pain2.wav")
    precache_sound2 ("enforcer/death1.wav")
    precache_sound2 ("enforcer/idle1.wav")

    self.nextthink = time + 0.1 + random()
    self.think = noise_think
end
