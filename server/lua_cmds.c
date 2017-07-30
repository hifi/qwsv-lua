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

#include "qwsvdef.h"

#define PR_RunError(a, ...) SV_Error(a)

extern lua_State *L;

float* g_float_p(int o)
{
    return NULL;
}

int* g_int_p(int o)
{
    return NULL;
}

edict_t* G_EDICT(int o)
{
    return NULL;
}

vec_t* G_VECTOR(int o)
{
    return NULL;
}

char* G_STRING(int o)
{
    return NULL;
}

int G_FUNCTION(int o)
{
    return 0;
}

#define	RETURN_EDICT(e) NULL
#define	RETURN_STRING(s) NULL

/*
===============================================================================

						BUILT-IN FUNCTIONS

===============================================================================
*/

char *PF_VarString(int first)
{
    int i;
    static char out[256];

    out[0] = 0;
    for (i = first; i < pr_argc; i++) {
        strcat(out, G_STRING((OFS_PARM0 + i * 3)));
    }
    return out;
}


/*
=================
PF_errror

This is a TERMINAL error, which will kill off the entire server.
Dumps self.

error(value)
=================
*/
void PF_error(void)
{
    SV_Error("Program error");
}

/*
=================
PF_objerror

Dumps out self, then an error message.  The program is aborted and self is
removed, but the level can continue.

objerror(value)
=================
*/
int PF_objerror(lua_State *L)
{
    const char *s;
    edict_t *ed;

    s = luaL_checkstring(L, 1);
    Con_Printf("======OBJECT ERROR in %s:\n%s\n",
               "(unknown)", s);
    ed = PROG_TO_EDICT(pr_global_struct->self);
    //ED_Print(ed);
    ED_Free(ed);

    SV_Error("Program error");
    return 0;
}



/*
==============
PF_makevectors

Writes new values for v_forward, v_up, and v_right based on angles
makevectors(vector)
==============
*/
int PF_makevectors(lua_State *L)
{
    vec_t **v;
    v = luaL_checkudata(L, 1, "vec3_t");

    AngleVectors((*v), pr_global_struct->v_forward,
                 pr_global_struct->v_right, pr_global_struct->v_up);

    // global variables need to be pushed back
    PUSH_GVEC3(v_forward);
    PUSH_GVEC3(v_up);
    PUSH_GVEC3(v_right);

    return 0;
}

/*
=================
PF_setorigin

This is the only valid way to move an object without using the physics of the world (setting velocity and waiting).  Directly changing origin will not set internal links correctly, so clipping would be messed up.  This should be called when an object is spawned, and then only if it is teleported.

setorigin (entity, origin)
=================
*/
int PF_setorigin(lua_State *L)
{
    edict_t **e;
    vec_t *org;

    e = lua_touserdata(L, 1);
    org = PR_Vec3_ToVec(L, 2);
    VectorCopy(org, (*e)->v.origin);
    SV_LinkEdict(*e, false);
    return 0;
}


/*
=================
PF_setsize

the size box is rotated by the current angle

setsize (entity, minvector, maxvector)
=================
*/
int PF_setsize(lua_State *L)
{
    edict_t **e;
    vec_t *min, *max;

    e = lua_touserdata(L, 1);
    min = PR_Vec3_ToVec(L, 2);
    max = PR_Vec3_ToVec(L, 3);

    VectorCopy(min, (*e)->v.mins);
    VectorCopy(max, (*e)->v.maxs);
    VectorSubtract(max, min, (*e)->v.size);
    SV_LinkEdict((*e), false);
    return 0;
}


/*
=================
PF_setmodel

setmodel(entity, model)
Also sets size, mins, and maxs for inline bmodels
=================
*/
int PF_setmodel(lua_State *L)
{
    edict_t **e;
    char *m, **check;
    int i;
    model_t *mod;


    e = luaL_checkudata(L, 1, "edict_t");

    /* silently ignore if model is nil */
    if (lua_isnil(L, 2))
        m = "";
    else
        m = (char *)luaL_checkstring(L, 2);

    // check to see if model was properly precached
    for (i = 0, check = sv.model_precache; *check; i++, check++)
        if (!strcmp(*check, m))
            break;

    if (!*check)
        PR_RunError("no precache: %s\n", m);

    (*e)->v.model = PR_SetString(m);
    (*e)->v.modelindex = i;

    // if it is an inline model, get the size information for it
    if (m[0] == '*') {
        mod = Mod_ForName(m, true);
        VectorCopy(mod->mins, (*e)->v.mins);
        VectorCopy(mod->maxs, (*e)->v.maxs);
        VectorSubtract(mod->maxs, mod->mins, (*e)->v.size);
        SV_LinkEdict(*e, false);
    }

    return 0;
}

/*
=================
PF_bprint

broadcast print to everyone on server

bprint(value)
=================
*/
void PF_bprint(void)
{
    char *s;
    int level;

    level = G_FLOAT(OFS_PARM0);

    s = PF_VarString(1);
    SV_BroadcastPrintf(level, "%s", s);
}

/*
=================
PF_sprint

single print to a specific client

sprint(clientent, value)
=================
*/
void PF_sprint(void)
{
    char *s;
    client_t *client;
    int entnum;
    int level;

    entnum = G_EDICTNUM(OFS_PARM0);
    level = G_FLOAT(OFS_PARM1);

    s = PF_VarString(2);

    if (entnum < 1 || entnum > MAX_CLIENTS) {
        Con_Printf("tried to sprint to a non-client\n");
        return;
    }

    client = &svs.clients[entnum - 1];

    SV_ClientPrintf(client, level, "%s", s);
}


/*
=================
PF_centerprint

single print to a specific client

centerprint(clientent, value)
=================
*/
int PF_centerprint(lua_State *L)
{
    char *s;
    int entnum;
    edict_t **ed;
    client_t *cl;

    ed = luaL_checkudata(L, 1, "edict_t");
    s = (char *)luaL_checkstring(L, 2);

    entnum = NUM_FOR_EDICT(*ed);

    if (entnum < 1 || entnum > MAX_CLIENTS) {
        Con_Printf("tried to sprint to a non-client\n");
        return 0;
    }

    cl = &svs.clients[entnum - 1];

    ClientReliableWrite_Begin(cl, svc_centerprint, 2 + strlen(s));
    ClientReliableWrite_String(cl, s);
    return 0;
}


/*
=================
PF_normalize

vector normalize(vector)
=================
*/
int PF_normalize(lua_State *L)
{
    vec_t *value1;
    vec_t *newvalue;
    float new;

    value1 = PR_Vec3_ToVec(L, 1);
    newvalue = PR_Vec3_New(L);

    new =
        value1[0] * value1[0] + value1[1] * value1[1] +
        value1[2] * value1[2];
    new = sqrt(new);

    if (new == 0)
        newvalue[0] = newvalue[1] = newvalue[2] = 0;
    else {
        new = 1 / new;
        newvalue[0] = value1[0] * new;
        newvalue[1] = value1[1] * new;
        newvalue[2] = value1[2] * new;
    }

    return 1;
}

/*
=================
PF_vectoyaw

float vectoyaw(vector)
=================
*/
void PF_vectoyaw(void)
{
    float *value1;
    float yaw;

    value1 = G_VECTOR(OFS_PARM0);

    if (value1[1] == 0 && value1[0] == 0)
        yaw = 0;
    else {
        yaw = (int) (atan2(value1[1], value1[0]) * 180 / M_PI);
        if (yaw < 0)
            yaw += 360;
    }

    G_FLOAT(OFS_RETURN) = yaw;
}


/*
=================
PF_vectoangles

vector vectoangles(vector)
=================
*/
int PF_vectoangles(lua_State *L)
{
    vec_t *value1;
    float forward;
    float yaw, pitch;
    vec_t *ret;

    value1 = PR_Vec3_ToVec(L, 1);
    ret = PR_Vec3_New(L);

    if (value1[1] == 0 && value1[0] == 0) {
        yaw = 0;
        if (value1[2] > 0)
            pitch = 90;
        else
            pitch = 270;
    } else {
        yaw = (int) (atan2(value1[1], value1[0]) * 180 / M_PI);
        if (yaw < 0)
            yaw += 360;

        forward = sqrt(value1[0] * value1[0] + value1[1] * value1[1]);
        pitch = (int) (atan2(value1[2], forward) * 180 / M_PI);
        if (pitch < 0)
            pitch += 360;
    }

    ret[0] = pitch;
    ret[1] = yaw;
    ret[2] = 0;

    return 1;
}

/*
=================
PF_Random

Returns a number from 0<= num < 1

random()
=================
*/
int PF_random(lua_State *L)
{
    float num;

    num = (rand() & 0x7fff) / ((float) 0x7fff);

    lua_pushnumber(L, num);
    return 1;
}


/*
=================
PF_ambientsound

=================
*/
int PF_ambientsound(lua_State *L)
{
    char **check;
    const char *samp;
    vec_t *pos;
    float vol, attenuation;
    int i, soundnum;

    pos = PR_Vec3_ToVec(L, 1);
    samp = lua_tostring(L, 2);
    vol = lua_tonumber(L, 3);
    attenuation = lua_tonumber(L, 4);

    // check to see if samp was properly precached
    for (soundnum = 0, check = sv.sound_precache; *check;
         check++, soundnum++)
        if (!strcmp(*check, samp))
            break;

    if (!*check) {
        Con_Printf("no precache: %s\n", samp);
        return 0;
    }
    // add an svc_spawnambient command to the level signon packet

    MSG_WriteByte(&sv.signon, svc_spawnstaticsound);
    for (i = 0; i < 3; i++)
        MSG_WriteCoord(&sv.signon, pos[i]);

    MSG_WriteByte(&sv.signon, soundnum);

    MSG_WriteByte(&sv.signon, vol * 255);
    MSG_WriteByte(&sv.signon, attenuation * 64);
    return 0;
}

/*
=================
PF_sound

Each entity can have eight independant sound sources, like voice,
weapon, feet, etc.

Channel 0 is an auto-allocate channel, the others override anything
allready running on that entity/channel pair.

An attenuation of 0 will play full volume everywhere in the level.
Larger attenuations will drop off.

=================
*/
int PF_sound(lua_State *L)
{
    char *sample;
    int channel;
    edict_t **entity;
    int volume;
    float attenuation;

    entity = luaL_checkudata(L, 1, "edict_t");
    channel = luaL_checknumber(L, 2);
    sample = (char *)luaL_checkstring(L, 3);
    volume = luaL_checknumber(L, 4) * 255;
    attenuation = luaL_checknumber(L, 5);

    SV_StartSound(*entity, channel, sample, volume, attenuation);
    return 0;
}

/*
=================
PF_break

break()
=================
*/
void PF_break(void)
{
    Con_Printf("break statement\n");
    *(int *) -4 = 0;            // dump to debugger
//      PR_RunError ("break statement");
}

/*
=================
PF_traceline

Used for use tracing and shot targeting
Traces are blocked by bbox and exact bsp entityes, and also slide box entities
if the tryents flag is set.

traceline (vector1, vector2, tryents)
=================
*/
void PF_traceline(void)
{
    float *v1, *v2;
    trace_t trace;
    int nomonsters;
    edict_t *ent;

    v1 = G_VECTOR(OFS_PARM0);
    v2 = G_VECTOR(OFS_PARM1);
    nomonsters = G_FLOAT(OFS_PARM2);
    ent = G_EDICT(OFS_PARM3);

    trace = SV_Move(v1, vec3_origin, vec3_origin, v2, nomonsters, ent);

    pr_global_struct->trace_allsolid = trace.allsolid;
    pr_global_struct->trace_startsolid = trace.startsolid;
    pr_global_struct->trace_fraction = trace.fraction;
    pr_global_struct->trace_inwater = trace.inwater;
    pr_global_struct->trace_inopen = trace.inopen;
    VectorCopy(trace.endpos, pr_global_struct->trace_endpos);
    VectorCopy(trace.plane.normal, pr_global_struct->trace_plane_normal);
    pr_global_struct->trace_plane_dist = trace.plane.dist;
    if (trace.ent)
        pr_global_struct->trace_ent = EDICT_TO_PROG(trace.ent);
    else
        pr_global_struct->trace_ent = EDICT_TO_PROG(sv.edicts);
}

/*
=================
PF_checkpos

Returns true if the given entity can move to the given position from it's
current position by walking or rolling.
FIXME: make work...
scalar checkpos (entity, vector)
=================
*/
void PF_checkpos(void)
{
}

//============================================================================

byte checkpvs[MAX_MAP_LEAFS / 8];

int PF_newcheckclient(int check)
{
    int i;
    byte *pvs;
    edict_t *ent;
    mleaf_t *leaf;
    vec3_t org;

// cycle to the next one

    if (check < 1)
        check = 1;
    if (check > MAX_CLIENTS)
        check = MAX_CLIENTS;

    if (check == MAX_CLIENTS)
        i = 1;
    else
        i = check + 1;

    for (;; i++) {
        if (i == MAX_CLIENTS + 1)
            i = 1;

        ent = EDICT_NUM(i);

        if (i == check)
            break;              // didn't find anything else

        if (ent->free)
            continue;
        if (ent->v.health <= 0)
            continue;
        if ((int) ent->v.flags & FL_NOTARGET)
            continue;

        // anything that is a client, or has a client as an enemy
        break;
    }

// get the PVS for the entity
    VectorAdd(ent->v.origin, ent->v.view_ofs, org);
    leaf = Mod_PointInLeaf(org, sv.worldmodel);
    pvs = Mod_LeafPVS(leaf, sv.worldmodel);
    memcpy(checkpvs, pvs, (sv.worldmodel->numleafs + 7) >> 3);

    return i;
}

/*
=================
PF_checkclient

Returns a client (or object that has a client enemy) that would be a
valid target.

If there are more than one valid options, they are cycled each frame

If (self.origin + self.viewofs) is not in the PVS of the current target,
it is not returned at all.

name checkclient ()
=================
*/
#define	MAX_CHECK	16
int c_invis, c_notvis;
void PF_checkclient(void)
{
    edict_t *ent, *self;
    mleaf_t *leaf;
    int l;
    vec3_t view;

// find a new check if on a new frame
    if (sv.time - sv.lastchecktime >= 0.1) {
        sv.lastcheck = PF_newcheckclient(sv.lastcheck);
        sv.lastchecktime = sv.time;
    }
// return check if it might be visible  
    ent = EDICT_NUM(sv.lastcheck);
    if (ent->free || ent->v.health <= 0) {
        RETURN_EDICT(sv.edicts);
        return;
    }
// if current entity can't possibly see the check entity, return 0
    self = PROG_TO_EDICT(pr_global_struct->self);
    VectorAdd(self->v.origin, self->v.view_ofs, view);
    leaf = Mod_PointInLeaf(view, sv.worldmodel);
    l = (leaf - sv.worldmodel->leafs) - 1;
    if ((l < 0) || !(checkpvs[l >> 3] & (1 << (l & 7)))) {
        c_notvis++;
        RETURN_EDICT(sv.edicts);
        return;
    }
// might be able to see it
    c_invis++;
    RETURN_EDICT(ent);
}

//============================================================================


/*
=================
PF_stuffcmd

Sends text over to the client's execution buffer

stuffcmd (clientent, value)
=================
*/
void PF_stuffcmd(void)
{
    int entnum;
    char *str;
    client_t *cl;

    entnum = G_EDICTNUM(OFS_PARM0);
    if (entnum < 1 || entnum > MAX_CLIENTS)
        PR_RunError("Parm 0 not a client");
    str = G_STRING(OFS_PARM1);

    cl = &svs.clients[entnum - 1];

    if (strcmp(str, "disconnect\n") == 0) {
        // so long and thanks for all the fish
        cl->drop = true;
        return;
    }

    ClientReliableWrite_Begin(cl, svc_stufftext, 2 + strlen(str));
    ClientReliableWrite_String(cl, str);
}

/*
=================
PF_localcmd

Sends text over to the client's execution buffer

localcmd (string)
=================
*/
void PF_localcmd(void)
{
    char *str;

    str = G_STRING(OFS_PARM0);
    Cbuf_AddText(str);
}

/*
=================
PF_cvar

float cvar (string)
=================
*/
int PF_cvar(lua_State *L)
{
    char *str;

    str = (char *)lua_tostring(L, 1);

    lua_pushnumber(L, Cvar_VariableValue(str));
    return 1;
}

/*
=================
PF_cvar_set

float cvar (string)
=================
*/
int PF_cvar_set(lua_State *L)
{
    char *var, *val;

    var = (char *)lua_tostring(L, 1);
    val = (char *)lua_tostring(L, 2);

    Cvar_Set(var, val);
    return 0;
}

/*
=================
PF_findradius

Returns a chain of entities that have origins within a spherical area

findradius (origin, radius)
=================
*/
void PF_findradius(void)
{
    edict_t *ent, *chain;
    float rad;
    float *org;
    vec3_t eorg;
    int i, j;

    chain = (edict_t *) sv.edicts;

    org = G_VECTOR(OFS_PARM0);
    rad = G_FLOAT(OFS_PARM1);

    ent = NEXT_EDICT(sv.edicts);
    for (i = 1; i < sv.num_edicts; i++, ent = NEXT_EDICT(ent)) {
        if (ent->free)
            continue;
        if (ent->v.solid == SOLID_NOT)
            continue;
        for (j = 0; j < 3; j++)
            eorg[j] =
                org[j] - (ent->v.origin[j] +
                          (ent->v.mins[j] + ent->v.maxs[j]) * 0.5);
        if (Length(eorg) > rad)
            continue;

        ent->v.chain = EDICT_TO_PROG(chain);
        chain = ent;
    }

    RETURN_EDICT(chain);
}


/*
=========
PF_dprint
=========
*/
int PF_dprint(lua_State *L)
{
    Con_Printf("%s", lua_tostring(L, 1));
    return 0;
}

char pr_string_temp[128];

void PF_ftos(void)
{
    float v;
    v = G_FLOAT(OFS_PARM0);

    if (v == (int) v)
        sprintf(pr_string_temp, "%d", (int) v);
    else
        sprintf(pr_string_temp, "%5.1f", v);
    G_INT(OFS_RETURN) = PR_SetString(pr_string_temp);
}

int PF_fabs(lua_State *L)
{
    float v;
    v = luaL_checknumber(L, 1);
    lua_pushnumber(L, fabs(v));
    return 1;
}

void PF_vtos(void)
{
    sprintf(pr_string_temp, "'%5.1f %5.1f %5.1f'", G_VECTOR(OFS_PARM0)[0],
            G_VECTOR(OFS_PARM0)[1], G_VECTOR(OFS_PARM0)[2]);
    G_INT(OFS_RETURN) = PR_SetString(pr_string_temp);
}

int PF_Spawn(lua_State *L)
{
    edict_t *ed;
    ed = ED_Alloc();
    ED_PushEdict(ed);
    return 1;
}

int PF_Remove(lua_State *L)
{
    edict_t **ed;

    ed = lua_touserdata(L, 1);
    ED_Free(*ed);
    return 0;
}


// entity (entity start, .string field, string match) find = #5;
int PF_Find(lua_State *L)
{
    edict_t **e;
    const char *f;
    const char *s, *t;
    edict_t *ed;
    int i;

    e = luaL_checkudata(L, 1, "edict_t");
    f = luaL_checkstring(L, 2);
    s = luaL_checkstring(L, 3);

    i = NUM_FOR_EDICT(*e);

    for (i++; i < sv.num_edicts; i++) {
        ed = EDICT_NUM(i);
        if (ed->free)
            continue;

        t = NULL;

        // XXX fix these
        if (strcmp(f, "classname") == 0) {
            t = PR_GetString(ed->v.classname);
        }
        else if (strcmp(f, "targetname") == 0) {
            t = PR_GetString(ed->v.targetname);
        } else {
            SV_Error("PF_Find() called with unknown field");
        }

        if (!t)
            continue;
        if (!strcmp(t, s)) {
            ED_PushEdict(ed);
            return 1;
        }
    }

    return 0;
}

void PR_CheckEmptyString(char *s)
{
    if (s[0] <= ' ')
        PR_RunError("Bad string");
}

void PF_precache_file(void)
{                               // precache_file is only used to copy files with qcc, it does nothing
    G_INT(OFS_RETURN) = G_INT(OFS_PARM0);
}

int PF_precache_sound(lua_State *L)
{
    const char *s;
    int i;

    if (sv.state != ss_loading)
        PR_RunError
            ("PF_Precache_*: Precache can only be done in spawn functions");

    s = lua_tostring(L, 1);
    lua_pushvalue(L, 1);
    //PR_CheckEmptyString(s);

    for (i = 0; i < MAX_SOUNDS; i++) {
        if (!sv.sound_precache[i]) {
            sv.sound_precache[i] = PR_StrDup(s);
            return 1;
        }
        if (!strcmp(sv.sound_precache[i], s))
            return 1;
    }
    PR_RunError("PF_precache_sound: overflow");
    return 1;
}

int PF_precache_model(lua_State *L)
{
    const char *s;
    int i;

    if (sv.state != ss_loading)
        PR_RunError
            ("PF_Precache_*: Precache can only be done in spawn functions");

    s = lua_tostring(L, 1);
    lua_pushvalue(L, 1);
    //PR_CheckEmptyString(s);

    for (i = 0; i < MAX_MODELS; i++) {
        if (!sv.model_precache[i]) {
            sv.model_precache[i] = PR_StrDup(s);
            return 1;
        }
        if (!strcmp(sv.model_precache[i], s))
            return 1;
    }
    PR_RunError("PF_precache_model: overflow");
    return 1;
}


void PF_coredump(void)
{
}

void PF_traceon(void)
{
#if 0
    pr_trace = true;
#endif
}

void PF_traceoff(void)
{
#if 0
    pr_trace = false;
#endif
}

void PF_eprint(void)
{
}

/*
===============
PF_walkmove

float(float yaw, float dist) walkmove
===============
*/
void PF_walkmove(void)
{
#if 0
    edict_t *ent;
    float yaw, dist;
    vec3_t move;
    dfunction_t *oldf;
    int oldself;

    ent = PROG_TO_EDICT(pr_global_struct->self);
    yaw = G_FLOAT(OFS_PARM0);
    dist = G_FLOAT(OFS_PARM1);

    if (!((int) ent->v.flags & (FL_ONGROUND | FL_FLY | FL_SWIM))) {
        G_FLOAT(OFS_RETURN) = 0;
        return;
    }

    yaw = yaw * M_PI * 2 / 360;

    move[0] = cos(yaw) * dist;
    move[1] = sin(yaw) * dist;
    move[2] = 0;

// save program state, because SV_movestep may call other progs
    //oldf = pr_xfunction;
    oldself = pr_global_struct->self;

    G_FLOAT(OFS_RETURN) = SV_movestep(ent, move, true);


// restore program state
    //pr_xfunction = oldf;
    pr_global_struct->self = oldself;
#endif
}

/*
===============
PF_droptofloor

void() droptofloor
===============
*/
int PF_droptofloor(lua_State *L)
{
    edict_t *ent;
    vec3_t end;
    trace_t trace;

    ent = PROG_TO_EDICT(pr_global_struct->self);

    VectorCopy(ent->v.origin, end);
    end[2] -= 256;

    trace =
        SV_Move(ent->v.origin, ent->v.mins, ent->v.maxs, end, false, ent);

    if (trace.fraction == 1 || trace.allsolid)
        lua_pushnumber(L, 0);
    else {
        VectorCopy(trace.endpos, ent->v.origin);
        SV_LinkEdict(ent, false);
        ent->v.flags = (int) ent->v.flags | FL_ONGROUND;
        ent->v.groundentity = EDICT_TO_PROG(trace.ent);
        lua_pushnumber(L, 1);
    }

    return 1;
}

/*
===============
PF_lightstyle

void(float style, string value) lightstyle
===============
*/
int PF_lightstyle(lua_State *L)
{
    int style;
    char *val;
    client_t *client;
    int j;

    style = lua_tonumber(L, 1);
    val = (char *)lua_tostring(L, 2);

// change the string in sv
    sv.lightstyles[style] = val;

// send message to all clients on this server
    if (sv.state != ss_active)
        return 0;

    for (j = 0, client = svs.clients; j < MAX_CLIENTS; j++, client++)
        if (client->state == cs_spawned) {
            ClientReliableWrite_Begin(client, svc_lightstyle,
                                      strlen(val) + 3);
            ClientReliableWrite_Char(client, style);
            ClientReliableWrite_String(client, val);
        }

    return 0;
}

void PF_rint(void)
{
    float f;
    f = G_FLOAT(OFS_PARM0);
    if (f > 0)
        G_FLOAT(OFS_RETURN) = (int) (f + 0.5);
    else
        G_FLOAT(OFS_RETURN) = (int) (f - 0.5);
}

void PF_floor(void)
{
    G_FLOAT(OFS_RETURN) = floor(G_FLOAT(OFS_PARM0));
}

void PF_ceil(void)
{
    G_FLOAT(OFS_RETURN) = ceil(G_FLOAT(OFS_PARM0));
}


/*
=============
PF_checkbottom
=============
*/
void PF_checkbottom(void)
{
    edict_t *ent;

    ent = G_EDICT(OFS_PARM0);

    G_FLOAT(OFS_RETURN) = SV_CheckBottom(ent);
}

/*
=============
PF_pointcontents
=============
*/
int PF_pointcontents(lua_State *L)
{
    vec_t *v;

    v = PR_Vec3_ToVec(L, 1);

    lua_pushnumber(L, SV_PointContents(v));
    return 1;
}

/*
=============
PF_nextent

entity nextent(entity)
=============
*/
void PF_nextent(void)
{
    int i;
    edict_t *ent;

    i = G_EDICTNUM(OFS_PARM0);
    while (1) {
        i++;
        if (i == sv.num_edicts) {
            RETURN_EDICT(sv.edicts);
            return;
        }
        ent = EDICT_NUM(i);
        if (!ent->free) {
            RETURN_EDICT(ent);
            return;
        }
    }
}

/*
=============
PF_aim

Pick a vector for the player to shoot along
vector aim(entity, missilespeed)
=============
*/
//cvar_t        sv_aim = {"sv_aim", "0.93"};
cvar_t sv_aim = { "sv_aim", "2" };

void PF_aim(void)
{
#if 0
    edict_t *ent, *check, *bestent;
    vec3_t start, dir, end, bestdir;
    int i, j;
    trace_t tr;
    float dist, bestdist;
    float speed;
    char *noaim;

    ent = G_EDICT(OFS_PARM0);
    speed = G_FLOAT(OFS_PARM1);

    VectorCopy(ent->v.origin, start);
    start[2] += 20;

// noaim option
    i = NUM_FOR_EDICT(ent);
    if (i > 0 && i < MAX_CLIENTS) {
        noaim = Info_ValueForKey(svs.clients[i - 1].userinfo, "noaim");
        if (atoi(noaim) > 0) {
            VectorCopy(pr_global_struct->v_forward, G_VECTOR(OFS_RETURN));
            return;
        }
    }
// try sending a trace straight
    VectorCopy(pr_global_struct->v_forward, dir);
    VectorMA(start, 2048, dir, end);
    tr = SV_Move(start, vec3_origin, vec3_origin, end, false, ent);
    if (tr.ent && tr.ent->v.takedamage == DAMAGE_AIM
        && (!teamplay.value || ent->v.team <= 0
            || ent->v.team != tr.ent->v.team)) {
        VectorCopy(pr_global_struct->v_forward, G_VECTOR(OFS_RETURN));
        return;
    }

// try all possible entities
    VectorCopy(dir, bestdir);
    bestdist = sv_aim.value;
    bestent = NULL;

    check = NEXT_EDICT(sv.edicts);
    for (i = 1; i < sv.num_edicts; i++, check = NEXT_EDICT(check)) {
        if (check->v.takedamage != DAMAGE_AIM)
            continue;
        if (check == ent)
            continue;
        if (teamplay.value && ent->v.team > 0
            && ent->v.team == check->v.team)
            continue;           // don't aim at teammate
        for (j = 0; j < 3; j++)
            end[j] = check->v.origin[j]
                + 0.5 * (check->v.mins[j] + check->v.maxs[j]);
        VectorSubtract(end, start, dir);
        VectorNormalize(dir);
        dist = DotProduct(dir, pr_global_struct->v_forward);
        if (dist < bestdist)
            continue;           // to far to turn
        tr = SV_Move(start, vec3_origin, vec3_origin, end, false, ent);
        if (tr.ent == check) {  // can shoot at this one
            bestdist = dist;
            bestent = check;
        }
    }

    if (bestent) {
        VectorSubtract(bestent->v.origin, ent->v.origin, dir);
        dist = DotProduct(dir, pr_global_struct->v_forward);
        VectorScale(pr_global_struct->v_forward, dist, end);
        end[2] = dir[2];
        VectorNormalize(end);
        VectorCopy(end, G_VECTOR(OFS_RETURN));
    } else {
        VectorCopy(bestdir, G_VECTOR(OFS_RETURN));
    }
#endif
}

/*
==============
PF_changeyaw

This was a major timewaster in progs, so it was converted to C
==============
*/
void PF_changeyaw(void)
{
    edict_t *ent;
    float ideal, current, move, speed;

    ent = PROG_TO_EDICT(pr_global_struct->self);
    current = anglemod(ent->v.angles[1]);
    ideal = ent->v.ideal_yaw;
    speed = ent->v.yaw_speed;

    if (current == ideal)
        return;
    move = ideal - current;
    if (ideal > current) {
        if (move >= 180)
            move = move - 360;
    } else {
        if (move <= -180)
            move = move + 360;
    }
    if (move > 0) {
        if (move > speed)
            move = speed;
    } else {
        if (move < -speed)
            move = -speed;
    }

    ent->v.angles[1] = anglemod(current + move);
}

/*
===============================================================================

MESSAGE WRITING

===============================================================================
*/

#define	MSG_BROADCAST	0       // unreliable to all
#define	MSG_ONE			1       // reliable to one (msg_entity)
#define	MSG_ALL			2       // reliable to all
#define	MSG_INIT		3       // write to the init string
#define	MSG_MULTICAST	4       // for multicast()

sizebuf_t *WriteDest(lua_State *L)
{
    int dest;

    dest = luaL_checkinteger(L, 1);

    switch (dest) {
    case MSG_BROADCAST:
        return &sv.datagram;

    case MSG_ONE:
        SV_Error("Shouldn't be at MSG_ONE");

    case MSG_ALL:
        return &sv.reliable_datagram;

    case MSG_INIT:
        if (sv.state != ss_loading)
            PR_RunError
                ("PF_Write_*: MSG_INIT can only be written in spawn functions");
        return &sv.signon;

    case MSG_MULTICAST:
        return &sv.multicast;

    default:
        luaL_error(L, "WriteDest: bad destination");
        break;
    }

    return NULL;
}

static client_t *Write_GetClient(lua_State *L)
{
    int entnum;
    edict_t *ent;

    ent = PROG_TO_EDICT(pr_global_struct->msg_entity);
    entnum = NUM_FOR_EDICT(ent);
    if (entnum < 1 || entnum > MAX_CLIENTS)
        luaL_error(L, "WriteDest: not a client");
    return &svs.clients[entnum - 1];
}


int PF_WriteByte(lua_State *L)
{
    if (luaL_checknumber(L, 1) == MSG_ONE) {
        client_t *cl = Write_GetClient(L);
        ClientReliableCheckBlock(cl, 1);
        ClientReliableWrite_Byte(cl, luaL_checknumber(L, 2));
    } else
        MSG_WriteByte(WriteDest(L), luaL_checknumber(L, 2));

    return 0;
}
#if 0
void PF_WriteChar(void)
{
    if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
        client_t *cl = Write_GetClient();
        ClientReliableCheckBlock(cl, 1);
        ClientReliableWrite_Char(cl, G_FLOAT(OFS_PARM1));
    } else
        MSG_WriteChar(WriteDest(), G_FLOAT(OFS_PARM1));
}

void PF_WriteShort(void)
{
    if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
        client_t *cl = Write_GetClient();
        ClientReliableCheckBlock(cl, 2);
        ClientReliableWrite_Short(cl, G_FLOAT(OFS_PARM1));
    } else
        MSG_WriteShort(WriteDest(), G_FLOAT(OFS_PARM1));
}

void PF_WriteLong(void)
{
    if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
        client_t *cl = Write_GetClient();
        ClientReliableCheckBlock(cl, 4);
        ClientReliableWrite_Long(cl, G_FLOAT(OFS_PARM1));
    } else
        MSG_WriteLong(WriteDest(), G_FLOAT(OFS_PARM1));
}

void PF_WriteAngle(void)
{
    if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
        client_t *cl = Write_GetClient();
        ClientReliableCheckBlock(cl, 1);
        ClientReliableWrite_Angle(cl, G_FLOAT(OFS_PARM1));
    } else
        MSG_WriteAngle(WriteDest(), G_FLOAT(OFS_PARM1));
}
#endif

int PF_WriteCoord(lua_State *L)
{
    if (luaL_checknumber(L, 1) == MSG_ONE) {
        client_t *cl = Write_GetClient(L);
        ClientReliableCheckBlock(cl, 2);
        ClientReliableWrite_Coord(cl, luaL_checknumber(L, 2));
    } else
        MSG_WriteCoord(WriteDest(L), luaL_checknumber(L, 2));

    return 0;
}

#if 0
void PF_WriteString(void)
{
    if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
        client_t *cl = Write_GetClient();
        ClientReliableCheckBlock(cl, 1 + strlen(G_STRING(OFS_PARM1)));
        ClientReliableWrite_String(cl, G_STRING(OFS_PARM1));
    } else
        MSG_WriteString(WriteDest(), G_STRING(OFS_PARM1));
}


void PF_WriteEntity(void)
{
    if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
        client_t *cl = Write_GetClient();
        ClientReliableCheckBlock(cl, 2);
        ClientReliableWrite_Short(cl, G_EDICTNUM(OFS_PARM1));
    } else
        MSG_WriteShort(WriteDest(), G_EDICTNUM(OFS_PARM1));
}
#endif

//=============================================================================

int SV_ModelIndex(char *name);

int PF_makestatic(lua_State *L)
{
    edict_t **ent;
    int i;

    ent = luaL_checkudata(L, 1, "edict_t");

    MSG_WriteByte(&sv.signon, svc_spawnstatic);

    MSG_WriteByte(&sv.signon, SV_ModelIndex(PR_GetString((*ent)->v.model)));

    MSG_WriteByte(&sv.signon, (*ent)->v.frame);
    MSG_WriteByte(&sv.signon, (*ent)->v.colormap);
    MSG_WriteByte(&sv.signon, (*ent)->v.skin);
    for (i = 0; i < 3; i++) {
        MSG_WriteCoord(&sv.signon, (*ent)->v.origin[i]);
        MSG_WriteAngle(&sv.signon, (*ent)->v.angles[i]);
    }

    // throw the entity away now
    ED_Free(*ent);
    return 0;
}

//=============================================================================

/*
==============
PF_setspawnparms
==============
*/
void PF_setspawnparms(void)
{
    edict_t *ent;
    int i;
    client_t *client;

    ent = G_EDICT(OFS_PARM0);
    i = NUM_FOR_EDICT(ent);
    if (i < 1 || i > MAX_CLIENTS)
        PR_RunError("Entity is not a client");

    // copy spawn parms out of the client_t
    client = svs.clients + (i - 1);

    for (i = 0; i < NUM_SPAWN_PARMS; i++)
        (&pr_global_struct->parm1)[i] = client->spawn_parms[i];
}

/*
==============
PF_changelevel
==============
*/
void PF_changelevel(void)
{
    char *s;
    static int last_spawncount;

// make sure we don't issue two changelevels
    if (svs.spawncount == last_spawncount)
        return;
    last_spawncount = svs.spawncount;

    s = G_STRING(OFS_PARM0);
    Cbuf_AddText(va("map %s\n", s));
}


/*
==============
PF_logfrag

logfrag (killer, killee)
==============
*/
void PF_logfrag(void)
{
    edict_t *ent1, *ent2;
    int e1, e2;
    char *s;

    ent1 = G_EDICT(OFS_PARM0);
    ent2 = G_EDICT(OFS_PARM1);

    e1 = NUM_FOR_EDICT(ent1);
    e2 = NUM_FOR_EDICT(ent2);

    if (e1 < 1 || e1 > MAX_CLIENTS || e2 < 1 || e2 > MAX_CLIENTS)
        return;

    s = va("\\%s\\%s\\\n", svs.clients[e1 - 1].name,
           svs.clients[e2 - 1].name);

    SZ_Print(&svs.log[svs.logsequence & 1], s);
    if (sv_fraglogfile) {
        fprintf(sv_fraglogfile, s);
        fflush(sv_fraglogfile);
    }
}


/*
==============
PF_infokey

string(entity e, string key) infokey
==============
*/
void PF_infokey(void)
{
    edict_t *e;
    int e1;
    char *value;
    char *key;
    static char ov[256];

    e = G_EDICT(OFS_PARM0);
    e1 = NUM_FOR_EDICT(e);
    key = G_STRING(OFS_PARM1);

    if (e1 == 0) {
        if ((value = Info_ValueForKey(svs.info, key)) == NULL || !*value)
            value = Info_ValueForKey(localinfo, key);
    } else if (e1 <= MAX_CLIENTS) {
        if (!strcmp(key, "ip"))
            value =
                strcpy(ov,
                       NET_BaseAdrToString(svs.clients[e1 - 1].netchan.
                                           remote_address));
        else if (!strcmp(key, "ping")) {
            int ping = SV_CalcPing(&svs.clients[e1 - 1]);
            sprintf(ov, "%d", ping);
            value = ov;
        } else
            value = Info_ValueForKey(svs.clients[e1 - 1].userinfo, key);
    } else
        value = "";

    RETURN_STRING(value);
}

/*
==============
PF_stof

float(string s) stof
==============
*/
void PF_stof(void)
{
    char *s;

    s = G_STRING(OFS_PARM0);

    G_FLOAT(OFS_RETURN) = atof(s);
}


/*
==============
PF_multicast

void(vector where, float set) multicast
==============
*/
int PF_multicast(lua_State *L)
{
    vec_t *o;
    int to;

    o = luaL_checkudata(L, 1, "vec3_t");
    to = luaL_checknumber(L, 2);

    SV_Multicast(o, to);
    return 0;
}


void PF_Fixme(void)
{
    PR_RunError("unimplemented bulitin");
}


int PF_vec3(lua_State *L)
{
    vec_t *v;

    if (lua_gettop(L) != 3)
        luaL_error(L, "vec3() requires 3 args");

    v = PR_Vec3_New(L);

    v[0] = lua_tonumber(L, 1);
    v[1] = lua_tonumber(L, 2);
    v[2] = lua_tonumber(L, 3);

    return 1;
}

void PR_InstallBuiltins(void)
{
    lua_register(L, "dprint", PF_dprint);
    lua_register(L, "precache_model", PF_precache_model);
    lua_register(L, "precache_model2", PF_precache_model);
    lua_register(L, "find", PF_Find);
    lua_register(L, "setmodel", PF_setmodel);
    lua_register(L, "setsize", PF_setsize);
    lua_register(L, "remove", PF_Remove);
    lua_register(L, "precache_sound", PF_precache_sound);
    lua_register(L, "precache_sound2", PF_precache_sound);
    lua_register(L, "ambientsound", PF_ambientsound);
    lua_register(L, "makestatic", PF_makestatic);
    lua_register(L, "random", PF_random);
    lua_register(L, "spawn", PF_Spawn);
    lua_register(L, "setorigin", PF_setorigin);
    lua_register(L, "cvar", PF_cvar);
    lua_register(L, "cvar_set", PF_cvar_set);
    lua_register(L, "lightstyle", PF_lightstyle);
    lua_register(L, "makevectors", PF_makevectors);
    lua_register(L, "objerror", PF_objerror);
    lua_register(L, "centerprint", PF_centerprint);
    lua_register(L, "sound", PF_sound);
    lua_register(L, "WriteByte", PF_WriteByte);
    lua_register(L, "WriteCoord", PF_WriteCoord);
    lua_register(L, "multicast", PF_multicast);
    lua_register(L, "droptofloor", PF_droptofloor);
    lua_register(L, "fabs", PF_fabs);
    lua_register(L, "normalize", PF_normalize);
    lua_register(L, "vectoangles", PF_vectoangles);
    lua_register(L, "pointcontents", PF_pointcontents);

    // constructor for vec3 data
    lua_register(L, "vec3", PF_vec3);
}
