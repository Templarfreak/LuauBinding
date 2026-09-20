--!nocheck
--!nolint
local ffi = require("ffi")
local _LuauLib = ffi.load("luau.dll")
local C = ffi.C

local Luau = {}

setmetatable(Luau, {
    __index = _LuauLib
})

ffi.cdef[[
    // C
    void free(void* ptr);

    enum {
        LUA_REGISTRYINDEX = -10000,
        LUA_ENVIRONINDEX  = -10001,
        LUA_GLOBALSINDEX  = -10002
    };

    //Consts
    enum
    {
        LUA_TNIL = 0,     // must be 0 due to lua_isnoneornil
        LUA_TBOOLEAN = 1, // must be 1 due to l_isfalse

        LUA_TLIGHTUSERDATA,
        LUA_TNUMBER,
        LUA_TINTEGER,
        LUA_TVECTOR,

        LUA_TSTRING, // all types above this must be value types, all types below this must be GC types - see iscollectable

        LUA_TTABLE,
        LUA_TFUNCTION,
        LUA_TUSERDATA,
        LUA_TTHREAD,
        LUA_TBUFFER,

        // values below this line are used in GCObject tags but may never show up in TValue type tags
        LUA_TPROTO,
        LUA_TUPVAL,
        LUA_TDEADKEY,

        // the count of TValue type tags
        LUA_T_COUNT = LUA_TPROTO
    };

    // Types
    typedef double lua_Number;
    typedef ptrdiff_t lua_Integer;
    typedef struct lua_State lua_State;
    typedef unsigned long size_t;
    typedef long long int64_t;
    typedef int (*lua_CFunction)(lua_State* L);
    typedef int (*lua_Continuation)(lua_State* L, int status);

    // Core VM Management
    lua_State* luaL_newstate(void);
    void luaL_openlibs(lua_State* L);
    void lua_close(lua_State* L);
    void lua_setfenv(lua_State* L, int idx);

    // Execution & Stack Control
    int lua_pcall(lua_State* L, int nargs, int nresults, int errfunc);
    int lua_getfield(lua_State* L, int objindex, const char* k);
    void lua_settop(lua_State* L, int idx);
    int lua_gettop (lua_State *L);
    int lua_type(lua_State* L, int idx);
    void lua_remove(lua_State* L, int idx);
    int lua_resume(lua_State* L, lua_State* from, int narg);
    void lua_xmove(lua_State* from, lua_State* to, int n);
    void lua_pushcclosurek(lua_State* L, lua_CFunction fn, const char* debugname, int nup, lua_Continuation cont);

    // Luau Sandboxing (Required for your NewVM logic)
    void luaL_sandbox(lua_State* L);
    void luaL_sandboxthread(lua_State* L);
    lua_State* lua_newthread(lua_State* L);

    // Compilation & Loading
    char* luau_compile(const char* source, size_t sourceSize, void* options, size_t* outSize);
    int luau_load(lua_State* L, const char* chunkname, const char* data, size_t size, int env);

    // Data Retrieval (lua_to*)
    const char* lua_tolstring(lua_State* L, int idx, size_t* len);
    int lua_toboolean(lua_State *L, int idx);
    double lua_tonumberx(lua_State* L, int idx, int* isnum);
    void* lua_touserdata(lua_State *L, int idx);
    int lua_type(lua_State* L, int idx);
    void lua_gettable (lua_State *L, int idx);
    const char* luaL_checklstring(lua_State* L, int numArg, size_t* l);
    int lua_tointegerx(lua_State* L, int idx, int* isnum);

    // Data Input (lua_push*)
    void lua_pushnil(lua_State *L);
    void lua_pushnumber(lua_State *L, lua_Number n);
    void lua_pushboolean(lua_State *L, int b);
    void lua_pushlstring(lua_State *L, const char *s, size_t l);
    void lua_pushlightuserdata(lua_State *L, void* p);
    void lua_pushvalue(lua_State *L, int idx);
    void lua_pushstring (lua_State *L, const char *s);
    void lua_pushinteger(lua_State* L, long long n);

    // Tables
    void lua_createtable(lua_State* L, int narr, int nrec);
    int lua_setmetatable(lua_State* L, int objindex);
    void lua_setglobal(lua_State* L, const char* name);
    void lua_setfield(lua_State* L, int idx, const char* k);
    void lua_settable(lua_State* L, int idx);

    // Ref
    int lua_ref(lua_State* L, int idx);
    void lua_unref(lua_State* L, int ref);

    // Debugging
    void luaL_where(lua_State *L, int lvl);
]]

Luau.lua_getglobal = function(L, name)
    return Luau.lua_getfield(L, Luau.LUA_GLOBALSINDEX, name)
end

Luau.lua_isfunction = function(L, idx)
    return Luau.lua_type(L, idx) == Luau.LUA_TFUNCTION
end

Luau.lua_pop = function(L, n)
    Luau.lua_settop(L, -n - 1)
end

Luau.lua_tonumber = function(L, i)
    return Luau.lua_tonumberx(L, i, nil)
end

Luau.luaL_checkstring = function(L, n)
    return Luau.luaL_checklstring(L, n, nil)
end

Luau.lua_newtable = function(L)
    Luau.lua_createtable(L, 0, 0)
end

Luau.lua_pushcclosure = function(L, fn, debugname, nup)
    Luau.lua_pushcclosurek(L, fn, debugname, nup, nil)
end

Luau.lua_setglobal = function(L, s)
    Luau.lua_setfield(L, Luau.LUA_GLOBALSINDEX, s)
end

Luau.lua_tointeger = function(L, i)
    return Luau.lua_tointegerx(L, i, nil)
end

Luau.lua_isnil = function(L, idx)
    return Luau.lua_type(L, idx) == Luau.LUA_TNIL
end

return Luau