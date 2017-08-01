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

typedef int func_t;
typedef int string_t;

struct edict_s;

#include "progdefs.h"

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

typedef struct {
    unsigned short type;    // if DEF_SAVEGLOBGAL bit is set
                            // the variable needs to be saved in savegames
    unsigned short ofs;
    int s_name;
} ddef_t;

#define	MAX_ENT_LEAFS	16
typedef struct edict_s {
    qboolean free;
    link_t area;                // linked to a division node or leaf

    int num_leafs;
    short leafnums[MAX_ENT_LEAFS];

    entity_state_t baseline;

    float freetime;             // sv.time when the object was freed
    entvars_t v;                // C exported fields from progs
    int ref;                    // Lua self reference
    int fields;                 // Lua fields table ref
} edict_t;

//============================================================================

void PR_Init(void);
void PR_InstallBuiltins(void);

void PR_ExecuteProgram(func_t fnum);
void PR_LoadProgs(void);

void PR_Profile_f(void);
char *PR_StrDup(const char *); // XXX: this needs to be fixed

edict_t *ED_Alloc(void);
void ED_Free(edict_t * ed);
void ED_PushEdict(edict_t *ed);

void ED_Print(edict_t * ed);
char *ED_ParseEdict(char *data, edict_t * ent);
void ED_LoadFromFile(char *data);

edict_t *EDICT_NUM(int n);
int NUM_FOR_EDICT(edict_t * e);
#define	NEXT_EDICT(e) ((edict_t *)( (byte *)e + pr_edict_size))

#define	EDICT_TO_PROG(e) (e->ref)
edict_t *PROG_TO_EDICT(int ref);
#define	EDICT_FROM_AREA(l) STRUCT_FROM_LINK(l,edict_t,area)

//============================================================================

extern func_t SpectatorConnect;
extern func_t SpectatorThink;
extern func_t SpectatorDisconnect;

void PR_RunError(char *error, ...);

void ED_PrintEdicts(void);
void ED_PrintNum(int ent);
#define ED_PushEdict(L, e) lua_rawgeti(L, LUA_REGISTRYINDEX, e->ref);

typedef union eval_s {
    string_t string;
    float _float;
    float vector[3];
    func_t function;
    int _int;
    int edict;
} eval_t;

eval_t *GetEdictFieldValue(edict_t * ed, char *field);

//
// PR Strings stuff
//
#define MAX_PRSTR 1024

char *PR_GetString(int num);
int PR_SetString(char *s);

//
// compatibility with the engine as it is
//
extern char *pr_strings;
extern globalvars_t *pr_global_struct;
extern int pr_edict_size; // in bytes

typedef struct {
    int entityfields;
} dprograms_t;

typedef int dfunction_t;
extern dprograms_t *progs;
extern int num_prstr;

//
// lua_edict.c helpers
//

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

#define PUSH_GREF(s) \
    if (pr_global_struct->s) \
        lua_rawgeti(L, LUA_REGISTRYINDEX, pr_global_struct->s); \
    else \
        lua_pushnil(L); \
    lua_setglobal(L, #s);

#define PUSH_GFLOAT(s) \
    lua_pushnumber(L, pr_global_struct->s); \
    lua_setglobal(L, #s);

#define PUSH_GVEC3(s) \
    PR_Vec3_Push(L, pr_global_struct->s); \
    lua_setglobal(L, #s);

#define GET_GFLOAT(s) \
    lua_getglobal(L, #s); \
    pr_global_struct->s = lua_tonumber(L, -1); \
    lua_pop(L, 1); \

//
// lua_vector.c
//
void PR_Vec3_Init(lua_State *L);
vec_t* PR_Vec3_New(lua_State *L);
vec_t* PR_Vec3_ToVec(lua_State *L, int index);
void PR_Vec3_Push(lua_State *L, vec3_t in);
