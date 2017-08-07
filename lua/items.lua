--[[
    items.qc

    item functions

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

--[[ ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD BE .8 .3 .4 IN COLOR --]]

function SUB_regen()
    self.model = self.mdl -- restore original model
    self.solid = SOLID_TRIGGER -- allow it to be touched again
    sound(self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM) -- play respawn sound
    setorigin (self, self.origin)
end

--[[ QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
]]--

function noclass()
    dprint("noclass spawned at")
    dprint(vtos(self.origin))
    dprint("\n")
    remove (self)
end

function q_touch()
    local stemp
    local best
    local s

    if other.classname ~= "player" then
        return
    elseif other.health <= 0 then
        return
    end

    self.mdl = self.model

    sound(other, CHAN_VOICE, self.noise, 1, ATTN_NORM)
    stuffcmd(other, "bf\n")
    self.solid = SOLID_NOT
    other.items = other.items | IT_QUAD
    self.model = ""
    if deathmatch == 4 then
        other.armortype = 0
        other.armorvalue = 0 * 0.01
        other.ammo_cells = 0
    end

    -- do the apropriate action
    other.super_time = 1
    other.super_damage_finished = self.cnt

    s = tostring(rint(other.super_damage_finished - time))

    bprint(PRINT_LOW, other.netname)
    if deathmatch == 4 then
        bprint(PRINT_LOW, " recovered an OctaPower with ")
    else
        bprint(PRINT_LOW, " recovered a Quad with ")
    end
    bprint(PRINT_LOW, s)
    bprint(PRINT_LOW, " seconds remaining!\n")

    activator = other
    SUB_UseTargets() -- fire all targets / killtargets
end

function DropQuad(timeleft)
    local item

    item = spawn()
    item.origin = self.origin

    item.velocity.z = 300
    item.velocity.x = -100 + (random() * 200)
    item.velocity.y = -100 + (random() * 200)

    item.flags = FL_ITEM
    item.solid = SOLID_TRIGGER
    item.movetype = MOVETYPE_TOSS
    item.noise = "items/damage.wav"
    setmodel(item, "progs/quaddama.mdl")
    setsize(item, vec3(-16,-16,-24), vec3(16,16,32))
    item.cnt = time + timeleft
    item.touch = q_touch
    item.nextthink = time + timeleft -- remove it with the time left on it
    item.think = SUB_Remove
end

function r_touch()
    local stemp
    local best
    local s

    if other.classname ~= "player" then
        return
    elseif other.health <= 0 then
        return
    end

    self.mdl = self.model

    sound(other, CHAN_VOICE, self.noise, 1, ATTN_NORM)
    stuffcmd(other, "bf\n")
    self.solid = SOLID_NOT
    other.items = other.items | IT_INVISIBILITY
    self.model = ""

    -- do the apropriate action
    other.invisible_time = 1
    other.invisible_finished = self.cnt
    s = tostring(rint(other.invisible_finished - time))
    bprint(PRINT_LOW, other.netname)
    bprint(PRINT_LOW, " recovered a Ring with ")
    bprint(PRINT_LOW, s)
    bprint(PRINT_LOW, " seconds remaining!\n")

    activator = other
    SUB_UseTargets() -- fire all targets / killtargets
end

function DropRing()
    local item

    item = spawn()
    item.origin = self.origin

    item.velocity.z = 300
    item.velocity.x = -100 + (random() * 200)
    item.velocity.y = -100 + (random() * 200)

    item.flags = FL_ITEM
    item.solid = SOLID_TRIGGER
    item.movetype = MOVETYPE_TOSS
    item.noise = "items/inv1.wav"
    setmodel(item, "progs/invisibl.mdl")
    setsize(item, vec3(-16,-16,-24), vec3(16,16,32))
    item.cnt = time + timeleft
    item.touch = r_touch
    item.nextthink = time + timeleft -- remove after 30 seconds
    item.think = SUB_Remove
end

--[[
============
PlaceItem

plants the object on the floor
============
]]--
function PlaceItem()
    local oldz

    self.mdl = self.model -- so it can be restored on respawn
    self.flags = FL_ITEM -- make extra wide
    self.solid = SOLID_TRIGGER
    self.movetype = MOVETYPE_TOSS
    self.velocity = vec3(0,0,0)
    self.origin.z = self.origin.z + 6
    oldz = self.origin.z
    if not droptofloor() then
        dprint("Bonus item fell out of level at ")
        dprint(vtos(self.origin))
        dprint("\n")
        remove(self)
    end
end

--[[
============
StartItem

Sets the clipping size and plants the object on the floor
============
]]--
function StartItem()
    self.nextthink = time + 0.2 -- items start after other solids
    self.think = PlaceItem
end

--[[
=========================================================================

HEALTH BOX

=========================================================================
]]--
--
-- T_Heal: add health to an entity, limiting health to max_health
-- "ignore" will ignore max_health limit
--
function T_Heal(e, healamount, ignore)
    if e.health <= 0 then
        return false
    end
    if not ignore and e.health >= other.max_health then
        return false
    end
    healamount = math.ceil(healamount)

    e.health = e.health + healamount
    if not ignore and e.health >= other.max_health then
        e.health = other.max_health
    end

    if e.health > 250 then
        e.health = 250
    end
    return true
end

--[[
QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
]]--

local H_ROTTEN = 1
local H_MEGA = 2
local healamount, healtype

function item_health()
    self.touch = health_touch

    if (self.spawnflags & H_ROTTEN) > 0 then
        precache_model("maps/b_bh10.bsp")
        precache_sound("items/r_item1.wav")
        setmodel(self, "maps/b_bh10.bsp")
        self.noise = "items/r_item1.wav"
        self.healamount = 15
        self.healtype = 0
    elseif (self.spawnflags & H_MEGA) > 0 then
        precache_model("maps/b_bh100.bsp")
        precache_sound("items/r_item2.wav")
        setmodel(self, "maps/b_bh100.bsp")
        self.noise = "items/r_item2.wav"
        self.healamount = 100
        self.healtype = 2
    else
        precache_model("maps/b_bh25.bsp")
        precache_sound("items/health1.wav")
        setmodel(self, "maps/b_bh25.bsp")
        self.noise = "items/health1.wav"
        self.healamount = 25
        self.healtype = 1
    end
    setsize(self, vec3(0,0,0), vec3(32,32,56))
    StartItem()
end

function health_touch()
    local amount
    local s

    if deathmatch == 4 then
        if other.invincible_time and other.invincible_time > 0 then
            return
        end
    end

    if other.classname ~= "player" then
        return
    end

    if self.healtype == 2 then -- Megahealth? Ignore max_health...
        if other.health >= 250 then
            return
        end
        if not T_Heal(other, self.healamount, true) then
            return
        end
    else
        if not T_Heal(other, self.healamount, false) then
            return
        end
    end

    sprint(other, PRINT_LOW, "You receive ")
    s = tostring(self.healamount)
    sprint(other, PRINT_LOW, s)
    sprint(other, PRINT_LOW, " health\n")

    -- health touch sound
    sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM)

    stuffcmd(other, "bf\n")

    self.model = ""
    self.solid = SOLID_NOT

    -- Megahealth = rot down the player's super health
    if self.healtype == 2 then
        other.items = other.items | IT_SUPERHEALTH
        if deathmatch ~= 4 then
            self.nextthink = time + 5
            self.think = item_megahealth_rot
        end
        self.owner = other
    else
        if deathmatch ~= 2 then -- deathmatch 2 is the silly old rules
            self.nextthink = time + 20
            self.think = SUB_regen
        end
    end

    activator = other
    SUB_UseTargets() -- fire all targets / killtargets
end

function item_megahealth_rot()
    other = self.owner

    if other.health > other.max_health then
        other.health = other.health - 1
        self.nextthink = time + 1
        return
    end

    -- it is possible for a player to die and respawn between rots, so don't
    -- just blindly subtract the flag off
    other.items = other.items - (other.items & IT_SUPERHEALTH)

    if deathmatch ~= 2 then -- deathmatch 2 is silly old rules
        self.nextthink = time + 20
        self.think = SUB_regen
    end
end

--[[
===============================================================================

ARMOR

===============================================================================
]]--

function armor_touch()
    local type, value, bit

    if other.health <= 0 then
        return
    end
    if other.classname ~= "player" then
        return
    end
    if deathmatch == 4 and other.invincible_time > 0 then
        return
    end

    if self.classname == "item_armor1" then
        type = 0.3
        value = 100
        bit = IT_ARMOR1
    elseif self.classname == "item_armor2" then
        type = 0.6
        value = 150
        bit = IT_ARMOR2
    elseif self.classname == "item_armorInv" then
        type = 0.8
        value = 200
        bit = IT_ARMOR3
    end
    if (other.armortype * other.armorvalue) >= (type * value) then
        return
    end

    other.armortype = type
    other.armorvalue = value
    other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit

    self.solid = SOLID_NOT
    self.model = ""
    if deathmatch ~= 2 then
        self.nextthink = time + 20
    end
    self.think = SUB_regen

    sprint(other, PRINT_LOW, "You got armor\n")
    -- armor touch sound
    sound(other, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM)
    stuffcmd(other, "bf\n")

    activator = other
    SUB_UseTargets() -- fire all targets / killtargets
end

--[[ QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32) ]]--

function item_armor1()
    self.touch = armor_touch
    precache_model("progs/armor.mdl")
    setmodel(self, "progs/armor.mdl")
    self.skin = 0
    setsize(self, vec3(-16,-16,0), vec3(16,16,56))
    StartItem()
end

--[[ QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32) ]]--

function item_armor2()
    self.touch = armor_touch
    precache_model("progs/armor.mdl")
    setmodel(self, "progs/armor.mdl")
    self.skin = 1
    setsize(self, vec3(-16,-16,0), vec3(16,16,56))
    StartItem()
end

--[[ QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32) ]]--

function item_armorInv()
    self.touch = armor_touch
    precache_model("progs/armor.mdl")
    setmodel(self, "progs/armor.mdl")
    self.skin = 2
    setsize(self, vec3(-16,-16,0), vec3(16,16,56))
    StartItem()
end

--[[
===============================================================================

WEAPONS

===============================================================================
]]--

function bound_other_ammo()
    if other.ammo_shells > 100 then
        other.ammo_shells = 100
    end
    if other.ammo_nails > 200 then
        other.ammo_nails = 200
    end
    if other.ammo_rockets > 100 then
        other.ammo_rockets = 100
    end
    if other.ammo_cells > 100 then
        other.ammo_cells = 100
    end
end

function RankForWeapon(w)
    if w == IT_LIGHTNING then
        return 1
    elseif w == IT_ROCKET_LAUNCHER then
        return 2
    elseif w == IT_SUPER_NAILGUN then
        return 3
    elseif w == IT_GRENADE_LAUNCHER then
        return 4
    elseif w == IT_SUPER_SHOTGUN then
        return 5
    elseif w == IT_NAILGUN then
        return 6
    else
        return 7
    end
end

function WeaponCode(w)
    if w == IT_SUPER_SHOTGUN then
        return 3
    elseif w == IT_NAILGUN then
        return 4
    elseif w == IT_SUPER_NAILGUN then
        return 5
    elseif w == IT_GRENADE_LAUNCHER then
        return 6
    elseif w == IT_ROCKET_LAUNCHER then
        return 7
    elseif w == IT_LIGHTNING then
        return 8
    else
        return 1
    end
end

--[[
=============
Deathmatch_Weapon

Deathmatch weapon change rules for picking up a weapon

.float ammo_shells, ammo_nails, ammo_rockets, ammo_cells
=============
]]--
function Deathmatch_Weapon(old, new)
    local oldrank, newrank

    -- change self.weapon if desired
    oldrank = RankForWeapon(self.weapon)
    newrank = RankForWeapon(new)
    if newrank < oldrank then
        self.weapon = new
    end
end

--[[
=============
weapon_touch
=============
]]--

function weapon_touch()
    local hadammo, best, new, old
    local stemp
    local leave

    -- For client weapon_switch
    local w_switch

    if (other.flags & FL_CLIENT) == 0 then
        return
    end

    if (tonumber(infokey(other,"w_switch")) or 0) == 0 then
        w_switch = 8
    else
        w_switch = tonumber(infokey(other,"w_switch")) or 0
    end
    -- if the player was using his best weapon, change up to the new one if better
    stemp = self
    self = other
    best = W_BestWeapon()
    self = stemp

    if deathmatch == 2 or deathmatch == 3 or deathmatch == 5 then
        leave = 1
    else
        leave = 0
    end

    if self.classname == "weapon_nailgun" then
        if leave == 1 and (other.items & IT_NAILGUN) > 0 then
            return
        end
        hadammo = other.ammo_nails
        new = IT_NAILGUN
        other.ammo_nails = other.ammo_nails + 30
    elseif self.classname == "weapon_supernailgun" then
        if leave == 1 and (other.items & IT_SUPER_NAILGUN) > 0 then
            return
        end
        hadammo = other.ammo_rockets
        new = IT_SUPER_NAILGUN
        other.ammo_nails = other.ammo_nails + 30
    elseif self.classname == "weapon_supershotgun" then
        if leave == 1 and (other.items & IT_SUPER_SHOTGUN) > 0 then
            return
        end
        hadammo = other.ammo_rockets
        new = IT_SUPER_SHOTGUN
        other.ammo_shells = other.ammo_shells + 5
    elseif self.classname == "weapon_rocketlauncher" then
        if leave == 1 and (other.items & IT_ROCKET_LAUNCHER) > 0 then
            return
        end
        hadammo = other.ammo_rockets
        new = IT_ROCKET_LAUNCHER
        other.ammo_rockets = other.ammo_rockets + 5
    elseif self.classname == "weapon_grenadelauncher" then
        if leave == 1 and (other.items & IT_GRENADE_LAUNCHER) > 0 then
            return
        end
        hadammo = other.ammo_rockets
        new = IT_GRENADE_LAUNCHER
        other.ammo_rockets = other.ammo_rockets + 5
    elseif self.classname == "weapon_lightning" then
        if leave == 1 and (other.items & IT_LIGHTNING) > 0 then
            return
        end
        hadammo = other.ammo_rockets
        new = IT_LIGHTNING
        other.ammo_cells = other.ammo_cells + 15
    else
        objerror("weapon_touch: unknown classname")
    end

    sprint(other, PRINT_LOW, "You got the ")
    sprint(other, PRINT_LOW, self.netname)
    sprint(other, PRINT_LOW, "\n")
    -- weapon touch sound
    sound(other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM)
    stuffcmd(other, "bf\n")

    bound_other_ammo()

    -- change to the weapon
    old = other.items
    other.items = other.items | new

    stemp = self
    self = other

    if WeaponCode(new) <= w_switch then
        if (self.flags & FL_INWATER) > 0 then
            if new ~= IT_LIGHTNING then
                Deathmatch_Weapon(old, new)
            end
        else
            Deathmatch_Weapon(old, new)
        end
    end

    W_SetCurrentAmmo()

    self = stemp

    if leave == 1 then
        return
    end

    -- TODO: Determine whether this logic is correct; always true?!
    if deathmatch ~= 3 or deathmatch ~=5 then
        -- remove it in single player, or setup for respawning in deathmatch
        self.model = ""
        self.solid = SOLID_NOT
        if deathmatch ~= 2 then
            self.nextthink = time + 30
        end
        self.think = SUB_regen
    end
    activator = other
    SUB_UseTargets() -- fire all targets / killtargets
end

--[[ QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32) ]]--

function weapon_supershotgun()
    if deathmatch <= 3 then
        precache_model("progs/g_shot.mdl")
        setmodel(self, "progs/g_shot.mdl")
        self.weapon = IT_SUPER_SHOTGUN
        self.netname = "Double-barrelled Shotgun"
        self.touch = weapon_touch
        setsize(self, vec3(-16,-16,0), vec3(16,16,56))
        StartItem()
    end
end

--[[ QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32) ]]--

function weapon_nailgun()
    if deathmatch <= 3 then
        precache_model("progs/g_nail.mdl")
        setmodel(self, "progs/g_nail.mdl")
        self.weapon = IT_NAILGUN
        self.netname = "nailgun"
        self.touch = weapon_touch
        setsize(self, vec3(-16,-16,0), vec3(16,16,56))
        StartItem()
    end
end

--[[ QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32) ]]--

function weapon_supernailgun()
    if deathmatch <= 3 then
        precache_model("progs/g_nail2.mdl")
        setmodel(self, "progs/g_nail2.mdl")
        self.weapon = IT_SUPER_NAILGUN
        self.netname = "Super Nailgun"
        self.touch = weapon_touch
        setsize(self, vec3(-16,-16,0), vec3(16,16,56))
        StartItem()
    end
end

--[[ QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32) ]]--

function weapon_grenadelauncher()
    if deathmatch <= 3 then
        precache_model("progs/g_rock.mdl")
        setmodel(self, "progs/g_rock.mdl")
        self.weapon = 3
        self.netname = "Grenade Launcher"
        self.touch = weapon_touch
        setsize(self, vec3(-16,-16,0), vec3(16,16,56))
        StartItem()
    end
end

--[[ QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32) ]]--

function weapon_rocketlauncher()
    if deathmatch <= 3 then
        precache_model("progs/g_rock2.mdl")
        setmodel(self, "progs/g_rock2.mdl")
        self.weapon = 3
        self.netname = "Rocket Launcher"
        self.touch = weapon_touch
        setsize(self, vec3(-16,-16,0), vec3(16,16,56))
        StartItem()
    end
end


--[[ QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32) ]]--

function weapon_lightning()
    if deathmatch <= 3 then
        precache_model("progs/g_light.mdl")
        setmodel(self, "progs/g_light.mdl")
        self.weapon = 3
        self.netname = "Thunderbolt"
        self.touch = weapon_touch
        setsize(self, vec3(-16,-16,0), vec3(16,16,56))
        StartItem()
    end
end

--[[
===============================================================================

AMMO

===============================================================================
]]--

function ammo_touch()
    local stemp
    local best

    if other.classname ~= "player" then
        return
    end
    if other.health <= 0 then
        return
    end

    -- if the player was using his best weapon, change up to the new one if better
    stemp = self
    self = other
    best = W_BestWeapon()
    self = stemp

    -- shotgun
    if self.weapon == 1 then
        if other.ammo_shells >= 100 then
            return
        end
        other.ammo_shells = other.ammo_shells + self.aflag
    end

    -- spikes
    if self.weapon == 2 then
        if other.ammo_nails >= 200 then
            return
        end
        other.ammo_nails = other.ammo_nails + self.aflag
    end

    -- rockets
    if self.weapon == 3 then
        if other.ammo_rockets >= 100 then
            return
        end
        other.ammo_rockets = other.ammo_rockets + self.aflag
    end

    -- cells
    if self.weapon == 4 then
        if other.ammo_cells >= 100 then
            return
        end
        other.ammo_cells = other.ammo_cells + self.aflag
    end

    bound_other_ammo()

    sprint(other, PRINT_LOW, "You got the ")
    sprint(other, PRINT_LOW, self.netname)
    sprint(other, PRINT_LOW, "\n")
    -- ammo touch sound
    sound(other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM)
    stuffcmd(other, "bf\n")

    -- change to a better weapon if appropriate
    if other.weapon == best then
        stemp = self
        self = other
        self.weapon = W_BestWeapon()
        W_SetCurrentAmmo()
        self = stemp
    end

    -- if changed current ammo, update it
    stemp = self
    self = other
    W_SetCurrentAmmo()
    self = stemp

    -- remove it in single player, or setup for respawning in deathmatch
    self.model = ""
    self.solid = SOLID_NOT
    if deathmatch ~= 2 then
        self.nextthink = time + 30
    end

    -- Xian -- If playing in DM 3.0 mode, halve the time ammo respawns
    if deathmatch == 3 or deathmatch == 5 then
        self.nextthink = time + 15
    end

    self.think = SUB_regen

    activator = other
    SUB_UseTargets() -- fire all targets / killtargets
end


local WEAPON_BIG2 = 1

--[[ QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big ]]--

function item_shells()
    if deathmatch == 4 then
        return
    end

    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_BIG2) > 0 then
        precache_model("maps/b_shell1.bsp")
        setmodel(self, "maps/b_shell1.bsp")
        self.aflag = 40
    else
        precache_model("maps/b_shell0.bsp")
        setmodel(self, "maps/b_shell0.bsp")
        self.aflag = 20
    end
    self.weapon = 1
    self.netname = "shells"
    setsize(self, vec3(0,0,0), vec3(32,32,56))
    StartItem()
end

--[[ QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big ]]--

function item_spikes()
    if deathmatch == 4 then
        return
    end

    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_BIG2) > 0 then
        precache_model("maps/b_nail1.bsp")
        setmodel(self, "maps/b_nail1.bsp")
        self.aflag = 50
    else
        precache_model("maps/b_nail0.bsp")
        setmodel(self, "maps/b_nail0.bsp")
        self.aflag = 25
    end
    self.weapon = 2
    self.netname = "nails"
    setsize(self, vec3(0,0,0), vec3(32,32,56))
    StartItem()
end

--[[ QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big ]]--

function item_rockets()
    if deathmatch == 4 then
        return
    end

    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_BIG2) > 0 then
        precache_model("maps/b_rock1.bsp")
        setmodel(self, "maps/b_rock1.bsp")
        self.aflag = 10
    else
        precache_model("maps/b_rock0.bsp")
        setmodel(self, "maps/b_rock0.bsp")
        self.aflag = 5
    end
    self.weapon = 3
    self.netname = "rockets"
    setsize(self, vec3(0,0,0), vec3(32,32,56))
    StartItem()
end

--[[ QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big ]]--

function item_cells()
    if deathmatch == 4 then
        return
    end

    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_BIG2) > 0 then
        precache_model("maps/b_batt1.bsp")
        setmodel(self, "maps/b_batt1.bsp")
        self.aflag = 12
    else
        precache_model("maps/b_batt0.bsp")
        setmodel(self, "maps/b_batt0.bsp")
        self.aflag = 6
    end
    self.weapon = 4
    self.netname = "cells"
    setsize(self, vec3(0,0,0), vec3(32,32,56))
    StartItem()
end

--[[
QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
]]

local WEAPON_SHOTGUN = 1
local WEAPON_ROCKET = 2
local WEAPON_SPIKES = 4
local WEAPON_BIG = 8

function item_weapon()
    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_SHOTGUN) > 0 then
        if (self.spawnflags & WEAPON_BIG) > 0 then
            precache_model ("maps/b_shell1.bsp")
            setmodel (self, "maps/b_shell1.bsp")
            self.aflag = 40
        else
            precache_model ("maps/b_shell0.bsp")
            setmodel (self, "maps/b_shell0.bsp")
            self.aflag = 20
        end
        self.weapon = 1
        self.netname = "shells"
    end

    if (self.spawnflags & WEAPON_SPIKES) > 0 then
        if (self.spawnflags & WEAPON_BIG) > 0 then
            precache_model ("maps/b_nail1.bsp")
            setmodel (self, "maps/b_nail1.bsp")
            self.aflag = 40
        else
            precache_model ("maps/b_nail0.bsp")
            setmodel (self, "maps/b_nail0.bsp")
            self.aflag = 20
        end
        self.weapon = 2
        self.netname = "spikes"
    end

    if (self.spawnflags & WEAPON_ROCKET) > 0 then
        if (self.spawnflags & WEAPON_BIG) > 0 then
            precache_model ("maps/b_rock1.bsp")
            setmodel (self, "maps/b_rock1.bsp")
            self.aflag = 10
        else
            precache_model ("maps/b_rock0.bsp")
            setmodel (self, "maps/b_rock0.bsp")
            self.aflag = 5
        end
        self.weapon = 3
        self.netname = "rockets"
    end

    setsize (self, vec3(0,0,0), vec3(32,32,56))
    StartItem ()
end

--[[
===============================================================================

KEYS

===============================================================================
]]--

function key_touch()
    local stemp
    local best

    if other.classname ~= "player" then
        return
    elseif other.health <= 0 then
        return
    elseif (other.items & self.items) > 0 then
        return
    end

    sprint(other, PRINT_LOW, "You got the ")
    sprint(other, PRINT_LOW, self.netname)
    sprint(other,PRINT_LOW, "\n")

    sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM)
    stuffcmd(other, "bf\n")
    other.items = other.items | self.items

    self.solid = SOLID_NOT
    self.model = ""

    activator = other
    SUB_UseTargets() -- fire all targets / killtargets
end

function key_setsounds()
    if world.worldtype == 0 then
        precache_sound("misc/medkey.wav")
        self.noise = "misc/medkey.wav"
    elseif world.worldtype == 1 then
        precache_sound("misc/runekey.wav")
        self.noise = "misc/runekey.wav"
    elseif world.worldtype == 2 then
        precache_sound2("misc/basekey.wav")
        self.noise = "misc/basekey.wav"
    end
end

--[[ QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
]]--

function item_key1()
    if world.worldtype == 0 then
        precache_model("progs/w_s_key.mdl")
        setmodel(self, "progs/w_s_key.mdl")
        self.netname = "silver key"
    elseif world.worldtype == 1 then
        precache_model("progs/m_s_key.mdl")
        setmodel(self, "progs/m_s_key.mdl")
        self.netname = "silver runekey"
    elseif world.worldtype == 2 then
        precache_model2("progs/b_s_key.mdl")
        setmodel(self, "progs/b_s_key.mdl")
        self.netname = "silver keycard"
    end
    key_setsounds()
    self.touch = key_touch
    self.items = IT_KEY1
    setsize(self, vec3(-16,-16,-24), vec3(16,16,32))
    StartItem()
end

--[[ QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
]]--

function item_key2()
    if world.worldtype == 0 then
        precache_model("progs/w_g_key.mdl")
        setmodel(self, "progs/w_g_key.mdl")
        self.netname = "gold key"
    elseif world.worldtype == 1 then
        precache_model("progs/m_g_key.mdl")
        setmodel(self, "progs/m_g_key.mdl")
        self.netname = "gold runekey"
    elseif world.worldtype == 2 then
        precache_model2 ("progs/b_g_key.mdl")
        setmodel(self, "progs/b_g_key.mdl")
        self.netname = "gold keycard"
    end
    key_setsounds()
    self.touch = key_touch
    self.items = IT_KEY2
    setsize(self, vec3(-16,-16,-24), vec3(16,16,32))
    StartItem()
end

--[[
===============================================================================

END OF LEVEL RUNES

===============================================================================
]]--

function sigil_touch()
    local stemp
    local best

    if other.classname ~= "player" then
        return
    elseif other.health <= 0 then
        return
    end

    centerprint(other, "You got the rune!")

    sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM)
    stuffcmd(other, "bf\n")
    self.solid = SOLID_NOT
    self.model = ""
    serverflags = serverflags | (self.spawnflags & 15)
    self.classname = "" -- so rune doors won't find it

    activator = other
    SUB_UseTargets() -- fire all targets / killtargets
end


--[[ QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
]]--

function item_sigil()
    if self.spawnflags == 0 then
        objerror ("no spawnflags")
    end

    precache_sound("misc/runekey.wav")
    self.noise = "misc/runekey.wav"

    if (self.spawnflags & 1) > 0 then
        precache_model("progs/end1.mdl")
        setmodel(self, "progs/end1.mdl")
    end
    if (self.spawnflags & 2) > 0 then
        precache_model2 ("progs/end2.mdl")
        setmodel(self, "progs/end2.mdl")
    end
    if (self.spawnflags & 4) > 0 then
        precache_model2 ("progs/end3.mdl")
        setmodel(self, "progs/end3.mdl")
    end
    if (self.spawnflags & 8) > 0 then
        precache_model2 ("progs/end4.mdl")
        setmodel(self, "progs/end4.mdl")
    end

    self.touch = sigil_touch
    setsize(self, vec3(-16,-16,-24), vec3(16,16,32))
    StartItem()
end

--[[
===============================================================================

POWERUPS

===============================================================================
--]]

function powerup_touch()
    local stemp
    local best

    if other.classname ~= "player" then
        return
    elseif other.health <= 0 then
        return
    end

    sprint(other, PRINT_LOW, "You got the ")
    sprint(other,PRINT_LOW, self.netname)
    sprint(other,PRINT_LOW, "\n")

    self.mdl = self.model

    if self.classname == "item_artifact_invulnerability" or self.classname == "item_artifact_invisibility" then
        self.nextthink = time + 60*5
    else
        self.nextthink = time + 60
    end

    self.think = SUB_regen

    sound(other, CHAN_VOICE, self.noise, 1, ATTN_NORM)
    stuffcmd(other, "bf\n")
    self.solid = SOLID_NOT
    other.items = other.items | self.items
    self.model = ""

    -- do the apropriate action
    if self.classname == "item_artifact_envirosuit" then
        other.rad_time = 1
        other.radsuit_finished = time + 30
    elseif self.classname == "item_artifact_invulnerability" then
        other.invincible_time = 1
        other.invincible_finished = time + 30
    elseif self.classname == "item_artifact_invisibility" then
        other.invisible_time = 1
        other.invisible_finished = time + 30
    elseif self.classname == "item_artifact_super_damage" then
        if deathmatch == 4 then
            other.armortype = 0
            other.armorvalue = 0 * 0.01
            other.ammo_cells = 0
        end
        other.super_time = 1
        other.super_damage_finished = time + 30
    end

    activator = other
    SUB_UseTargets() -- fire all targets / killtargets
end



--[[ QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
--]]

function item_artifact_invulnerability()
    self.touch = powerup_touch

    precache_model("progs/invulner.mdl")
    precache_sound("items/protect.wav")
    precache_sound("items/protect2.wav")
    precache_sound("items/protect3.wav")
    self.noise = "items/protect.wav"
    setmodel(self, "progs/invulner.mdl")
    self.netname = "Pentagram of Protection"
    self.effects = self.effects | EF_RED
    self.items = IT_INVULNERABILITY
    setsize(self, vec3(-16,-16,-24), vec3(16,16,32))
    StartItem()
end

--[[ QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime for 30 seconds
--]]

function item_artifact_envirosuit()
    self.touch = powerup_touch

    precache_model("progs/suit.mdl")
    precache_sound("items/suit.wav")
    precache_sound("items/suit2.wav")
    self.noise = "items/suit.wav"
    setmodel(self, "progs/suit.mdl")
    self.netname = "Biosuit"
    self.items = IT_SUIT
    setsize(self, vec3(-16,-16,-24), vec3(16,16,32))
    StartItem()
end

--[[ QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invisible for 30 seconds
--]]

function item_artifact_invisibility()
    self.touch = powerup_touch

    precache_model("progs/invisibl.mdl")
    precache_sound("items/inv1.wav")
    precache_sound("items/inv2.wav")
    precache_sound("items/inv3.wav")
    self.noise = "items/inv1.wav"
    setmodel(self, "progs/invisibl.mdl")
    self.netname = "Ring of Shadows"
    self.items = IT_INVISIBILITY
    setsize(self, vec3(-16,-16,-24), vec3(16,16,32))
    StartItem()
end

--[[ QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
The next attack from the player will do 4x damage
--]]

function item_artifact_super_damage()
    self.touch = powerup_touch

    precache_model("progs/quaddama.mdl")
    precache_sound("items/damage.wav")
    precache_sound("items/damage2.wav")
    precache_sound("items/damage3.wav")
    self.noise = "items/damage.wav"
    setmodel(self, "progs/quaddama.mdl")
    if deathmatch == 4 then
        self.netname = "OctaPower"
    else
        self.netname = "Quad Damage"
    end
    self.items = IT_QUAD
    self.effects = self.effects | EF_BLUE
    setsize(self, vec3(-16,-16,-24), vec3(16,16,32))
    StartItem()
end

--[[
===============================================================================

PLAYER BACKPACKS

===============================================================================
]]--

function BackpackTouch()
    local s
    local best, old, new
    local stemp
    local acount
    local b_switch

    if deathmatch == 4 and other.invincible_time and other.invincible_time > 0 then
        return
    end

    if (tonumber(infokey(other,"b_switch")) or 0) == 0 then
        b_switch = 8
    else
        b_switch = tonumber(infokey(other,"b_switch")) or 0
    end

    if other.classname ~= "player" then
        return
    elseif other.health <= 0 then
        return
    end

    acount = 0
    sprint(other, PRINT_LOW, "You get ")

    if deathmatch == 4 then
        other.health = other.health + 10
        sprint(other, PRINT_LOW, "10 additional health\n")
        if (other.health > 250) and (other.health < 300) then
            sound(other, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM)
        else
            sound(other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM)
        end
        stuffcmd(other, "bf\n")
        remove(self)

        if (other.health > 299) and (other.invincible_time ~= 1) then
            other.invincible_time = 1
            other.invincible_finished = time + 30
            other.items = other.items | IT_INVULNERABILITY
            other.super_time = 1
            other.super_damage_finished = time + 30
            other.items = other.items | IT_QUAD
            other.ammo_cells = 0

            sound(other, CHAN_VOICE, "boss1/sight1.wav", 1, ATTN_NORM)
            stuffcmd(other, "bf\n")
            bprint(PRINT_HIGH, other.netname)
            bprint(PRINT_HIGH, " attains bonus powers!!!\n")
        end
        self = other
        return
    end
    if (self.items ~= 0) and ((other.items & self.items) == 0) then
        acount = 1
        sprint(other, PRINT_LOW, "the ")
        sprint(other, PRINT_LOW, self.netname)
    end

    -- if the player was using his best weapon, change up to the new one if better
    stemp = self
    self = other
    best = W_BestWeapon()
    self = stemp

    -- change weapons
    other.ammo_shells = other.ammo_shells + self.ammo_shells
    other.ammo_nails = other.ammo_nails + self.ammo_nails
    other.ammo_rockets = other.ammo_rockets + self.ammo_rockets
    other.ammo_cells = other.ammo_cells + self.ammo_cells

    new = self.items
    if not new or new == 0 then
        new = other.weapon
    end
    old = other.items
    other.items = other.items | self.items

    bound_other_ammo()

    if self.ammo_shells > 0 then
        if acount > 0 then
            sprint(other, PRINT_LOW, ", ")
        end
        acount = 1
        s = tostring(self.ammo_shells)
        sprint(other, PRINT_LOW, s)
        sprint(other, PRINT_LOW, " shells")
    end
    if self.ammo_nails > 0 then
        if acount > 0 then
            sprint(other, PRINT_LOW, ", ")
        end
        acount = 1
        s = tostring(self.ammo_nails)
        sprint(other, PRINT_LOW, s)
        sprint(other, PRINT_LOW, " nails")
    end
    if self.ammo_rockets > 0 then
        if acount > 0 then
            sprint(other, PRINT_LOW, ", ")
        end
        acount = 1
        s = tostring(self.ammo_rockets)
        sprint(other, PRINT_LOW, s)
        sprint(other, PRINT_LOW, " rockets")
    end
    if self.ammo_cells > 0 then
        if acount > 0 then
            sprint(other, PRINT_LOW, ", ")
        end
        acount = 1
        s = tostring(self.ammo_cells)
        sprint(other, PRINT_LOW, s)
        sprint(other,PRINT_LOW, " cells")
    end

    if (deathmatch == 3 or deathmatch == 5) and (WeaponCode(new) == 6 or WeaponCode(new) == 7) and (other.ammo_rockets < 5) then
        other.ammo_rockets = 5
    end

    sprint(other, PRINT_LOW, "\n")
    -- backpack touch sound
    sound(other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM)
    stuffcmd(other, "bf\n")

    remove(self)
    self = other

    -- change to the weapon
    if WeaponCode(new) <= b_switch then
        if (self.flags & FL_INWATER) > 0 then
            if new ~= IT_LIGHTNING then
                Deathmatch_Weapon(old, new)
            end
        else
            Deathmatch_Weapon(old, new)
        end
    end

    W_SetCurrentAmmo()
end

--[[
===============
DropBackpack
===============
--]]

function DropBackpack()
    local item

    if (self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells) == 0 then
        return -- nothing in it
    end

    item = spawn()
    item.origin = self.origin - vec3(0,0,24)

    item.items = self.weapon
    if item.items == IT_AXE then
        item.netname = "Axe"
    elseif item.items == IT_SHOTGUN then
        item.netname = "Shotgun"
    elseif item.items == IT_SUPER_SHOTGUN then
        item.netname = "Double-barrelled Shotgun"
    elseif item.items == IT_NAILGUN then
        item.netname = "Nailgun"
    elseif item.items == IT_SUPER_NAILGUN then
        item.netname = "Super Nailgun"
    elseif item.items == IT_GRENADE_LAUNCHER then
        item.netname = "Grenade Launcher"
    elseif item.items == IT_ROCKET_LAUNCHER then
        item.netname = "Rocket Launcher"
    elseif item.items == IT_LIGHTNING then
        item.netname = "Thunderbolt"
    else
        item.netname = ""
    end

    item.ammo_shells = self.ammo_shells
    item.ammo_nails = self.ammo_nails
    item.ammo_rockets = self.ammo_rockets
    item.ammo_cells = self.ammo_cells

    item.velocity.z = 300
    item.velocity.x = -100 + (random() * 200)
    item.velocity.y = -100 + (random() * 200)

    item.flags = FL_ITEM
    item.solid = SOLID_TRIGGER
    item.movetype = MOVETYPE_TOSS
    setmodel(item, "progs/backpack.mdl")
    setsize(item, vec3(-16,-16,0), vec3(16,16,56))
    item.touch = BackpackTouch

    item.nextthink = time + 120 -- remove after 2 minutes
    item.think = SUB_Remove
end
