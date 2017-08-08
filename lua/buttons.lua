--[[
    buttons.qc

    button and multiple button

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

function button_wait()
    self.state = STATE_TOP
    self.nextthink = self.ltime + self.wait
    self.think = button_return
    activator = self.enemy
    SUB_UseTargets()
    self.frame = 1 -- use alternate textures
end

function button_done()
    self.state = STATE_BOTTOM
end

function button_return()
    self.state = STATE_DOWN
    SUB_CalcMove (self.pos1, self.speed, button_done)
    self.frame = 0 -- use normal textures
    if self.health > 0 then
        self.takedamage = DAMAGE_YES -- can be shot again
    end
end


function button_blocked()
    -- do nothing, just don't ome all the way back out
end

function button_fire()
    if self.state == STATE_UP or self.state == STATE_TOP then
        return
    end

    sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM)

    self.state = STATE_UP
    SUB_CalcMove (self.pos2, self.speed, button_wait);
end


function button_use()
    self.enemy = activator
    button_fire ()
end

function button_touch()
    if other.classname ~= "player" then
        return
    end
    self.enemy = other
    button_fire ()
end

function button_killed()
    self.enemy = damage_attacker
    self.health = self.max_health
    self.takedamage = DAMAGE_NO -- wil be reset upon return
    button_fire ()
end


--[[
QUAKED func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"        determines the opening direction
"target"    all entities with a matching targetname will be used
"speed"        override the default 40 speed
"wait"        override the default 1 second wait (-1 = never return)
"lip"        override the default 4 pixel lip remaining at end of move
"health"    if set, the button must be killed instead of touched
"sounds"
0) steam metal
1) wooden clunk
2) metallic click
3) in-out
--]]
function func_button()
    local gtemp, ftemp;

    if self.sounds == 0 then
        precache_sound ("buttons/airbut1.wav")
        self.noise = "buttons/airbut1.wav"
    elseif self.sounds == 1 then
        precache_sound ("buttons/switch21.wav")
        self.noise = "buttons/switch21.wav"
    elseif self.sounds == 2 then
        precache_sound ("buttons/switch02.wav")
        self.noise = "buttons/switch02.wav"
    elseif self.sounds == 3 then
        precache_sound ("buttons/switch04.wav")
        self.noise = "buttons/switch04.wav"
    end
    
    SetMovedir ()

    self.movetype = MOVETYPE_PUSH
    self.solid = SOLID_BSP
    setmodel (self, self.model)

    self.blocked = button_blocked
    self.use = button_use

    if self.health > 0 then
        self.max_health = self.health
        self.th_die = button_killed
        self.takedamage = DAMAGE_YES
    else
        self.touch = button_touch
    end

    if not self.speed or self.speed == 0 then
        self.speed = 40
    end
    if not self.wait or self.wait == 0 then
        self.wait = 1
    end
    if not self.lip or self.lip == 0 then
        self.lip = 4
    end

    self.state = STATE_BOTTOM

    self.pos1 = self.origin
    self.pos2 = self.pos1 + self.movedir*(math.abs(self.movedir*self.size) - self.lip)
end
