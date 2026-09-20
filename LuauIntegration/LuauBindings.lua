--!nocheck
--!nolint
require("InteropLib")
require("Backports")
local LuauAPI = require("LuauIntegration.LuauAPI")
local ffi = require("ffi")

local lua_cfunc = ffi.typeof("lua_CFunction")
local voidptr = ffi.typeof("void *")

local Lifetime = {
    cfuncs = {},
    libs = {by_name = {}, by_handle = {}},
    objects = {},
}

Lifetime.register_lib = function(name, handle, new_entry)
        Lifetime.libs.by_name[name] = new_entry
        Lifetime.libs.by_handle[handle] = new_entry
end

Lifetime.remove_lib = function(entry)
    Lifetime.libs.by_name[entry.name] = nil
    Lifetime.libs.by_handle[entry.handle] = nil
end

local function create_handles()
    local store = {}
    local next_id = 1

    local handles = {}

    function handles.create(obj)
        local id = next_id
        next_id = id + 1
        store[id] = obj
        return id
    end

    function handles.get(id)
        return store[id]
    end

    function handles.delete(id)
        store[id] = nil
    end

    function handles.iter()
        return pairs(store)
    end

    function handles.exists(id)
        return store[id] ~= nil
    end

    return handles
end

local Handles = create_handles()

--- direct management of libraries to be injected into Luau VMs
local NamespaceManager = {
    Registry = {}
}

Lifetime.anchor_cfunc = function(cfunc)
    table.insert(Lifetime.cfuncs, cfunc)
    return cfunc
end

local function new_cfunc(func)
    local cfunc = ffi.cast(lua_cfunc, func)
    return Lifetime.anchor_cfunc(cfunc)
end

local function register_table(L, name, tbl)
    LuauAPI.lua_newtable(L)

    for key, cfunc in pairs(tbl) do
        if (cfunc ~= nil and ffi.istype(lua_cfunc, cfunc)) then
            LuauAPI.lua_pushcclosure(L, cfunc, nil, 0)
            LuauAPI.lua_setfield(L, -2, key)
        else
            error("Invalid lua_CFunction. Either nil or not actually of the type.")
        end
    end

    LuauAPI.lua_setglobal(L, name)
end

local function push_handle(L, handle)
    LuauAPI.lua_pushinteger(L, handle)
    LuauAPI.lua_setfield(L, -2, "__handle")
end

local function get_handle_obj(L, index)
    LuauAPI.lua_getfield(L, index, "__handle")
    local id = LuauAPI.lua_tointeger(L, -1)
    local obj = Handles.get(id)

    if (obj == nil) then
        error("Invalid or expired handle: " .. tostring(id))
    end
    
    LuauAPI.lua_pop(L, 1)
    return Handles.get(id)
end

local function get_handle(L, index)
    LuauAPI.lua_getfield(L, index, "__handle")

    if (LuauAPI.lua_isnil(L, -1)) then
        LuauAPI.lua_pop(L, 1)
        error("Expected handle-bearing object")
    end

    local id = LuauAPI.lua_tointeger(L, -1)
    LuauAPI.lua_pop(L, 1)
    return id
end

local function resolve_symbol(lib, symbol)
    return lib[symbol]
end

local ffi_load_index_func = new_cfunc(function(L)
    local handle = get_handle(L, 1)
    local lib = Lifetime.libs.by_handle[handle]
    local symbol = ffi.string(LuauAPI.luaL_checkstring(L, 2))

    if (lib and lib.cfuncs[symbol]) then
        print("returning cached function")
        local cfunc = lib.cfuncs[symbol]

        LuauAPI.lua_pushcclosure(L, cfunc, 0)

        LuauAPI.lua_pushvalue(L, 2)
        LuauAPI.lua_pushvalue(L, -2)
        LuauAPI.lua_settable(L, 1)

        return 1
    end

    if (lib == nil or lib.lib == nil) then
        LuauAPI.lua_pushnil(L)
        return 1
    end

    local sym = lib.lib[symbol]

    if (sym == nil) then
        LuauAPI.lua_pushnil(L)
        return 1
    end

    print("making function")

    local fn = new_cfunc(function(L)
        local argc = LuauAPI.lua_gettop(L)
        local args = {}

        for i = 1, argc do
            local t = LuauAPI.lua_type(L, i)

            if (t == LuauAPI.LUA_TNUMBER) then
                args[i] = LuauAPI.lua_tonumber(L, i)
            elseif (t == LuauAPI.LUA_TSTRING) then
                args[i] = ffi.string(LuauAPI.luaL_checkstring(L, i))
            elseif (t == LuauAPI.LUA_TBOOLEAN) then
                args[i] = LuauAPI.lua_toboolean(L, i)
            elseif (t == LuauAPI.LUA_TNIL) then
                args[i] = nil
            elseif (t == LuauAPI.LUA_TTABLE) then
                LuauAPI.lua_getfield(L, i, "__handle")
                if (LuauAPI.lua_isnil(L, -1) == nil) then
                    local hid = LuauAPI.lua_tointeger(L, -1)
                    LuauAPI.lua_pop(L, 1)

                    local obj = Lifetime.objects[hid]
                    if (obj == nil) then
                        error("Invalid handle passed as argument")
                    end

                    args[i] = obj
                else
                    LuauAPI.lua_pop(L, 1)
                    error("Unsupported table argument (no __handle)")
                end
            else
                error("Unsupported argument type")
            end
        end

        local results = table.pack(sym(unpack(args)))

        for i = 1, results.n do
            local result = results[i]

            if (type(result) == "number") then
                LuauAPI.lua_pushnumber(L, result)
            elseif (type(result) == "string") then
                LuauAPI.lua_pushlstring(L, result, #result)
            elseif (type(result) == "boolean") then
                LuauAPI.lua_pushboolean(L, result)
            elseif (result == nil) then
                LuauAPI.lua_pushnil(L)
            elseif (ffi.istype(voidptr, result)) then
                local handle = Handles.create(result)

                LuauAPI.lua_newtable(L)
                LuauAPI.lua_pushinteger(L, handle)
                LuauAPI.lua_setfield(L, -2, "__handle")
                Lifetime.objects[handle] = result
            end
        end

        return results.n
    end)

    if (lib.cfuncs[symbol] == nil) then
        lib.cfuncs[symbol] = fn
    end

    LuauAPI.lua_pushcclosure(L, fn, nil, 0)

    LuauAPI.lua_pushvalue(L, 2)
    LuauAPI.lua_pushvalue(L, -2)
    LuauAPI.lua_settable(L, 1)

    return 1
end)

NamespaceManager.define_namespace = function(name, def)
    NamespaceManager.Registry[name] = def()
end

NamespaceManager.install_namespace = function(L, name)
    local tbl = NamespaceManager.Registry[name]
    if (tbl ~= nil) then
        register_table(L, name, tbl)
    else
        error(string.format("Namespace '%s' not defined", name))
    end
end

NamespaceManager.define_namespace("ffi", function()
    return {
        cdef = new_cfunc(function(L)
            local def = ffi.string(LuauAPI.luaL_checkstring(L, 1))
            ffi.cdef(def)

            return 0
        end),

        load = new_cfunc(function(L)
            local name = ffi.string(LuauAPI.luaL_checkstring(L, 1))
            local which_entry = Lifetime.libs.by_name[name]
            local handle = nil

            if (which_entry) then
                handle = which_entry.handle
            else
                local raw = ffi.load(name)
                handle = Handles.create(raw)
                local new_entry = {cfuncs = {}, lib = raw, handle = handle, name = name}
                Lifetime.register_lib(name, handle, new_entry)
            end

            LuauAPI.lua_newtable(L)
            push_handle(L, handle)
            LuauAPI.lua_newtable(L)
            LuauAPI.lua_pushcclosure(L, ffi_load_index_func, nil, 0)
            LuauAPI.lua_setfield(L, -2, "__index")
            LuauAPI.lua_setmetatable(L, -2)

            return 1
        end)
    }
end)

local LuauBindings = {}

LuauBindings.register_namespaces = function(L, ...)
    local which_namespaces = table.pack(...)

    for i = 1, which_namespaces.n do
        NamespaceManager.install_namespace(L, which_namespaces[i])
    end
end

return function() return LuauBindings, NamespaceManager end