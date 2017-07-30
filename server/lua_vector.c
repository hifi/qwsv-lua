// lua_edict.c -- vec3_t management

/*
   when pushing a vec3 into stack it will
*/

#include "qwsvdef.h"

typedef struct vec3_wrap_s {
    vec_t *p;
    vec3_t v;
} vec3_wrap_t;

static int PR_Vec3_Eq(lua_State *L)
{
    vec_t *a,*b;

    a = PR_Vec3_ToVec(L, 1);
    b = PR_Vec3_ToVec(L, 2);

    lua_pushboolean(L, a[0] == b[0]
                    && a[1] == b[1]
                    && a[2] == b[2]);

    return 1;
};

static int PR_Vec3_Add(lua_State *L)
{
    vec_t *a,*b,*c;

    a = PR_Vec3_ToVec(L, 1);
    b = PR_Vec3_ToVec(L, 2);
    c = PR_Vec3_New(L);

    VectorAdd(a,b,c);
    
    return 1;
};

static int PR_Vec3_Sub(lua_State *L)
{
    vec_t *a,*b,*c;

    a = PR_Vec3_ToVec(L, 1);
    b = PR_Vec3_ToVec(L, 2);
    c = PR_Vec3_New(L);

    VectorSubtract(a,b,c);
    
    return 1;
};

static int PR_Vec3_Mul(lua_State *L)
{
    vec_t *a,*b;
    float s;

    int i_vec = 1;
    int i_sec = 2; 

    if (!lua_isuserdata(L, 1)) {
        i_vec = 2;
        i_sec = 1;
    }

    a = PR_Vec3_ToVec(L, i_vec);

    if (lua_isuserdata(L, i_sec)) {
        b = PR_Vec3_ToVec(L, i_sec);
        s = a[0] * b[0]
            + a[1] * b[1]
            + a[2] * b[2];
        lua_pushnumber(L, s);
    } else {
        b = PR_Vec3_New(L);
        s = luaL_checknumber(L, i_sec);
        VectorScale(a,s,b);
    }

    return 1;
};

static int PR_Vec3_ToString(lua_State *L)
{
    vec_t *a;
    char buf[32];

    a = PR_Vec3_ToVec(L, 1);

    sprintf(buf, "%.1f %.1f %.1f", a[0], a[1], a[2]);

    lua_pushstring(L, buf);
    return 1;
};

static int PR_Vec3_Len(lua_State *L)
{
    vec_t *value1;
    float new;

    value1 = PR_Vec3_ToVec(L, 1);

    new =
        value1[0] * value1[0] + value1[1] * value1[1] +
        value1[2] * value1[2];
    new = sqrt(new);

    lua_pushnumber(L, new);
    return 1;
}

static int PR_Vec3_Index(lua_State *L)
{
    vec_t *v;
    const char *key;

    v = PR_Vec3_ToVec(L, 1);
    key = luaL_checkstring(L, 2);

    switch(key[0])
    {
        case 'x': lua_pushnumber(L, v[0]); break;
        case 'y': lua_pushnumber(L, v[1]); break;
        case 'z': lua_pushnumber(L, v[2]); break;
        default: luaL_error(L, "vec3_t can only have x/y/x");
    }

    return 1;
}

static int PR_Vec3_NewIndex(lua_State *L)
{
    vec_t *v;
    const char *key;
    float value;

    v = PR_Vec3_ToVec(L, 1);
    key = luaL_checkstring(L, 2);
    value = luaL_checknumber(L, 3);

    switch(key[0])
    {
        case 'x': v[0] = value; break;
        case 'y': v[1] = value; break;
        case 'z': v[2] = value; break;
        default: luaL_error(L, "vec3_t can only have x/y/x");
    }

    return 0;
}

static const luaL_Reg PR_Vec3_Metatable[] = {
    {"__eq",       PR_Vec3_Eq},
    {"__add",      PR_Vec3_Add},
    {"__sub",      PR_Vec3_Sub},
    {"__mul",      PR_Vec3_Mul},
    {"__tostring", PR_Vec3_ToString},
    {"__len",      PR_Vec3_Len},
    {"__index",    PR_Vec3_Index},
    {"__newindex", PR_Vec3_NewIndex},
    {0, 0}
};

void PR_Vec3_Init(lua_State *L)
{
    luaL_newmetatable(L, "vec3_t");
    luaL_setfuncs(L, PR_Vec3_Metatable, 0);
    lua_pop(L, 1);
}

vec_t* PR_Vec3_New(lua_State *L)
{
    vec3_wrap_t *v;

    v = lua_newuserdata(L, sizeof(*v));
    memset(v, 0, sizeof(*v)); // needed?

    v->p = v->v;

    luaL_getmetatable(L, "vec3_t");
    lua_setmetatable(L, -2);

    return v->v;
}

vec_t* PR_Vec3_ToVec(lua_State *L, int index)
{
    vec_t **v;

    v = luaL_checkudata(L, index, "vec3_t");

    return *v;
}

void PR_Vec3_Push(lua_State *L, vec3_t in)
{
    vec_t **v;

    v = lua_newuserdata(L, sizeof(*v));

    *v = in;

    luaL_getmetatable(L, "vec3_t");
    lua_setmetatable(L, -2);
}
