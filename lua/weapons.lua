--[[
    weapons.qc

    weapon and weapon hit functions

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

]]--

-- called by worldspawn
function W_Precache()
    precache_sound ("weapons/r_exp3.wav")   -- new rocket explosion
    precache_sound ("weapons/rocket1i.wav") -- spike gun
    precache_sound ("weapons/sgun1.wav")
    precache_sound ("weapons/guncock.wav")  -- player shotgun
    precache_sound ("weapons/ric1.wav")     -- ricochet (used in c code)
    precache_sound ("weapons/ric2.wav")     -- ricochet (used in c code)
    precache_sound ("weapons/ric3.wav")     -- ricochet (used in c code)
    precache_sound ("weapons/spike2.wav")   -- super spikes
    precache_sound ("weapons/tink1.wav")    -- spikes tink (used in c code)
    precache_sound ("weapons/grenade.wav")  -- grenade launcher
    precache_sound ("weapons/bounce.wav")   -- grenade bounce
    precache_sound ("weapons/shotgn2.wav")  -- super shotgun
end

function crandom()
    return 2*(random() - 0.5)
end

--[[
================
W_FireAxe
================
]]
function W_FireAxe()
    local source
    local org

    makevectors (self.v_angle)
    source = self.origin + vec3(0,0,16)
    trace_fraction = 1337
    traceline (source, source + v_forward*64, FALSE, self)
    if trace_fraction == 1.0 then
        return
    end

    org = trace_endpos - v_forward*4

    if trace_ent.takedamage > 0 then
        trace_ent.axhitme = 1
        SpawnBlood (org, 20)
        if deathmatch > 3 then
            T_Damage (trace_ent, self, self, 75)
        else
            T_Damage (trace_ent, self, self, 20)
        end
    else
        -- hit wall
        sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM)

        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
        WriteByte (MSG_MULTICAST, TE_GUNSHOT)
        WriteByte (MSG_MULTICAST, 3)
        WriteCoord (MSG_MULTICAST, org.x)
        WriteCoord (MSG_MULTICAST, org.y)
        WriteCoord (MSG_MULTICAST, org.z)
        multicast (org, MULTICAST_PVS)
    end
end

--============================================================================

function wall_velocity()
    local vel

    vel = normalize (self.velocity)
    vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5))
    vel = vel + 2*trace_plane_normal
    vel = vel * 200

    return vel
end

--[[
================
SpawnMeatSpray
================
]]
function SpawnMeatSpray(org, vel)
    local missile
    local org

    missile = spawn ()
    missile.owner = self
    missile.movetype = MOVETYPE_BOUNCE
    missile.solid = SOLID_NOT

    makevectors (self.angles)

    missile.velocity = vel
    missile.velocity.z = missile.velocity.z + 250 + 50*random()

    missile.avelocity = vec3(3000,1000,2000)

    -- set missile duration
    missile.nextthink = time + 1
    missile.think = SUB_Remove

    setmodel (missile, "progs/zom_gib.mdl")
    setsize (missile, vec3(0,0,0), vec3(0,0,0))
    setorigin (missile, org)
end

--[[
================
SpawnBlood
================
]]--
function SpawnBlood(org, damage)
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
    WriteByte (MSG_MULTICAST, TE_BLOOD)
    WriteByte (MSG_MULTICAST, 1)
    WriteCoord (MSG_MULTICAST, org.x)
    WriteCoord (MSG_MULTICAST, org.y)
    WriteCoord (MSG_MULTICAST, org.z)
    multicast (org, MULTICAST_PVS)
end

--[[
================
spawn_touchblood
================
]]--
function spawn_touchblood(damage)
    local vel

    vel = wall_velocity () * 0.2
    SpawnBlood (self.origin + vel*0.01, damage)
end

--[[
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
]]

local multi_ent
local multi_damage

local blood_org
local blood_count

local puff_org
local puff_count

function ClearMultiDamage()
    multi_ent = world
    multi_damage = 0
    blood_count = 0
    puff_count = 0
end

function ApplyMultiDamage()
    if not multi_ent then
        return
    end
    T_Damage (multi_ent, self, self, multi_damage)
end

function AddMultiDamage(hit, damage)
    if not hit then
        return
    end

    if hit ~= multi_ent then
        ApplyMultiDamage ()
        multi_damage = damage
        multi_ent = hit
    else
        multi_damage = multi_damage + damage
    end
end

function Multi_Finish()
    if puff_count > 0 then
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
        WriteByte (MSG_MULTICAST, TE_GUNSHOT)
        WriteByte (MSG_MULTICAST, puff_count)
        WriteCoord (MSG_MULTICAST, puff_org.x)
        WriteCoord (MSG_MULTICAST, puff_org.y)
        WriteCoord (MSG_MULTICAST, puff_org.z)
        multicast (puff_org, MULTICAST_PVS)
    end

    if blood_count > 0 then
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
        WriteByte (MSG_MULTICAST, TE_BLOOD)
        WriteByte (MSG_MULTICAST, blood_count)
        WriteCoord (MSG_MULTICAST, blood_org.x)
        WriteCoord (MSG_MULTICAST, blood_org.y)
        WriteCoord (MSG_MULTICAST, blood_org.z)
        multicast (puff_org, MULTICAST_PVS)
    end
end

--[[
==============================================================================
BULLETS
==============================================================================
]]

--[[
================
TraceAttack
================
]]
function TraceAttack(damage, dir)
    local vel, org

    vel = normalize(dir + v_up*crandom() + v_right*crandom())
    vel = vel + 2*trace_plane_normal
    vel = vel * 200

    org = trace_endpos - dir*4

    if trace_ent.takedamage > 0 then
        blood_count = blood_count + 1
        blood_org = org
        AddMultiDamage (trace_ent, damage)
    else
        puff_count = puff_count + 1
    end
end

--[[
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
]]
function FireBullets(shotcount, dir, spread)
    local direction
    local src

    makevectors(self.v_angle)

    src = self.origin + v_forward*10
    src.z = self.absmin.z + self.size.z * 0.7

    ClearMultiDamage ()

    traceline (src, src + dir*2048, FALSE, self)
    puff_org = trace_endpos - dir*4

    while shotcount > 0 do
        direction = dir + crandom()*spread.x*v_right + crandom()*spread.y*v_up
        traceline (src, src + direction*2048, FALSE, self)
        if trace_fraction ~= 1.0 then
            TraceAttack (4, direction)
        end

        shotcount = shotcount - 1
    end

    ApplyMultiDamage ()
    Multi_Finish ()
end

--[[
================
W_FireShotgun
================
]]
function W_FireShotgun()
    local dir

    sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM)

    msg_entity = self
    WriteByte (MSG_ONE, SVC_SMALLKICK)

    if deathmatch ~= 4 then
        self.ammo_shells = self.ammo_shells - 1
        self.currentammo = self.ammo_shells
    end

    dir = aim (self, 100000)
    FireBullets (6, dir, vec3(0.04,0.04,0))
end

--[[
================
W_FireSuperShotgun
================
]]
function W_FireSuperShotgun()
    local dir

    if self.currentammo == 1 then
        W_FireShotgun ()
        return
    end

    sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM)

    msg_entity = self
    WriteByte (MSG_ONE, SVC_BIGKICK)

    if deathmatch ~= 4 then
        self.ammo_shells = self.ammo_shells - 2
        self.currentammo = self.ammo_shells
    end
    dir = aim (self, 100000)
    FireBullets (14, dir, vec3(0.14,0.08,0))
end

--[[
==============================================================================

ROCKETS

==============================================================================
]]

function T_MissileTouch()
    local damg

    if other == self.owner then
        return -- don't explode on owner
    end

    if self.voided > 0 then
        return
    end

    self.voided = 1

    if pointcontents(self.origin) == CONTENT_SKY then
        remove(self)
        return
    end

    damg = 100 + random()*20

    if other.health > 0 then
        other.deathtype = "rocket"
        T_Damage (other, self, self.owner, damg )
    end

    -- don't do radius damage to the other, because all the damage
    -- was done in the impact
    T_RadiusDamage (self, self.owner, 120, other, "rocket")

    self.origin = self.origin - 8 * normalize(self.velocity)

    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
    WriteByte (MSG_MULTICAST, TE_EXPLOSION)
    WriteCoord (MSG_MULTICAST, self.origin.x)
    WriteCoord (MSG_MULTICAST, self.origin.y)
    WriteCoord (MSG_MULTICAST, self.origin.z)
    multicast (self.origin, MULTICAST_PHS)

    remove(self)
end


--[[
================
W_FireRocket
================
]]
function W_FireRocket()
    if deathmatch ~= 4 then
        self.ammo_rockets = self.ammo_rockets - 1
        self.currentammo = self.ammo_rockets
    end

    sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM)

    msg_entity = self
    WriteByte (MSG_ONE, SVC_SMALLKICK)

    newmis = spawn ()
    newmis.owner = self
    newmis.movetype = MOVETYPE_FLYMISSILE
    newmis.solid = SOLID_BBOX

    -- set newmis speed
    makevectors (self.v_angle)
    newmis.velocity = aim(self, 1000)
    newmis.velocity = newmis.velocity * 1000
    newmis.angles = vectoangles(newmis.velocity)

    newmis.touch = T_MissileTouch
    newmis.voided = 0

    -- set newmis duration
    newmis.nextthink = time + 5
    newmis.think = SUB_Remove
    newmis.classname = "rocket"

    setmodel (newmis, "progs/missile.mdl")
    setsize (newmis, vec3(0,0,0), vec3(0,0,0))
    setorigin (newmis, self.origin + v_forward*8 + vec3(0,0,16))
end

--[[
===============================================================================
LIGHTNING
===============================================================================
]]

function LightningHit(from, damage)
    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
    WriteByte (MSG_MULTICAST, TE_LIGHTNINGBLOOD)
    WriteCoord (MSG_MULTICAST, trace_endpos.x)
    WriteCoord (MSG_MULTICAST, trace_endpos.y)
    WriteCoord (MSG_MULTICAST, trace_endpos.z)
    multicast (trace_endpos, MULTICAST_PVS)

    T_Damage (trace_ent, from, from, damage)
end

--[[
=================
LightningDamage
=================
]]
function LightningDamage(p1, p2, from, damage)
    local e1,e2
    local f

    f = p2 - p1
    normalize (f)
    f.x = 0 - f.y
    f.y = f.x
    f.z = 0
    f = f*16

    e1 = world
    e2 = world

    traceline (p1, p2, FALSE, self)

    if trace_ent.takedamage > 0 then
        LightningHit (from, damage)
        if self.classname == "player" then
            if other.classname == "player" then
                trace_ent.velocity.z = trace_ent.velocity.z + 400
            end
        end
    end
    e1 = trace_ent

    traceline (p1 + f, p2 + f, FALSE, self)
    if trace_ent ~= e1 and trace_ent.takedamage > 0 then
        LightningHit (from, damage)
    end
    e2 = trace_ent

    traceline (p1 - f, p2 - f, FALSE, self)
    if trace_ent ~= e1 and trace_ent ~= e2 and trace_ent.takedamage > 0 then
        LightningHit (from, damage)
    end
end

function W_FireLightning()
    local org
    local cells

    if self.ammo_cells < 1 then
        self.weapon = W_BestWeapon ()
        W_SetCurrentAmmo ()
        return
    end

    -- explode if under water
    if self.waterlevel > 1 then
        if deathmatch > 3 then
            if random() <= 0.5 then
                self.deathtype = "selfwater"
                T_Damage (self, self, self.owner, 4000)
            else
                cells = self.ammo_cells
                self.ammo_cells = 0
                W_SetCurrentAmmo ()
                T_RadiusDamage (self, self, 35*cells, world, "")
                return
            end
        else
            cells = self.ammo_cells
            self.ammo_cells = 0
            W_SetCurrentAmmo ()
            T_RadiusDamage (self, self, 35*cells, world,"")
            return
        end
    end

    if not self.t_width or self.t_width < time then
        sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM)
        self.t_width = time + 0.6
    end
    msg_entity = self
    WriteByte (MSG_ONE, SVC_SMALLKICK)

    if deathmatch ~= 4 then
        self.ammo_cells = self.ammo_cells - 1
        self.currentammo = self.ammo_cells
    end

    org = self.origin + vec3(0,0,16)

    traceline (org, org + v_forward*600, TRUE, self)

    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
    WriteByte (MSG_MULTICAST, TE_LIGHTNING2)
    WriteEntity (MSG_MULTICAST, self)
    WriteCoord (MSG_MULTICAST, org.x)
    WriteCoord (MSG_MULTICAST, org.y)
    WriteCoord (MSG_MULTICAST, org.z)
    WriteCoord (MSG_MULTICAST, trace_endpos.x)
    WriteCoord (MSG_MULTICAST, trace_endpos.y)
    WriteCoord (MSG_MULTICAST, trace_endpos.z)
    multicast (org, MULTICAST_PHS)

    LightningDamage (self.origin, trace_endpos + v_forward*4, self, 30)
end


--=============================================================================


function GrenadeExplode()
    if self.voided > 0 then
        return
    end
    self.voided = 1

    T_RadiusDamage (self, self.owner, 120, world, "grenade")

    WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
    WriteByte (MSG_MULTICAST, TE_EXPLOSION)
    WriteCoord (MSG_MULTICAST, self.origin.x)
    WriteCoord (MSG_MULTICAST, self.origin.y)
    WriteCoord (MSG_MULTICAST, self.origin.z)
    multicast (self.origin, MULTICAST_PHS)

    remove (self)
end

function GrenadeTouch()
    if other == self.owner then
        return -- don't explode on owner
    end
    if other.takedamage == DAMAGE_AIM then
        GrenadeExplode()
        return
    end
    sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM) -- bounce sound
    if self.velocity == vec3(0,0,0) then
        self.avelocity = vec3(0,0,0)
    end
end

--[[
================
W_FireGrenade
================
]]
function W_FireGrenade()
    if deathmatch ~= 4 then
        self.ammo_rockets = self.ammo_rockets - 1
        self.currentammo = self.ammo_rockets
    end

    sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM)

    msg_entity = self
    WriteByte (MSG_ONE, SVC_SMALLKICK)

    newmis = spawn ()
    newmis.voided = 0
    newmis.owner = self
    newmis.movetype = MOVETYPE_BOUNCE
    newmis.solid = SOLID_BBOX
    newmis.classname = "grenade"

    -- set newmis speed
    makevectors (self.v_angle)

    if self.v_angle.x > 0 then
        newmis.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10
    else
        newmis.velocity = aim(self, 10000)
        newmis.velocity = newmis.velocity * 600
        newmis.velocity.z = 200
    end

    newmis.avelocity = vec3(300,300,300)

    newmis.angles = vectoangles(newmis.velocity)

    newmis.touch = GrenadeTouch

    -- set newmis duration
    if deathmatch == 4 then
        newmis.nextthink = time + 2.5
        self.attack_finished = time + 1.1
        T_Damage (self, self, self.owner, 10)
    else
        newmis.nextthink = time + 2.5
    end

    newmis.think = GrenadeExplode

    setmodel (newmis, "progs/grenade.mdl")
    setsize (newmis, vec3(0,0,0), vec3(0,0,0))
    setorigin (newmis, self.origin)
end

--=============================================================================

--[[
===============
launch_spike

Used for both the player and the ogre
===============
]]--
function launch_spike(org, dir)

    newmis = spawn()
    newmis.voided = 0
    newmis.owner = self
    newmis.movetype = MOVETYPE_FLYMISSILE
    newmis.solid = SOLID_BBOX

    newmis.angles = vectoangles(dir)

    newmis.touch = spike_touch
    newmis.classname = "spike"
    newmis.think = SUB_Remove
    newmis.nextthink = time + 6
    setmodel(newmis, "progs/spike.mdl")
    setsize(newmis, VEC_ORIGIN, VEC_ORIGIN)
    setorigin(newmis, org)

    newmis.velocity = dir * 1000
end

function W_FireSuperSpikes()
    local dir
    local old

    sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM)
    self.attack_finished = time + 0.2
    if deathmatch ~= 4 then
        self.ammo_nails = self.ammo_nails - 2
        self.currentammo = self.ammo_nails
    end
    dir = aim (self, 1000)
    launch_spike (self.origin + vec3(0,0,16), dir)
    newmis.touch = superspike_touch
    setmodel (newmis, "progs/s_spike.mdl")
    setsize (newmis, VEC_ORIGIN, VEC_ORIGIN)
    msg_entity = self
    WriteByte (MSG_ONE, SVC_SMALLKICK)
end

function W_FireSpikes(ox)
    local dir
    local old

    makevectors (self.v_angle)

    if self.ammo_nails >= 2 and self.weapon == IT_SUPER_NAILGUN then
        W_FireSuperSpikes ()
        return
    end

    if self.ammo_nails < 1 then
        self.weapon = W_BestWeapon ()
        W_SetCurrentAmmo ()
        return
    end

    sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM)
    self.attack_finished = time + 0.2
    if deathmatch ~= 4 then
        self.ammo_nails = self.ammo_nails - 1
        self.currentammo  = self.ammo_nails
    end
    dir = aim (self, 1000)
    launch_spike (self.origin + '0 0 16' + v_right*ox, dir)

    msg_entity = self
    WriteByte (MSG_ONE, SVC_SMALLKICK)
end

function spike_touch()
    local rand

    if other == self.owner then
        return
    end

    if self.voided > 0 then
        return
    end

    self.voided = 1

    if other.solid == SOLID_TRIGGER then
        return -- trigger field, do nothing
    end

    if pointcontents(self.origin) == CONTENT_SKY then
        remove(self)
        return
    end

    -- hit something that bleeds
    if other.takedamage > 0 then
        spawn_touchblood (9)
        other.deathtype = "nail"
        T_Damage (other, self, self.owner, 9)
    else
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
        if self.classname == "wizspike" then
            WriteByte (MSG_MULTICAST, TE_WIZSPIKE)
        elseif self.classname == "knightspike" then
            WriteByte (MSG_MULTICAST, TE_KNIGHTSPIKE)
        else
            WriteByte (MSG_MULTICAST, TE_SPIKE)
        end
        WriteCoord (MSG_MULTICAST, self.origin.x)
        WriteCoord (MSG_MULTICAST, self.origin.y)
        WriteCoord (MSG_MULTICAST, self.origin.z)
        multicast (self.origin, MULTICAST_PHS)
    end

    remove(self)
end

function superspike_touch()
    local rand

    if other == self.owner then
        return
    end

    if self.voided > 0 then
        return
    end
    self.voided = 1


    if other.solid == SOLID_TRIGGER then
        return -- trigger field, do nothing
    end

    if pointcontents(self.origin) == CONTENT_SKY then
        remove(self)
        return
    end

    -- hit something that bleeds
    if other.takedamage > 0 then
        spawn_touchblood (18)
        other.deathtype = "supernail"
        T_Damage (other, self, self.owner, 18)
    else
        WriteByte (MSG_MULTICAST, SVC_TEMPENTITY)
        WriteByte (MSG_MULTICAST, TE_SUPERSPIKE)
        WriteCoord (MSG_MULTICAST, self.origin.x)
        WriteCoord (MSG_MULTICAST, self.origin.y)
        WriteCoord (MSG_MULTICAST, self.origin.z)
        multicast (self.origin, MULTICAST_PHS)
    end

    remove(self)
end

--[[
===============================================================================

PLAYER WEAPON USE

===============================================================================
]]--

function W_SetCurrentAmmo()
    player_run() -- get out of any weapon firing states

    self.items = self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS))

    if self.weapon == IT_AXE then
        self.currentammo = 0
        self.weaponmodel = "progs/v_axe.mdl"
        self.weaponframe = 0
    elseif self.weapon == IT_SHOTGUN then
        self.currentammo = self.ammo_shells
        self.weaponmodel = "progs/v_shot.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_SHELLS
    elseif self.weapon == IT_SUPER_SHOTGUN then
        self.currentammo = self.ammo_shells
        self.weaponmodel = "progs/v_shot2.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_SHELLS
    elseif self.weapon == IT_NAILGUN then
        self.currentammo = self.ammo_nails
        self.weaponmodel = "progs/v_nail.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_NAILS
    elseif self.weapon == IT_SUPER_NAILGUN then
        self.currentammo = self.ammo_nails
        self.weaponmodel = "progs/v_nail2.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_NAILS
    elseif self.weapon == IT_GRENADE_LAUNCHER then
        self.currentammo = self.ammo_rockets
        self.weaponmodel = "progs/v_rock.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_ROCKETS
    elseif self.weapon == IT_ROCKET_LAUNCHER then
        self.currentammo = self.ammo_rockets
        self.weaponmodel = "progs/v_rock2.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_ROCKETS
    elseif self.weapon == IT_LIGHTNING then
        self.currentammo = self.ammo_cells
        self.weaponmodel = "progs/v_light.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_CELLS
    else
        self.currentammo = 0
        self.weaponmodel = ""
        self.weaponframe = 0
    end
end

function W_BestWeapon()
    local it

    it = self.items

    if self.waterlevel <= 1 and self.ammo_cells >= 1 and (it & IT_LIGHTNING) > 0 then
        return IT_LIGHTNING
    elseif self.ammo_nails >= 2 and (it & IT_SUPER_NAILGUN) > 0 then
        return IT_SUPER_NAILGUN
    elseif self.ammo_shells >= 2 and (it & IT_SUPER_SHOTGUN) > 0 then
        return IT_SUPER_SHOTGUN
    elseif self.ammo_nails >= 1 and (it & IT_NAILGUN) > 0 then
        return IT_NAILGUN
    elseif self.ammo_shells >= 1 and (it & IT_SHOTGUN) > 0 then
        return IT_SHOTGUN
    end

    return IT_AXE
end

function W_CheckNoAmmo()
    if self.currentammo > 0 then
        return true
    end

    if self.weapon == IT_AXE then
        return true
    end

    self.weapon = W_BestWeapon ()

    W_SetCurrentAmmo ()

    -- drop the weapon down
    return false
end

--[[
============
W_Attack

An attack impulse can be triggered now
============
*/
]]--

function W_Attack()
    local r

    if not W_CheckNoAmmo () then
        return
    end

    makevectors(self.v_angle) -- calculate forward angle for velocity
    self.show_hostile = time + 1 -- wake monsters up

    if self.weapon == IT_AXE then
        self.attack_finished = time + 0.5
        sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM)
        r = random()
        if r < 0.25 then
            player_axe1 ()
        elseif r < 0.5 then
            player_axeb1 ()
        elseif r < 0.75 then
            player_axec1 ()
        else
            player_axed1 ()
        end
    elseif self.weapon == IT_SHOTGUN then
        player_shot1 ()
        self.attack_finished = time + 0.5
        W_FireShotgun ()
    elseif self.weapon == IT_SUPER_SHOTGUN then
        player_shot1 ()
        self.attack_finished = time + 0.7
        W_FireSuperShotgun ()
    elseif self.weapon == IT_NAILGUN then
        player_nail1 ()
    elseif self.weapon == IT_SUPER_NAILGUN then
        player_nail1 ()
    elseif self.weapon == IT_GRENADE_LAUNCHER then
        player_rocket1()
        self.attack_finished = time + 0.6
        W_FireGrenade()
    elseif self.weapon == IT_ROCKET_LAUNCHER then
        player_rocket1()
        self.attack_finished = time + 0.8
        W_FireRocket()
    elseif self.weapon == IT_LIGHTNING then
        self.attack_finished = time + 0.1
        sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM)
        player_light1()
    end
end

--[[
============
W_ChangeWeapon

============
]]--
function W_ChangeWeapon()
    local it, am, fl

    it = self.items
    am = 0

    if self.impulse == 1 then
        fl = IT_AXE
    elseif self.impulse == 2 then
        fl = IT_SHOTGUN
        if self.ammo_shells < 1 then
            am = 1
        end
    elseif self.impulse == 3 then
        fl = IT_SUPER_SHOTGUN
        if self.ammo_shells < 2 then
            am = 1
        end
    elseif self.impulse == 4 then
        fl = IT_NAILGUN
        if self.ammo_nails < 1 then
            am = 1
        end
    elseif self.impulse == 5 then
        fl = IT_SUPER_NAILGUN
        if self.ammo_nails < 2 then
            am = 1
        end
    elseif self.impulse == 6 then
        fl = IT_GRENADE_LAUNCHER
        if self.ammo_rockets < 1 then
            am = 1
        end
    elseif self.impulse == 7 then
        fl = IT_ROCKET_LAUNCHER
        if self.ammo_rockets < 1 then
            am = 1
        end
    elseif self.impulse == 8 then
        fl = IT_LIGHTNING
        if self.ammo_cells < 1 then
            am = 1
        end
    end

    self.impulse = 0

    if (self.items & fl) == 0 then
        -- don't have the weapon or the ammo
        sprint (self, PRINT_HIGH, "no weapon.\n")
        return
    end

    if am == 1 then
        -- don't have the ammo
        sprint (self, PRINT_HIGH, "not enough ammo.\n")
        return
    end

    --
    -- set weapon, set ammo
    --
    self.weapon = fl
    W_SetCurrentAmmo ()
end

--[[
============
CheatCommand
============
]]--
function CheatCommand()
    if true then -- if (deathmatch || coop)
        -- this is disabled in the qw code with above if
        return
    end

    self.ammo_rockets = 100
    self.ammo_nails = 200
    self.ammo_shells = 100
    self.items = self.items |
        IT_AXE |
        IT_SHOTGUN |
        IT_SUPER_SHOTGUN |
        IT_NAILGUN |
        IT_SUPER_NAILGUN |
        IT_GRENADE_LAUNCHER |
        IT_ROCKET_LAUNCHER |
        IT_KEY1 | IT_KEY2

    self.ammo_cells = 200
    self.items = self.items | IT_LIGHTNING

    self.weapon = IT_ROCKET_LAUNCHER
    self.impulse = 0
    W_SetCurrentAmmo ()
end

--[[
============
CycleWeaponCommand

Go to the next weapon with ammo
============
]]--
function CycleWeaponCommand()
    local it, am

    it = self.items
    self.impulse = 0

    while true do
        am = 0

        if self.weapon == IT_LIGHTNING then
            self.weapon = IT_AXE
        elseif self.weapon == IT_AXE then
            self.weapon = IT_SHOTGUN
            if self.ammo_shells < 1 then
                am = 1
            end
        elseif self.weapon == IT_SHOTGUN then
            self.weapon = IT_SUPER_SHOTGUN
            if self.ammo_shells < 2 then
                am = 1
            end
        elseif self.weapon == IT_SUPER_SHOTGUN then
            self.weapon = IT_NAILGUN
            if self.ammo_nails < 1 then
                am = 1
            end
        elseif self.weapon == IT_NAILGUN then
            self.weapon = IT_SUPER_NAILGUN
            if self.ammo_nails < 2 then
                am = 1
            end
        elseif self.weapon == IT_SUPER_NAILGUN then
            self.weapon = IT_GRENADE_LAUNCHER
            if self.ammo_rockets < 1 then
                am = 1
            end
        elseif self.weapon == IT_GRENADE_LAUNCHER then
            self.weapon = IT_ROCKET_LAUNCHER
            if self.ammo_rockets < 1 then
                am = 1
            end
        elseif self.weapon == IT_ROCKET_LAUNCHER then
            self.weapon = IT_LIGHTNING
            if self.ammo_cells < 1 then
                am = 1
            end
        end

        if (self.items & self.weapon) > 0 and am == 0 then
            W_SetCurrentAmmo ()
            return
        end
    end
end

--[[
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
]]--
function CycleWeaponReverseCommand()
    local it, am

    it = self.items
    self.impulse = 0

    while true do
        am = 0

        if self.weapon == IT_LIGHTNING then
            self.weapon = IT_ROCKET_LAUNCHER
            if self.ammo_rockets < 1 then
                am = 1
            end
        elseif self.weapon == IT_ROCKET_LAUNCHER then
            self.weapon = IT_GRENADE_LAUNCHER
            if self.ammo_rockets < 1 then
                am = 1
            end
        elseif self.weapon == IT_GRENADE_LAUNCHER then
            self.weapon = IT_SUPER_NAILGUN
            if self.ammo_nails < 2 then
                am = 1
            end
        elseif self.weapon == IT_SUPER_NAILGUN then
            self.weapon = IT_NAILGUN
            if self.ammo_nails < 1 then
                am = 1
            end
        elseif self.weapon == IT_NAILGUN then
            self.weapon = IT_SUPER_SHOTGUN
            if self.ammo_shells < 2 then
                am = 1
            end
        elseif self.weapon == IT_SUPER_SHOTGUN then
            self.weapon = IT_SHOTGUN
            if self.ammo_shells < 1 then
                am = 1
            end
        elseif self.weapon == IT_SHOTGUN then
            self.weapon = IT_AXE
        elseif self.weapon == IT_AXE then
            self.weapon = IT_LIGHTNING
            if self.ammo_cells < 1 then
                am = 1
            end
        end

        if (it & self.weapon) > 0 and am == 0 then
            W_SetCurrentAmmo ()
            return
        end
    end
end

--[[
============
ServerflagsCommand

Just for development
============
]]--
function ServerflagsCommand()
    serverflags = serverflags * 2 + 1
end


--[[
============
ImpulseCommands

============
]]--
function ImpulseCommands()
    if self.impulse >= 1 and self.impulse <= 8 then
        W_ChangeWeapon ()
    end

    if self.impulse == 9 then
        CheatCommand ()
    end
    if self.impulse == 10 then
        CycleWeaponCommand ()
    end
    if self.impulse == 11 then
        ServerflagsCommand ()
    end
    if self.impulse == 12 then
        CycleWeaponReverseCommand ()
    end

    self.impulse = 0
end

--[[
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
]]--
function W_WeaponFrame()
    if time < self.attack_finished then
        return
    end

    ImpulseCommands ()

    -- check for attack
    if self.button0 > 0 then
        SuperDamageSound ()
        W_Attack ()
    end
end

--[[
========
SuperDamageSound

Plays sound if needed
========
--]]
function SuperDamageSound()
    if self.super_damage_finished > time then
        if self.super_sound < time then
            self.super_sound = time + 1
            sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM)
        end
    end
end
