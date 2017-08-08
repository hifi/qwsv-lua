Quake Lua API
=============
This document will expand when changes are introduced.

Differences to QuakeC
---------------------
### Booleans
Old `TRUE` and `FALSE` defines are gone. Real Lua booleans are used where appropriate.

**Warning**: Lua evaluates numeric `0` as true. All assumptions of `0` being false need to be corrected by using numeric comparison.

### Vectors

Original QuakeC code defined vectors as `'x y z'`, in Lua a new vector type was introduced which is initialized by `vec3(x, y, z)` function.

### Game only edict fields
All edict fields that are not shared with C which were in `defs.qc` are gone. They are created on-demand by the game code.

**Warning**: Lua does not allow doing arithmetic or string operations on `nil` so all access to custom fields need to be checked.

### aim(edict, speed)
Removed, use `v_forward` from `makevectors(vector)` instead. See below.

### makevectors(vector)
Returns the three vectors rather than sets them to globals.

Usage: `local v_forward, v_right, v_up = makevectors(...)`

### fabs(float)
Removed, use `math.abs(float)` instead.

### ftos(float)
Removed, use `tostring(float)` instead.

### stof(float)
Removed, use `tonumber(string)` instead.

### vlen(vector)
Removed, use `#vector` instead.

### nextent(entity)
Removed, use `entities()` iterator instead.

### traceline(vector, vector, type, edict)
Third argument was changed from boolean `nomonsters` to integer `type`. `TRUE`in QuakeC was defined as `1` which equals to `MOVE_NOMONSTERS`. `MOVE_*` enums were introduced to replace that.

Instead of setting `trace_` globals, we now return a Lua table that has the following structure (matches C struct):
```
{
    allsolid = boolean,
    startsolid = boolean,
    inopen = boolean,
    inwater = boolean,
    fraction = number,
    endpos = vector,
    ent = edict,
    plane = {
        normal = vector,
        dist = number
    }
}
```

### findradius(vector, float)
Returns a real Lua iterator instead of a chain of edicts.

Usage: `for ent in findradius(self.origin, 50) do ... end`

### find(starte, field, value)
Deprecated, use generic `entities()` iterator with a filter instead.

This has been reimplemented in pure Lua in `defs.lua` until removed completely.

New built-ins
-------------
These replace or complement existing built-ins where needed.

### vec3(x,y,x)

Initializes a three point vector.

### entities(filter)

Returns an iterator that can be used to go through all entities/edicts.

Optionally takes a function that is used to filter results, it must return a boolean.
