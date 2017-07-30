--[[
    server.qc

    server functions (movetarget code)

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

function monster_ogre() remove(self) end
function monster_demon1() remove(self) end
function monster_shambler() remove(self) end
function monster_knight() remove(self) end
function monster_army() remove(self) end
function monster_wizard() remove(self) end
function monster_dog() remove(self) end
function monster_zombie() remove(self) end
function monster_boss() remove(self) end
function monster_tarbaby() remove(self) end
function monster_hell_knight() remove(self) end
function monster_fish() remove(self) end
function monster_shalrath() remove(self) end
function monster_enforcer() remove(self) end
function monster_oldone() remove(self) end
function event_lightning() remove(self) end

--[[
==============================================================================

MOVETARGET CODE

The angle of the movetarget effects standing and bowing direction, but has no effect on movement, which allways heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
--]]

--[[
=============
t_movetarget

Something has bumped into a movetarget.  If it is a monster
moving towards it, change the next destination and continue.
==============
--]]
function t_movetarget()
    local temp

    if other.movetarget ~= self then
        return
    end
    
    if other.enemy then
        return -- fighting, not following a path
    end

    temp = self
    self = other
    other = temp

    if self.classname == "monster_ogre" then
        sound (self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);-- play chainsaw drag sound
    end

    --dprint ("t_movetarget\n");
    self.movetarget = find (world, targetname, other.target)
    self.goalentity = self.movetarget
    self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin)
    if not self.movetarget or self.movetarget == 0 then
        self.pausetime = time + 999999
        self.th_stand ()
        return
    end
end



function movetarget_f()
    if not self.targetname or #self.targetname == 0 then
        objerror ("monster_movetarget: no targetname")
    end
        
    self.solid = SOLID_TRIGGER
    self.touch = t_movetarget
    setsize (self, vec3(-8,-8,-8), vec3(8,8,8))
end

--[[
QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
--]]
function path_corner()
    movetarget_f ()
end

--============================================================================
