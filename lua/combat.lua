--[[
    combat.qc

    damage, obit, etc related functions

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

--============================================================================

--[[
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
--]]
function CanDamage(targ, inflictor)
    -- bmodels need special checking because their origin is 0,0,0
    if targ.movetype == MOVETYPE_PUSH then
        traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self)
        if trace_fraction == 1 then
            return true
        end
        if trace_ent == targ then
            return false
        end
        return false
    end
    
    traceline(inflictor.origin, targ.origin, TRUE, self)
    if trace_fraction == 1 then
        return true
    end

    traceline(inflictor.origin, targ.origin + vec3(15,15,0), TRUE, self)
    if trace_fraction == 1 then
        return true
    end

    traceline(inflictor.origin, targ.origin + vec3(-15,-15,0), TRUE, self)
    if trace_fraction == 1 then
        return true
    end

    traceline(inflictor.origin, targ.origin + vec3(-15,15,0), TRUE, self)
    if trace_fraction == 1 then
        return true
    end

    traceline(inflictor.origin, targ.origin + vec3(15,-15,0), TRUE, self)
    if trace_fraction == 1 then
        return true
    end

    return false
end


--[[
============
Killed
============
--]]
function Killed(targ, attacker)
    local oself

    oself = self
    self = targ
    
    if self.health < -99 then
        self.health = -99 -- don't let sbar look bad if a player
    end

    if self.movetype == MOVETYPE_PUSH or self.movetype == MOVETYPE_NONE then
        -- doors, triggers, etc
        self.th_die ()
        self = oself
        return
    end

    self.enemy = attacker;

    -- bump the monster counter
    if (self.flags & FL_MONSTER) > 0 then
        killed_monsters = killed_monsters + 1
        WriteByte (MSG_ALL, SVC_KILLEDMONSTER)
    end

    ClientObituary(self, attacker)
    
    self.takedamage = DAMAGE_NO
    self.touch = SUB_Null
    self.effects = 0

    self.th_die ()
    
    self = oself
end


--[[
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
--]]
function T_Damage(targ, inflictor, attacker, damage)
    local dir
    local oldself
    local save
    local take
    local s
    local attackerteam, targteam

    if not targ.takedamage or targ.takedamage == 0 then
        return
    end

    -- used by buttons and triggers to set activator for target firing
    damage_attacker = attacker

    -- check for quad damage powerup on the attacker
    if attacker.super_damage_finished and attacker.super_damage_finished > time and inflictor.classname ~= "door" then
        if deathmatch == 4 then
            damage = damage * 8
        else
            damage = damage * 4
        end
    end

    -- save damage based on the target's armor level
    save = math.ceil(targ.armortype*damage)
    if save >= targ.armorvalue then
        save = targ.armorvalue
        targ.armortype = 0 -- lost all armor
        targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3))
    end
    
    targ.armorvalue = targ.armorvalue - save
    take = math.ceil(damage-save)

    -- add to the damage total for clients, which will be sent as a single
    -- message at the end of the frame
    -- FIXME: remove after combining shotgun blasts?
    if (targ.flags & FL_CLIENT) > 0 then
        targ.dmg_take = targ.dmg_take + take
        targ.dmg_save = targ.dmg_save + save
        targ.dmg_inflictor = inflictor
    end

    damage_inflictor = inflictor

    -- figure momentum add
    if inflictor ~= world and targ.movetype == MOVETYPE_WALK then
        dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5
        dir = normalize(dir)
        -- Set kickback for smaller weapons
        --Zoid -- use normal NQ kickback
        --        -- Read: only if it's not yourself doing the damage
        --        if ( (damage < 60) & ((attacker.classname == "player") & (targ.classname == "player")) & ( attacker.netname != targ.netname)) 
        --            targ.velocity = targ.velocity + dir * damage * 11;
        --        else                        
        -- Otherwise, these rules apply to rockets and grenades                        
        -- for blast velocity

        targ.velocity = targ.velocity + dir * damage * 8

        -- Rocket Jump modifiers
        if (rj > 1) and ((attacker.classname == "player") and (targ.classname == "player")) and (attacker.netname == targ.netname) then
            targ.velocity = targ.velocity + dir * damage * rj
        end
    end

    -- check for godmode or invincibility
    if (targ.flags & FL_GODMODE) > 0 then
        return
    end

    if targ.invincible_finished and targ.invincible_finished >= time then
        if self.invincible_sound < time then
            sound (targ, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM)
            self.invincible_sound = time + 2
        end
        return
    end

    -- team play damage avoidance
    --ZOID 12-13-96: self.team doesn't work in QW.  Use keys
    attackerteam = infokey(attacker, "team")
    targteam = infokey(targ, "team")

    if (teamplay == 1) and (targteam == attackerteam) and
        (attacker.classname == "player") and (attackerteam ~= "") and
        inflictor.classname ~="door" then
        return
    end

    if (teamplay == 3) and (targteam == attackerteam) and
        (attacker.classname == "player") and (attackerteam ~= "") and
        (targ ~= attacker) and inflictor.classname ~= "door" then
        return
    end
        
    -- do the damage
    targ.health = targ.health - take

    if targ.health <= 0 then
        Killed (targ, attacker)
        return
    end

    -- react to the damage
    oldself = self
    self = targ

    if self.th_pain then
        self.th_pain (attacker, take)
    end

    self = oldself
end

--[[
============
T_RadiusDamage
============
--]]
function T_RadiusDamage(inflictor, attacker, damage, ignore, dtype)
    local points;
    local head;
    local org;

    head = findradius(inflictor.origin, damage+40)
    
    while head do
        if head ~= ignore then
            if head.takedamage > 0 then
                org = head.origin + (head.mins + head.maxs)*0.5
                points = 0.5 * #(inflictor.origin - org)
                if points < 0 then
                    points = 0
                end
                points = damage - points
                
                if head == attacker then
                    points = points * 0.5
                end
                if points > 0 then
                    if CanDamage (head, inflictor) then
                        head.deathtype = dtype
                        T_Damage (head, inflictor, attacker, points)
                    end
                end
            end
        end
        head = head.chain
    end
end

--[[
============
T_BeamDamage
============
--]]
function T_BeamDamage(attacker, damage)
    local points;
    local head;
    
    head = findradius(attacker.origin, damage+40)
    
    while head do
        if head.takedamage > 0 then
            points = 0.5 * #(attacker.origin - head.origin)
            if points < 0 then
                points = 0
            end
            points = damage - points
            if head == attacker then
                points = points * 0.5
            end
            if points > 0 then
                if CanDamage (head, attacker) then
                    T_Damage (head, attacker, attacker, points)
                end
            end
        end
        head = head.chain
    end
end

