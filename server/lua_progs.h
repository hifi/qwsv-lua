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

/*
typedef enum { ev_void, ev_string, ev_float, ev_vector, ev_entity,
        ev_field, ev_function, ev_pointer } etype_t;
        */

#define	OFS_NULL		0
#define	OFS_RETURN		1
#define	OFS_PARM0		4
#define	OFS_PARM1		7
#define	OFS_PARM2		10
#define	OFS_PARM3		13
#define	OFS_PARM4		16
#define	OFS_PARM5		19
#define	OFS_PARM6		22
#define	OFS_PARM7		25
#define	RESERVED_OFS	28

struct edict_s;

#include "progdefs.h"

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

typedef union eval_s {
    string_t string;
    float _float;
    float vector[3];
    func_t function;
    int _int;
    int edict;
} eval_t;

typedef struct {
    unsigned short type;    // if DEF_SAVEGLOBGAL bit is set
                            // the variable needs to be saved in savegames
    unsigned short ofs;
    int s_name;
} ddef_t;
#define	DEF_SAVEGLOBAL	(1<<15)

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

#define	EDICT_FROM_AREA(l) STRUCT_FROM_LINK(l,edict_t,area)

//============================================================================

//============================================================================

void PR_Init(void);
void PR_InstallBuiltins(void);

void PR_ExecuteProgram(func_t fnum);
void PR_LoadProgs(void);

void PR_Profile_f(void);
char *PR_StrDup(const char *);

edict_t *ED_Alloc(void);
void ED_Free(edict_t * ed);
void ED_PushEdict(edict_t *ed);

char *ED_NewString(char *string);
// returns a copy of the string allocated from the server's string heap

void ED_Print(edict_t * ed);
void ED_Write(FILE * f, edict_t * ed);
char *ED_ParseEdict(char *data, edict_t * ent);

void ED_WriteGlobals(FILE * f);
void ED_ParseGlobals(char *data);

void ED_LoadFromFile(char *data);

//define EDICT_NUM(n) ((edict_t *)(sv.edicts+ (n)*pr_edict_size))
//define NUM_FOR_EDICT(e) (((byte *)(e) - sv.edicts)/pr_edict_size)

edict_t *EDICT_NUM(int n);
int NUM_FOR_EDICT(edict_t * e);

#define	NEXT_EDICT(e) ((edict_t *)( (byte *)e + pr_edict_size))

#define	EDICT_TO_PROG(e) (e->ref)
//#define PROG_TO_EDICT(e) (e)
edict_t *PROG_TO_EDICT(int ref);

//============================================================================

float* g_float_p(int o);
#define G_FLOAT(o) (*g_float_p(o))
int* g_int_p(int o);
#define G_INT(o) (*g_int_p(o))
edict_t* G_EDICT(int o);
#define G_EDICTNUM(o) NUM_FOR_EDICT(G_EDICT(o))
vec_t* G_VECTOR(int o);
char* G_STRING(int o);
int G_FUNCTION(int o);

#define	E_FLOAT(e,o) (((float*)&e->v)[o])
#define	E_INT(e,o) (*(int *)&((float*)&e->v)[o])
#define	E_VECTOR(e,o) (&((float*)&e->v)[o])
#define	E_STRING(e,o) (PR_GetString(*(string_t *)&((float*)&e->v)[o]))

extern int type_size[8];

typedef void (*builtin_t) (void);
extern builtin_t *pr_builtins;
extern int pr_numbuiltins;

extern int pr_argc;

extern qboolean pr_trace;

extern func_t SpectatorConnect;
extern func_t SpectatorThink;
extern func_t SpectatorDisconnect;

void PR_RunError(char *error, ...);

void ED_PrintEdicts(void);
void ED_PrintNum(int ent);

eval_t *GetEdictFieldValue(edict_t * ed, char *field);

//
// PR STrings stuff
//
#define MAX_PRSTR 1024

char *PR_GetString(int num);
int PR_SetString(char *s);

/* compatibility things */
extern char *pr_strings;
extern globalvars_t *pr_global_struct;
extern int pr_edict_size;       // in bytes

typedef struct {
    int entityfields;
} dprograms_t;

typedef int dfunction_t;
extern dprograms_t *progs;
extern char *pr_strtbl[MAX_PRSTR];
extern int num_prstr;

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

/* lua_vector.c */
void PR_Vec3_Init(lua_State *L);
vec_t* PR_Vec3_New(lua_State *L);
vec_t* PR_Vec3_ToVec(lua_State *L, int index);
void PR_Vec3_Push(lua_State *L, vec3_t in);
