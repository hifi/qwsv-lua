--[[
    subs.qc

    sub-functions, mostly movement related

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


function SUB_Null() end

function SUB_Remove() remove(self) end

--[[
QuakeEd only writes a single float for angles (bad idea), so up and down are
just constant angles.
--]]
function SetMovedir()
    if self.angles == vec3(0,-1,0) then
        self.movedir = vec3(0,0,1)
    elseif self.angles == vec3(0,-2,0) then
        self.movedir = vec3(0,0,-1)
    else
        makevectors (self.angles)
        self.movedir = v_forward
    end
    
    self.angles = vec3(0,0,0)
end

--[[
================
InitTrigger
================
--]]
function InitTrigger()
    -- trigger angles are used for one-way touches.  An angle of 0 is assumed
    -- to mean no restrictions, so use a yaw of 360 instead.
    if self.angles ~= vec3(0,0,0) then
        SetMovedir()
    end
    self.solid = SOLID_TRIGGER
    setmodel (self, self.model) -- set size and link into world
    self.movetype = MOVETYPE_NONE
    self.modelindex = 0
    self.model = ""
end

--[[
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
--]]
function SUB_CalcMoveEnt(ent, tdest, tspeed, func)
    local stemp
    stemp = self
    self = ent

    SUB_CalcMove (tdest, tspeed, func)
    self = stemp
end

function SUB_CalcMove(tdest, tspeed, func)
    local vdestdelta
    local len, traveltime

    if not tspeed or tspeed == 0 then
        objerror("No speed is defined!")
    end

    self.think1 = func
    self.finaldest = tdest
    self.think = SUB_CalcMoveDone

    if tdest == self.origin then
        self.velocity = vec3(0,0,0)
        self.nextthink = self.ltime + 0.1
        return
    end
        
    -- set destdelta to the vector needed to move
    vdestdelta = tdest - self.origin;
    
    -- calculate length of vector
    len = #vdestdelta
    
    -- divide by speed to get time to reach dest
    traveltime = len / tspeed

    if traveltime < 0.03 then
        traveltime = 0.03
    end
    
    -- set nextthink to trigger a think when dest is reached
    self.nextthink = self.ltime + traveltime

    -- scale the destdelta vector by the time spent traveling to get velocity
    self.velocity = vdestdelta * (1/traveltime) -- qcc won't take vec/float    
end

--[[
============
After moving, set origin to exact final destination
============
--]]
function SUB_CalcMoveDone()
    setorigin(self, self.finaldest)
    self.velocity = vec3(0,0,0)
    self.nextthink = -1
    if self.think1 then
        self.think1()
    end
end


--[[
/*
=============
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from
self.angles rotating 

The calling function should make sure self.think is valid
===============
*/
void(entity ent, vector destangle, float tspeed, void() func) SUB_CalcAngleMoveEnt =
{
local entity        stemp;
    stemp = self;
    self = ent;
    SUB_CalcAngleMove (destangle, tspeed, func);
    self = stemp;
};

void(vector destangle, float tspeed, void() func) SUB_CalcAngleMove =
{
local vector    destdelta;
local float        len, traveltime;

    if (!tspeed)
        objerror("No speed is defined!");
        
// set destdelta to the vector needed to move
    destdelta = destangle - self.angles;
    
// calculate length of vector
    len = vlen (destdelta);
    
// divide by speed to get time to reach dest
    traveltime = len / tspeed;

// set nextthink to trigger a think when dest is reached
    self.nextthink = self.ltime + traveltime;

// scale the destdelta vector by the time spent traveling to get velocity
    self.avelocity = destdelta * (1 / traveltime);
    
    self.think1 = func;
    self.finalangle = destangle;
    self.think = SUB_CalcAngleMoveDone;
};

/*
============
After rotating, set angle to exact final angle
============
*/
void() SUB_CalcAngleMoveDone =
{
    self.angles = self.finalangle;
    self.avelocity = '0 0 0';
    self.nextthink = -1;
    if (self.think1)
        self.think1();
};


--]]
--=============================================================================

function DelayThink()
    activator = self.enemy
    SUB_UseTargets ()
    remove(self)
end

--[[
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
--]]
function SUB_UseTargets()
    local t, stemp, otemp, act

    --
    -- check for a delay
    --
    if self.delay and self.delay > 0 then
        -- create a temp object to fire at a later time
        t = spawn()
        t.classname = "DelayedUse"
        t.nextthink = time + self.delay
        t.think = DelayThink
        t.enemy = activator
        t.message = self.message
        t.killtarget = self.killtarget
        t.target = self.target
        return
    end
    
    
    --
    -- print the message
    --
    if activator and activator.classname == "player" and self.message and self.message ~= "" then
        centerprint (activator, self.message)
        if not self.noise then
            sound (activator, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NORM)
        end
    end

    --
    -- kill the killtagets
    --
    if self.killtarget and #self.killtarget > 0 then
        t = world
        while true do
            t = find (t, "targetname", self.killtarget)
            if not t then
                return
            end
            remove (t)
        end
    end
    
    --
    -- fire targets
    --
    if self.target and #self.target > 0 then
        act = activator
        t = world
        while true do
            t = find (t, "targetname", self.target)
            if not t then
                return
            end
            stemp = self
            otemp = other
            self = t
            other = stemp
            if self.use ~= SUB_Null then
                if self.use then
                    self.use ()
                end
            end
            self = stemp
            other = otemp
            activator = act
        end
    end
end
