/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
// sv_edict.c -- entity dictionary

#include "qwsvdef.h"

lua_State *L;

// leftovers from pr_
int pr_argc;
int num_prstr;
dprograms_t *progs;
dfunction_t *pr_functions;
char *pr_strings;
globalvars_t *pr_global_struct;
int pr_edict_size;              // in bytes

int type_size[8] =
    { 1, sizeof(void *) / 4, 1, 3, 1, 1, sizeof(void *) / 4,
sizeof(void *) / 4 };

#define	MAX_FIELD_LEN	64

func_t SpectatorConnect;
func_t SpectatorThink;
func_t SpectatorDisconnect;

/*
=================
ED_ClearEdict

Sets everything to NULL
=================
*/
void ED_ClearEdict(edict_t * e)
{
    //Con_Printf("ED_ClearEdict(%p)\n", e);
    e->free = false;

    if (e->fields)
        luaL_unref(L, LUA_REGISTRYINDEX, e->fields);

    e->fields = 0;
}

/*
=================
ED_Alloc

Either finds a free edict, or allocates a new one.
Try to avoid reusing an entity that was recently freed, because it
can cause the client to think the entity morphed into something else
instead of being removed and recreated, which can cause interpolated
angles and bad trails.
=================
*/
edict_t *ED_Alloc(void)
{
    int i;
    edict_t *e;

    for (i = MAX_CLIENTS + 1; i < sv.num_edicts; i++) {
        e = EDICT_NUM(i);
        // the first couple seconds of server time can involve a lot of
        // freeing and allocating, so relax the replacement policy
        if (e->free && (e->freetime < 2 || sv.time - e->freetime > 0.5)) {
            ED_ClearEdict(e);
            return e;
        }
    }

    if (i == MAX_EDICTS) {
        Con_Printf("WARNING: ED_Alloc: no free edicts\n");
        i--;                    // step on whatever is the last edict
        e = EDICT_NUM(i);
        SV_UnlinkEdict(e);
    } else
        sv.num_edicts++;
    e = EDICT_NUM(i);
    ED_ClearEdict(e);

    return e;
}

/*
=================
ED_Free

Marks the edict as free
FIXME: walk all entities and NULL out references to this entity
=================
*/
void ED_Free(edict_t * ed)
{
    SV_UnlinkEdict(ed);         // unlink from world bsp

    ed->free = true;
    ed->v.model = 0;
    ed->v.takedamage = 0;
    ed->v.modelindex = 0;
    ed->v.colormap = 0;
    ed->v.skin = 0;
    ed->v.frame = 0;
    VectorCopy(vec3_origin, ed->v.origin);
    VectorCopy(vec3_origin, ed->v.angles);
    ed->v.nextthink = -1;
    ed->v.solid = 0;

    ed->freetime = sv.time;

    // XXX: do something to Lua fields
}

static void ED_EnsureFields(edict_t *ed)
{
    if (ed->ref == 0) {
        edict_t **ud = lua_newuserdata(L, sizeof(void*));
        *ud = ed;
        luaL_getmetatable(L, "edict_t");
        lua_setmetatable(L, -2);
        ed->ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }

    if (ed->fields == 0) {
        //Sys_Printf("ED_EnsureFields(%p)\n", ed);
        lua_newtable(L);

        // set some defaults so that math works
        lua_pushstring(L, "style");
        lua_pushnumber(L, 0);
        lua_rawset(L, -3);

        lua_pushstring(L, "speed");
        lua_pushnumber(L, 0);
        lua_rawset(L, -3);

        ed->fields = luaL_ref(L, LUA_REGISTRYINDEX);
    }
}

void ED_PushEdict(edict_t *ed)
{
    ED_EnsureFields(ed);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ed->ref);
}

//===========================================================================
/*
=============
ED_SetField

Tries to guess the value type and sets an edict field to that.

Note: Expects the Lua stack to have a table.
Note: This will not support savegames.
=============
*/
#define PARSE_VEC() \
    strcpy(string, value); \
    v = string; \
    w = string; \
    for (i = 0; i < 3; i++) { \
        while (*v && *v != ' ') \
            v++; \
        *v = 0; \
        vec[i] = atof(w); \
        w = v = v + 1; \
    }

#define FIELD_FLOAT(n) \
    if (strcmp(key, #n) == 0) { e->v.n = atof(value); return true; }

#define FIELD_STRING(n) \
    if (strcmp(key, #n) == 0) { lua_pushstring(L, value); e->v.n = luaL_ref(L, LUA_REGISTRYINDEX); return true; }

#define FIELD_VEC(n) \
    if (strcmp(key, #n) == 0) { \
        vec = e->v.n; \
        PARSE_VEC(); \
        return true; \
    }

#define FIELD_LSTRING(n) \
    if (strcmp(key, #n) == 0) { \
        lua_rawgeti(L, LUA_REGISTRYINDEX, e->fields); \
        lua_pushstring(L, key); \
        lua_pushstring(L, value); \
        lua_rawset(L, -3); \
        lua_pop(L, 1); \
        return true; \
    }

#define FIELD_LFLOAT(n) \
    if (strcmp(key, #n) == 0) { \
        lua_rawgeti(L, LUA_REGISTRYINDEX, e->fields); \
        lua_pushstring(L, key); \
        lua_pushnumber(L, atof(value)); \
        lua_rawset(L, -3); \
        lua_pop(L, 1); \
        return true; \
    }

#define FIELD_LVEC(n) \
    if (strcmp(key, #n) == 0) { \
        lua_rawgeti(L, LUA_REGISTRYINDEX, e->fields); \
        lua_pushstring(L, key); \
        vec = PR_Vec3_New(L); \
        PARSE_VEC(); \
        lua_rawset(L, -3); \
        lua_pop(L, 1); \
        return true; \
    }

qboolean ED_SetField(edict_t *e, const char *key, const char *value)
{
    int i;
    char string[128];
    char *v, *w;
    vec_t *vec;

    /* this is a bad hack and needs to be rewritten, this works for start.bsp for now */
    FIELD_FLOAT(sounds);
    FIELD_STRING(classname);
    FIELD_STRING(message);
    FIELD_VEC(origin);
    FIELD_VEC(angles);
    FIELD_STRING(target);
    FIELD_STRING(model);
    FIELD_STRING(targetname);
    FIELD_FLOAT(spawnflags);
    FIELD_FLOAT(health);

    ED_EnsureFields(e);

    FIELD_LSTRING(wad);
    FIELD_LFLOAT(worldtype);
    FIELD_LFLOAT(light_lev);
    FIELD_LFLOAT(speed);
    FIELD_LFLOAT(style);
    FIELD_LFLOAT(wait);
    FIELD_LSTRING(map);
    FIELD_LSTRING(killtarget);
    FIELD_LVEC(mangle);

    return false;
}

/*
====================
ED_ParseEdict

Parses an edict out of the given string, returning the new position
ed should be a properly initialized empty edict.
Used for initial level load and for savegames.
====================
*/
char *ED_ParseEdict(char *data, edict_t * ent)
{
    qboolean anglehack;
    qboolean init;
    char keyname[256];

    init = false;

    // clear it
    ent->fields = 0; // XXX
    ED_EnsureFields(ent);

    // go through all the dictionary pairs
    while (1) {
        // parse key
        data = COM_Parse(data);
        if (com_token[0] == '}')
            break;
        if (!data)
            SV_Error("ED_ParseEntity: EOF without closing brace");

        // anglehack is to allow QuakeEd to write single scalar angles
        // and allow them to be turned into vectors. (FIXME...)
        if (!strcmp(com_token, "angle")) {
            strcpy(com_token, "angles");
            anglehack = true;
        } else
            anglehack = false;

        // FIXME: change light to _light to get rid of this hack
        if (!strcmp(com_token, "light"))
            strcpy(com_token, "light_lev");     // hack for single light def

        strcpy(keyname, com_token);

        // parse value  
        data = COM_Parse(data);
        if (!data)
            SV_Error("ED_ParseEntity: EOF without closing brace");

        if (com_token[0] == '}')
            SV_Error("ED_ParseEntity: closing brace without data");

        init = true;

        // keynames with a leading underscore are used for utility comments,
        // and are immediately discarded by quake
        if (keyname[0] == '_')
            continue;

        if (anglehack) {
            char temp[32];
            strcpy(temp, com_token);
            sprintf(com_token, "0 %s 0", temp);
        }

        if (!ED_SetField(ent, keyname, com_token))
            SV_Error("ED_ParseEdict: parse error, can't set field '%s' to '%s'", keyname, com_token);
    }

    if (!init)
        ent->free = true;

    return data;
}

/*
================
ED_LoadFromFile

The entities are directly placed in the array, rather than allocated with
ED_Alloc, because otherwise an error loading the map would have entity
number references out of order.

Creates a server's entity / program execution context by
parsing textual entity definitions out of an ent file.

Used for both fresh maps and savegame loads.  A fresh map would also need
to call ED_CallSpawnFunctions () to let the objects initialize themselves.
================
*/
void ED_LoadFromFile(char *data)
{
    edict_t *ent;
    int inhibit;
    int ref;
    int i;

    Con_Printf("ED_LoadFromFile(data=%p)\n", data);

    ent = NULL;
    inhibit = 0;

    // XXX: this is a stupid place to do this
    for (i = 1; i < MAX_CLIENTS; i++) {
        ED_EnsureFields(EDICT_NUM(i));
    }

    // parse ents
    while (1) {
        // parse the opening brace      
        data = COM_Parse(data);
        if (!data)
            break;
        if (com_token[0] != '{')
            SV_Error("ED_LoadFromFile: found %s when expecting {",
                     com_token);

        if (!ent)
            ent = EDICT_NUM(0);
        else
            ent = ED_Alloc();
        data = ED_ParseEdict(data, ent);

        // remove things from different skill levels or deathmatch
#if 0
        if (((int) ent->v.spawnflags & SPAWNFLAG_NOT_DEATHMATCH)) {
            ED_Free(ent);
            inhibit++;
            continue;
        }
#else
        #define current_skill 0 // XXX
        if (deathmatch.value)
        {
            if (((int)ent->v.spawnflags & SPAWNFLAG_NOT_DEATHMATCH))
            {
                ED_Free (ent);  
                inhibit++;
                continue;
            }
        }
        else if ((current_skill == 0 && ((int)ent->v.spawnflags & SPAWNFLAG_NOT_EASY))
            || (current_skill == 1 && ((int)ent->v.spawnflags & SPAWNFLAG_NOT_MEDIUM))
            || (current_skill >= 2 && ((int)ent->v.spawnflags & SPAWNFLAG_NOT_HARD)) )
        {
            ED_Free (ent);  
            inhibit++;
            continue;
        }
#endif
        //
        // immediately call spawn function
        //
        if (!ent->v.classname) {
            Con_Printf("No classname for:\n");
            //ED_Print(ent);
            ED_Free(ent);
            continue;
        }
        // look for the spawn function
        lua_getglobal(L, PR_GetString(ent->v.classname));

        if (!lua_isfunction(L, -1)) {
            Con_Printf("No spawn function for '%s'\n", PR_GetString(ent->v.classname));
            //ED_Print(ent);
            ED_Free(ent);
            lua_pop(L, 1);
            continue;
        }

        pr_global_struct->self = ent->ref;

        ref = luaL_ref(L, LUA_REGISTRYINDEX);
        PR_ExecuteProgram(ref);
        luaL_unref(L, LUA_REGISTRYINDEX, ref);

        SV_FlushSignon();
    }

    Con_DPrintf("%i entities inhibited\n", inhibit);
}

eval_t *GetEdictFieldValue(edict_t * ed, char *field)
{
    //Con_Printf("GetEdictFieldValue(edict=%p, field=\"%s\")\n", ed, field);
    return NULL;
}

int ED_FindFunction(const char *name)
{
    lua_getglobal(L, name);

    if (lua_isfunction(L, -1))
        return luaL_ref(L, LUA_REGISTRYINDEX);

    Con_Printf("Did not find function '%s'\n", name);

    lua_pop(L, 1);
    return LUA_NOREF;
}

#define PUSH_FFLOAT(s) \
    if (strcmp(key, #s) == 0) { \
        lua_pushnumber(L, (*e)->v.s); \
        return 1; \
    }

#define PUSH_FSTRING(s) \
    if (strcmp(key, #s) == 0) { \
        lua_rawgeti(L, LUA_REGISTRYINDEX, (*e)->v.s); \
        return 1; \
    }

#define PUSH_FVEC3(s) \
    if (strcmp(key, #s) == 0) { \
        PR_Vec3_Push(L, (*e)->v.s); \
        return 1; \
    }

static int ED_mt_index(lua_State *L)
{
    edict_t **e;
    const char *key;

    e = lua_touserdata(L, 1);
    key = lua_tostring(L, 2);

    // first handle C fields
    PUSH_FVEC3(origin);
    PUSH_FVEC3(angles);
    PUSH_FVEC3(view_ofs);
    PUSH_FVEC3(velocity);
    PUSH_FVEC3(mins);
    PUSH_FVEC3(maxs);
    PUSH_FSTRING(target);
    PUSH_FSTRING(targetname);
    PUSH_FSTRING(message);
    PUSH_FFLOAT(spawnflags);

    //Sys_Printf("ED_mt_index(%p, %s) falling through\n", *e, key);

    // pull it from fields table otherwise
    ED_EnsureFields(*e);

    lua_rawgeti(L, LUA_REGISTRYINDEX, (*e)->fields);
    lua_pushstring(L, key);
    lua_rawget(L, -2);
    lua_remove(L, -2);

    return 1;
}

#define SET_FFLOAT(s)  \
    if (strcmp(key, #s) == 0) { \
        (*e)->v.s = lua_tonumber(L, 3); \
        return 0; \
    }

#define SET_FFUNC(s)  \
    if (strcmp(key, #s) == 0) { \
        lua_pushvalue(L, 3); \
        (*e)->v.s = luaL_ref(L, LUA_REGISTRYINDEX); \
        return 0; \
    }

#define SET_FVEC3(s) \
    if (strcmp(key, #s) == 0) { \
        vec_t *_tmpvec; \
        _tmpvec = PR_Vec3_ToVec(L, 3); \
        memcpy((*e)->v.s, _tmpvec, sizeof(vec3_t)); \
        return 0; \
    }

static int ED_mt_newindex(lua_State *L)
{
    edict_t **e;
    const char *key;

    e = lua_touserdata(L, 1);
    key = lua_tostring(L, 2);

    //Sys_Printf("ED_mt_newindex(%p, %s)\n", *e, key);

    // first handle C fields
    SET_FFLOAT(health);
    SET_FFLOAT(takedamage);
    SET_FFLOAT(solid);
    SET_FFLOAT(movetype);
    SET_FFLOAT(flags);
    SET_FFLOAT(frame);
    SET_FFLOAT(nextthink);
    SET_FFUNC(think);
    SET_FFUNC(touch);
    SET_FFUNC(use);
    //SET_FFUNC(owner); // it's actually an edict
    SET_FVEC3(origin);
    SET_FVEC3(angles);
    SET_FVEC3(view_ofs);
    SET_FVEC3(velocity);

    // set the data to a field otherwise
    ED_EnsureFields(*e);

    lua_rawgeti(L, LUA_REGISTRYINDEX, (*e)->fields);
    lua_pushstring(L, key);
    lua_pushvalue(L, 3);
    lua_rawset(L, -3);
    lua_pop(L, 1);

    return 0;
}

static const luaL_Reg ED_mt[] = {
    {"__index",     ED_mt_index},
    {"__newindex",  ED_mt_newindex},
    {0, 0}
};

/*
===============
PR_LoadProgs
===============
*/
void PR_LoadProgs(void)
{
    byte* code;

    pr_edict_size = sizeof(edict_t);
    pr_strings = ""; // uh?
    pr_global_struct = Z_Malloc(sizeof *pr_global_struct);
    progs = Z_Malloc(sizeof *progs);
    progs->entityfields = sizeof(((edict_t *)0)->v) / 4; // this is also horrible
    L = luaL_newstate();
    luaL_openlibs(L);

    PR_Vec3_Init(L);

    luaL_newmetatable(L, "edict_t");
    luaL_setfuncs(L, ED_mt, 0);
    lua_pop(L, 1);

    PR_InstallBuiltins();

    code = COM_LoadHunkFile("qwprogs.lua");
    if (!code)
        SV_Error("No qwprogs.lua found.");

    luaL_loadstring(L, (char *)code);
    lua_call(L, 0, 0);

    pr_global_struct->main = ED_FindFunction("main");
    pr_global_struct->StartFrame = ED_FindFunction("StartFrame");
    pr_global_struct->PlayerPreThink = ED_FindFunction("PlayerPreThink");
    pr_global_struct->PlayerPostThink = ED_FindFunction("PlayerPostThink");
    pr_global_struct->ClientKill = ED_FindFunction("ClientKill");
    pr_global_struct->ClientConnect = ED_FindFunction("ClientConnect");
    pr_global_struct->PutClientInServer = ED_FindFunction("PutClientInServer");
    pr_global_struct->ClientDisconnect = ED_FindFunction("ClientDisconnect");
    pr_global_struct->SetNewParms = ED_FindFunction("SetNewParms");
    pr_global_struct->SetChangeParms = ED_FindFunction("SetChangeParms");
}


/*
===============
PR_Init
===============
*/
void PR_Init(void)
{
    Con_Printf("PR_Init called\n");
    /*
    Cmd_AddCommand("edict", ED_PrintEdict_f);
    Cmd_AddCommand("edicts", ED_PrintEdicts);
    Cmd_AddCommand("edictcount", ED_Count);
    Cmd_AddCommand("profile", PR_Profile_f);
    */
}

/*
====================
PR_ExecuteProgram
====================
*/
void PR_ExecuteProgram(func_t fnum)
{
    lua_rawgeti(L, LUA_REGISTRYINDEX, fnum);

    if (!lua_isfunction(L, -1))
        SV_Error("PR_ExecuteProgram(%d) did not get a function");

    // XXX: big hack because first frame is run before other edicts are initialized than world
    if (sv.state == ss_loading && EDICT_NUM(0)->ref == 0) {
        ED_EnsureFields(EDICT_NUM(0));
        pr_global_struct->self = EDICT_NUM(0)->ref;
        pr_global_struct->other = EDICT_NUM(0)->ref;
    }

    if (pr_global_struct->self == 0)
        SV_Error("Executing a function with zero self, this is a bug.\n");

    lua_rawgeti(L, LUA_REGISTRYINDEX, pr_global_struct->self);
    lua_setglobal(L, "self");

    if (EDICT_NUM(0)->ref) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, EDICT_NUM(0)->ref);
        lua_setglobal(L, "world");
    }

    if (pr_global_struct->other) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, pr_global_struct->other);
    } else {
        lua_pushnil(L);
    }
    lua_setglobal(L, "other");

    lua_pushnumber(L, svs.serverflags);
    lua_setglobal(L, "serverflags");

    lua_pushnumber(L, sv.time);
    lua_setglobal(L, "time");

    lua_pushnumber(L, pr_global_struct->force_retouch);
    lua_setglobal(L, "force_retouch");

    lua_call(L, 0, 0);

    lua_getglobal(L, "force_retouch");
    pr_global_struct->force_retouch = lua_tonumber(L, -1);
    lua_pop(L, 1);
}

edict_t *EDICT_NUM(int n)
{
    if (n < 0 || n >= MAX_EDICTS)
        SV_Error("EDICT_NUM: bad number %i", n);
    return (edict_t *) ((byte *) sv.edicts + (n) * pr_edict_size);
}

int NUM_FOR_EDICT(edict_t * e)
{
    int b;

    b = (byte *) e - (byte *) sv.edicts;
    b = b / pr_edict_size;

    if (b < 0 || b >= sv.num_edicts)
        SV_Error("NUM_FOR_EDICT: bad pointer");
    return b;
}

char *PR_GetString(int num)
{
    static char buf[256];

    if (num == 0)
        return "";

    lua_rawgeti(L, LUA_REGISTRYINDEX, num);

    if (!lua_isstring(L, -1))
        SV_Error("PR_GetString(%d) did not get a string");

    snprintf(buf, sizeof(buf), "%s", lua_tostring(L, -1));

    lua_pop(L, 1);

    //Con_Printf("PR_GetString(%d) -> '%s'\n", num, buf);

    return buf;
}

int PR_SetString(char *s)
{
    lua_pushstring(L, s);
    return luaL_ref(L, LUA_REGISTRYINDEX);
}

// XXX: these are *never* freed at this point
char *PR_StrDup(const char *in)
{
    char *out;

    out = Z_Malloc(strlen(in) + 1);
    strcpy(out, in);

    return out;
}

edict_t *PROG_TO_EDICT(int ref)
{
    edict_t **e;

    lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
    e = lua_touserdata(L, -1);

    lua_pop(L, 1);

    return *e;
}
