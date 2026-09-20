--!nocheck
--!nolint
require("InteropLib")
local ffi = require("ffi")
local Luau = require("LuauIntegration.LuauAPI")
local C = ffi.C
local LuauHelpers = {}
local Codebytes = {}

Codebytes.ByFilepath = {}
Codebytes.ByAddress = {}
Codebytes.Sizeof = {}
Codebytes.GetAddress = {}

function LuauHelpers.CompileLuauCode(code)
    local outSize = ffi.new("size_t[1]")
    local bytecode_ptr = Luau.luau_compile(code, #code, nil, outSize)

    if (bytecode_ptr == nil) then
        return nil
    end

    local bt = {}
    bt.ptr = bytecode_ptr
           -- equivalent to a C-style dereference ie *outSize
    bt.size = outSize[0] -- LOVE12 uses LuaJIT2.1, which has integers, which means this is also valid
    -- as long as you're using LOVE12 without worrying about float precision errors
    bt.address = PtrToAddress(bytecode_ptr)
    bt.free = function()
        if bt.ptr ~= nil then
            C.free(bt.ptr)
            bt.ptr = nil
            bt.address = nil
        end
    end

    return bt
end

function LuauHelpers.CompileLuauFile(filepath)
    if (Codebytes.ByFilepath[filepath] ~= nil) then
        return Codebytes.ByFilepath[filepath], Codebytes.GetAddress[filepath]
    end

    local info = love.filesystem.getInfo(filepath)
    if (info == nil) then
        error("Could not find file: " .. filepath  .. "\nLua stacktrace: " .. debug.traceback())
    end

    local source = love.filesystem.read(filepath)
    local bt = LuauHelpers.CompileLuauCode(source)

    if (bt == nil) then
        error("Failed to compile Luau file: " .. filepath  .. "\nLua stacktrace: " .. debug.traceback())
    end

    Codebytes.ByFilepath[filepath] = bt.ptr
    Codebytes.ByAddress[bt.address] = filepath
    Codebytes.Sizeof[bt.address] = bt.size
    Codebytes.GetAddress[filepath] = bt.address
    
    return bt.ptr, bt.address
end

function LuauHelpers.FreeLuauCodeByte(filepath)
    if (Codebytes.ByFilepath[filepath] ~= nil) then
        local bytes = Codebytes.ByFilepath[filepath]
        local address = PtrToAddress(bytes)
        C.free(bytes)
        Codebytes.ByFilepath[filepath] = nil
        Codebytes.ByAddress[address] = nil
        Codebytes.Sizeof[address] = nil
    end
end

function LuauHelpers.PushBytecodeToVM(L, input, chunkname)
    local bytecode = nil
    local chunk_prefix = chunkname or ""
    local display_name = ""
    local size = nil

    if (type(input) == "string") then
        if (Codebytes.ByFilepath[input]) then
            bytecode = Codebytes.ByFilepath[input]
            display_name = chunk_prefix .. "@" .. input
            local address = Codebytes.GetAddress[input]
            size = Codebytes.Sizeof[address]
        elseif (input:sub(-4) == ".lua" or input:sub(-5) == ".luau") then
            local address;
            bytecode, address = LuauHelpers.CompileLuauFile(input)
            size = Codebytes.Sizeof[address]
            display_name = chunk_prefix .. "@" .. input
        else
            bytecode = input
            display_name = chunkname or "@raw_source"
        end
    else
        bytecode = input.ptr
        size = input.size
        local address = input.address
        local filename = Codebytes.ByAddress[address]

        if (filename ~= nil) then
            display_name = chunk_prefix .. "@" .. filename
        else
            display_name = chunk_prefix .. "@" .. string.format("0x%X", address)
        end
    end

    if (bytecode == nil) then
        error("Could not resolve Luau bytecode from input." .. "\nLua stacktrace: " .. debug.traceback())
    end

    local status = Luau.luau_load(L, display_name, bytecode, size, 0)
    
    if (status == 0) then
        local run_status = Luau.lua_pcall(L, 0, 0, 0)
        print(run_status)

        if (run_status ~= 0) then
            local err = "Runtime Error in " .. display_name .. ": " .. ffi.string(Luau.lua_tolstring(L, -1, nil)) .. "\nLua stacktrace: " .. debug.traceback()
            return false, err
        end

        return true
    else
        local err = "Syntax Error in " .. display_name .. ": " .. ffi.string(Luau.lua_tolstring(L, -1, nil)) .. "\nLua stacktrace: " .. debug.traceback()
        return false, err
    end
end

---returns true or false. if false, returns the error that occurred. if true, returns the return values (if any). parameters 
---provided *must* be in the structure of {length = n, values = { ... etc ... }}. 
---this ensures that intentional nils will be pushed, and that values after the nil will never be dropped.
function LuauHelpers.CallGlobalFunctionOnVM(L, func_name, params, returns, err)
    Luau.lua_getglobal(L, func_name)

    if (Luau.lua_isfunction(L, -1) == true) then
        for i = 1, params.length do
            local param = params.values[i]
            local t = type(param)

            if (t == "string") then
                Luau.lua_pushlstring(L, param, #param)
            elseif (t == "number") then
                Luau.lua_pushnumber(L, param)
            elseif (t == "boolean") then
                Luau.lua_pushboolean(L, param and 1 or 0)
            elseif (t == "userdata" or t == "cdata") then
                Luau.lua_pushlightuserdata(L, ffi.cast("void*", param))
            elseif (param == nil) then
                Luau.lua_pushnil(L)
            end
        end

        local status = Luau.lua_pcall(L, params.length, returns, err or 0)

        if (status ~= 0) then
            local err = ffi.string(Luau.lua_tolstring(L, -1, nil))
            Luau.lua_pop(L, 1)
            print("Runtime error in " .. func_name .. ": " .. err  .. "\nLua stacktrace: " .. debug.traceback())
            return false, err
        end

        local results = {}

        if (returns > 0) then
            for i = returns, 1, -1 do
                local stack_idx = -i
                local t = Luau.lua_type(L, stack_idx)
                
                -- Convert C-stack value back to Lua value
                if (t == Luau.LUA_TNUMBER) then -- LUA_TNUMBER
                    results[#results + 1] = Luau.lua_tonumber(L, stack_idx)
                elseif (t == Luau.LUA_TSTRING) then -- LUA_TSTRING
                    results[#results + 1] = ffi.string(Luau.lua_tolstring(L, stack_idx, nil))
                elseif (t == Luau.LUA_TBOOLEAN) then -- LUA_TBOOLEAN
                    results[#results + 1] = (Luau.lua_toboolean(L, stack_idx) ~= 0)
                end
            end

            Luau.lua_pop(L, returns)
        end

        return true, unpack(results)
    else
        Luau.lua_pop(L, 1)
        return false, "Function '" .. func_name .. "' not found in the VM globals."
    end
end

function LuauHelpers.NewVM()
    local L = Luau.luaL_newstate()
    Luau.luaL_openlibs(L)

    return L
end

function LuauHelpers.DestroyVM(L)
    if (L ~= nil) then
        Luau.lua_close(L)
    end
end

return LuauHelpers