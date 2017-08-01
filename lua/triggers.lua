--[[
    triggers.qc

    trigger functions

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

local stemp, otemp, s, old

function trigger_reactivate()
    self.solid = SOLID_TRIGGER
end

--=============================================================================

local SPAWNFLAG_NOMESSAGE = 1
local SPAWNFLAG_NOTOUCH = 1

-- the wait time has passed, so set back up for another activation
function multi_wait()
    if self.max_health and self.max_health > 0 then
        self.health = self.max_health
        self.takedamage = DAMAGE_YES
        self.solid = SOLID_BBOX
    end
end

-- the trigger was just touched/killed/used
-- self.enemy should be set to the activator so it can be held through a delay
-- so wait for the delay time before firing
function multi_trigger()
    if self.nextthink > time then
        return -- allready been triggered
    end

    if self.classname == "trigger_secret" then
        if self.enemy.classname ~= "player" then
            return
        end
        found_secrets = found_secrets + 1
        WriteByte (MSG_ALL, SVC_FOUNDSECRET)
    end

    if self.noise and #self.noise > 0 then
        sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM)
    end

    -- don't trigger again until reset
    self.takedamage = DAMAGE_NO

    activator = self.enemy

    SUB_UseTargets()

    if self.wait and self.wait > 0 then
        self.think = multi_wait
        self.nextthink = time + self.wait
    else
        -- we can't just remove (self) here, because this is a touch function
        -- called wheil C code is looping through area links...
        self.touch = SUB_Null
        self.nextthink = time + 0.1
        self.think = SUB_Remove
    end
end

function multi_killed()
    self.enemy = damage_attacker
    multi_trigger()
end

function multi_use()
    self.enemy = activator
    multi_trigger()
end

function multi_touch()
    if other.classname ~= "player" then
        return
    end

    -- if the trigger has an angles field, check player's facing direction
    if self.movedir ~= vec3(0,0,0) then
        makevectors (other.angles)
        if v_forward * self.movedir < 0 then
            return -- not facing the right way
        end
    end

    self.enemy = other
    multi_trigger()
end

--[[
QUAKED trigger_multiple (.5 .5 .5) ? notouch
Variable sized repeatable trigger.  Must be targeted at one or more entities.  If "health" is set, the trigger must be killed to activate each time.
If "delay" is set, the trigger waits some time after activating before firing.
"wait" : Seconds between triggerings. (.2 default)
If notouch is set, the trigger is only fired by other entities, not by touching.
NOTOUCH has been obsoleted by trigger_relay!
sounds
1)    secret
2)    beep beep
3)    large switch
4)
set "message" to text string
--]]
function trigger_multiple()
    if self.sounds == 1 then
        precache_sound ("misc/secret.wav")
        self.noise = "misc/secret.wav"
    elseif self.sounds == 2 then
        precache_sound ("misc/talk.wav")
        self.noise = "misc/talk.wav"
    elseif self.sounds == 3 then
        precache_sound ("misc/trigger1.wav")
        self.noise = "misc/trigger1.wav"
    end

    if not self.wait or self.wait == 0 then
        self.wait = 0.2
    end
    self.use = multi_use

    InitTrigger()

    if self.health and self.health > 0 then
        if (self.spawnflags & SPAWNFLAG_NOTOUCH) > 0 then
            objerror ("health and notouch don't make sense\n")
        end
        self.max_health = self.health
        self.th_die = multi_killed
        self.takedamage = DAMAGE_YES
        self.solid = SOLID_BBOX
        setorigin (self, self.origin) -- make sure it links into the world
    else
        if (self.spawnflags & SPAWNFLAG_NOTOUCH) == 0 then
            self.touch = multi_touch
        end
    end
end

--[[
QUAKED trigger_once (.5 .5 .5) ? notouch
Variable sized trigger. Triggers once, then removes itself.  You must set the key "target" to the name of another object in the level that has a matching
"targetname".  If "health" is set, the trigger must be killed to activate.
If notouch is set, the trigger is only fired by other entities, not by touching.
if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
if "angle" is set, the trigger will only fire when someone is facing the direction of the angle.  Use "360" for an angle of 0.
sounds
1)    secret
2)    beep beep
3)    large switch
4)
set "message" to text string
--]]
function trigger_once()
    self.wait = -1
    trigger_multiple()
end

--=============================================================================

--[[
QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
--]]
function trigger_relay()
    self.use = SUB_UseTargets
end

--=============================================================================

--[[
QUAKED trigger_secret (.5 .5 .5) ?
secret counter trigger
sounds
1)    secret
2)    beep beep
3)
4)
set "message" to text string
--]]
function trigger_secret()
    total_secrets = total_secrets + 1
    self.wait = -1
    if not self.message then
        self.message = "You found a secret area!"
    end
    if self.sounds == 0 then
        self.sounds = 1
    end

    if self.sounds == 1 then
        precache_sound ("misc/secret.wav")
        self.noise = "misc/secret.wav"
    elseif self.sounds == 2 then
        precache_sound ("misc/talk.wav")
        self.noise = "misc/talk.wav"
    end

    trigger_multiple ()
end

--=============================================================================

function counter_use()
    local junk

    self.count = self.count - 1
    if self.count < 0 then
        return
    end

    if self.count ~= 0 then
        if activator.classname == "player"
        and (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0 then
            if self.count >= 4 then
                centerprint (activator, "There are more to go...")
            elseif self.count == 3 then
                centerprint (activator, "Only 3 more to go...")
            elseif self.count == 2 then
                centerprint (activator, "Only 2 more to go...")
            else
                centerprint (activator, "Only 1 more to go...")
            end
        end
        return
    end

    if activator.classname == "player"
    and (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0 then
        centerprint(activator, "Sequence completed!")
    end
    self.enemy = activator
    multi_trigger()
end

--[[
QUAKED trigger_counter (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.

After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
--]]
function trigger_counter()
    self.wait = -1
    if not self.count then
        self.count = 2
    end

    self.use = counter_use
end

--[[
==============================================================================

TELEPORT TRIGGERS

==============================================================================
--]]

local PLAYER_ONLY = 1
local SILENT      = 2

function play_teleport()
    local v
    local tmpstr

    v = random() * 5
    if v < 1 then
        tmpstr = "misc/r_tele1.wav"
    elseif v < 2 then
        tmpstr = "misc/r_tele2.wav"
    elseif v < 3 then
        tmpstr = "misc/r_tele3.wav"
    elseif v < 4 then
        tmpstr = "misc/r_tele4.wav"
    else
        tmpstr = "misc/r_tele5.wav"
    end

    sound (self, CHAN_VOICE, tmpstr, 1, ATTN_NORM)
    remove (self)
end

function spawn_tfog(org)
    s = spawn ()
    s.origin = org
    s.nextthink = time + 0.2
    s.think = play_teleport

    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
    WriteByte (MSG_MULTICAST, TE_TELEPORT)
    WriteCoord (MSG_MULTICAST, org.x)
    WriteCoord (MSG_MULTICAST, org.y)
    WriteCoord (MSG_MULTICAST, org.z)
    multicast (org, MULTICAST_PHS)
end

function tdeath_touch()
    local other2

    if other == self.owner then
        return
    end

    -- frag anyone who teleports in on top of an invincible player
    if other.classname == "player" then
        if other.invincible_finished > time and
            self.owner.invincible_finished > time then
            self.classname = "teledeath3"
            other.invincible_finished = 0
            self.owner.invincible_finished = 0
            T_Damage (other, self, self, 50000)
            other2 = self.owner
            self.owner = other
            T_Damage (other2, self, self, 50000)
        end

        if other.invincible_finished > time then
            self.classname = "teledeath2"
            T_Damage (self.owner, self, self, 50000)
            return
        end
    end

    if other.health and other.health > 0 then
        T_Damage (other, self, self, 50000)
    end
end


function spawn_tdeath(org, death_owner)
    local death

    death = spawn()
    death.classname = "teledeath"
    death.movetype = MOVETYPE_NONE
    death.solid = SOLID_TRIGGER
    death.angles = vec3(0,0,0)
    setsize (death, death_owner.mins - vec3(1,1,1), death_owner.maxs + vec3(1,1,1))
    setorigin (death, org)
    death.touch = tdeath_touch
    death.nextthink = time + 0.2
    death.think = SUB_Remove
    death.owner = death_owner

    force_retouch = 2 -- make sure even still objects get hit
end

function teleport_touch()
    local t
    local org

    if self.targetname and #self.targetname > 0 then
        if self.nextthink < time then
            return -- not fired yet
        end
    end

    if (self.spawnflags & PLAYER_ONLY) > 0 then
        if other.classname ~= "player" then
            return
        end
    end

    -- only teleport living creatures
    if other.health <= 0 or other.solid ~= SOLID_SLIDEBOX then
        return
    end

    SUB_UseTargets ()

    -- put a tfog where the player was
    spawn_tfog (other.origin)

    t = find (world, "targetname", self.target)
    if not t then
        objerror ("couldn't find target")
    end

    -- spawn a tfog flash in front of the destination
    makevectors (t.mangle)
    org = t.origin + 32 * v_forward

    spawn_tfog (org)
    spawn_tdeath(t.origin, other)

    -- move the player and lock him down for a little while
    if not other.health or other.health == 0 then
        other.origin = t.origin
        other.velocity = (v_forward * other.velocity.x) + (v_forward * other.velocity.y)
        return
    end

    setorigin (other, t.origin)
    other.angles = t.mangle
    if other.classname == "player" then
        other.fixangle = 1 -- turn this way immediately
        other.teleport_time = time + 0.7
        if (other.flags & FL_ONGROUND) > 0 then
            other.flags = other.flags - FL_ONGROUND
        end
        other.velocity = v_forward * 300
    end
    other.flags = other.flags - other.flags & FL_ONGROUND
end

--[[
QUAKED info_teleport_destination (.5 .5 .5) (-8 -8 -8) (8 8 32)
This is the destination marker for a teleporter.  It should have a "targetname" field with the same value as a teleporter's "target" field.
--]]
function info_teleport_destination()
    -- this does nothing, just serves as a target spot
    self.mangle = self.angles
    self.angles = vec3(0,0,0)
    self.model = ""
    self.origin = self.origin + vec3(0,0,27)
    if not self.targetname or #self.targetname == 0 then
        objerror ("no targetname")
    end
end

function teleport_use()
    self.nextthink = time + 0.2
    force_retouch = 2 -- make sure even still objects get hit
    self.think = SUB_Null
end

--[[
QUAKED trigger_teleport (.5 .5 .5) ? PLAYER_ONLY SILENT
Any object touching this will be transported to the corresponding info_teleport_destination entity. You must set the "target" field, and create an object with a "targetname" field that matches.

If the trigger_teleport has a targetname, it will only teleport entities when it has been fired.
--]]
function trigger_teleport()
    local o

    InitTrigger()
    self.touch = teleport_touch
    -- find the destination
    if not self.target or #self.target == 0 then
        objerror ("no target")
    end
    self.use = teleport_use

    if (self.spawnflags & SILENT) == 0 then
        precache_sound ("ambience/hum1.wav")
        o = (self.mins + self.maxs)*0.5
        ambientsound (o, "ambience/hum1.wav",0.5 , ATTN_STATIC)
    end
end

--[[
==============================================================================

trigger_setskill

==============================================================================
--]]

--[[
QUAKED trigger_setskill (.5 .5 .5) ?
sets skill level to the value of "message".
Only used on start map.
--]]
function trigger_setskill()
    remove (self)
end


--[[
==============================================================================

ONLY REGISTERED TRIGGERS

==============================================================================
--]]

function trigger_onlyregistered_touch()
    if other.classname ~= "player" then
        return
    end
    if self.attack_finished > time then
        return
    end

    self.attack_finished = time + 2
    if cvar("registered") > 0 then
        self.message = ""
        SUB_UseTargets()
        remove (self)
    else
        if not self.message and self.message ~= "" then
            centerprint (other, self.message)
            sound (other, CHAN_BODY, "misc/talk.wav", 1, ATTN_NORM)
        end
    end
end

--[[
QUAKED trigger_onlyregistered (.5 .5 .5) ?
Only fires if playing the registered version, otherwise prints the message
--]]
function trigger_onlyregistered()
    precache_sound ("misc/talk.wav")
    InitTrigger()
    self.touch = trigger_onlyregistered_touch
end

--============================================================================

function hurt_on()
    self.solid = SOLID_TRIGGER
    self.nextthink = -1
end

function hurt_touch()
    if other.takedamage > 0 then
        self.solid = SOLID_NOT
        T_Damage (other, self, self, self.dmg)
        self.think = hurt_on
        self.nextthink = time + 1
    end
end

--[[
QUAKED trigger_hurt (.5 .5 .5) ?
Any object touching this will be hurt
set dmg to damage amount
defalt dmg = 5
--]]
function trigger_hurt()
    InitTrigger()
    self.touch = hurt_touch
    if not self.dmg then
        self.dmg = 5
    end
end

--============================================================================

local PUSH_ONCE = 1

function trigger_push_touch()
    if other.classname == "grenade" then
        other.velocity = self.speed * self.movedir * 10
    elseif other.health > 0 then
        other.velocity = self.speed * self.movedir * 10
        if other.classname == "player" then
            if other.fly_sound < time then
                other.fly_sound = time + 1.5
                sound (other, CHAN_AUTO, "ambience/windfly.wav", 1, ATTN_NORM)
            end
        end
    end
    if (self.spawnflags & PUSH_ONCE) > 0 then
        remove(self)
    end
end

--[[
QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE
Pushes the player
--]]
function trigger_push()
    InitTrigger()
    precache_sound ("ambience/windfly.wav")
    self.touch = trigger_push_touch
    if not self.speed then
        self.speed = 1000
    end
end

--============================================================================

function trigger_monsterjump_touch()
    if other.flags & (FL_MONSTER | FL_FLY | FL_SWIM) ~= FL_MONSTER then
        return
    end

    -- set XY even if not on ground, so the jump will clear lips
    other.velocity.x = self.movedir.x * self.speed
    other.velocity.y = self.movedir.y * self.speed

    if (other.flags & FL_ONGROUND) == 0 then
        return
    end

    other.flags = other.flags - FL_ONGROUND

    other.velocity.z = self.height
end

--[[
QUAKED trigger_monsterjump (.5 .5 .5) ?
Walking monsters that touch this will jump in the direction of the trigger's angle
"speed" default to 200, the speed thrown forward
"height" default to 200, the speed thrown upwards
--]]
function trigger_monsterjump()
    if not self.speed then
        self.speed = 200
    end
    if not self.height then
        self.height = 200
    end
    if self.angles == vec3(0,0,0) then
        self.angles = vec3(0,360,0)
    end
    InitTrigger()
    self.touch = trigger_monsterjump_touch
end
