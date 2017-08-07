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

### ftos(float)
Removed, use `tostring(float)` instead.

### stof(float)
Removed, use `tonumber(string)` instead.

### vlen(vector)
Removed, use `#vector` instead.

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
