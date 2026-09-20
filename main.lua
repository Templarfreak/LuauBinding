--!nocheck
--!nolint
--local ffi = require("ffi")
require("Backports")
local LuauHelpers = require("LuauIntegration.LuauHelpers")
local LuauBindings = require("LuauIntegration.LuauBindings")()

local function make_call(L, func_name, return_count, ...)
    local params = {values = {...}}
    local param_size = select("#", ...)

    params.length = param_size

    local return_values = table.pack(LuauHelpers.CallGlobalFunctionOnVM(L, func_name, params, return_count))
    local success = return_values[1]
    local err = return_values[2]

    -- removing the success value because that's not actually the Luau function's return value
    -- we just want the return values in the for loop soon
    table.remove(return_values, 1)
    return_values.n = return_values.n - 1

    if (success) then
        if (return_values.n > 0) then
            print("--- Results Harvested ---")
            for i = 1, return_values.n do
                local type_of = type(return_values[i])
                local value = return_values[i]

                if (type(value) == "boolean") then
                    value = value and "true" or "false"
                end

                print("type = " .. type_of .. " value = " .. value)
            end
        else
            print("Success, no return values")
        end
    elseif (err ~= nil) then
        print("Call Failed: " .. err)
    end
end

function love.load()
    print("=== Starting Luau VM Integration Test ===")

    local VM = LuauHelpers.NewVM()
    LuauBindings.register_namespaces(VM, "ffi")
    local file_name = "some_luau.luau"
    print("VM Initialized.")

    local bytecode, address = LuauHelpers.CompileLuauFile(file_name)
    if (bytecode == nil) then
        error("Failed to compile " .. file_name)
    end

    print("Bytecode Compiled. Handle Address:", address)

    local exec_success, exec_err = LuauHelpers.PushBytecodeToVM(VM, file_name)

    if (exec_success == false) then
        error("Execution Error: " .. exec_err)
    end

    print("Bytecode Executed (Globals Defined).")

    make_call(VM, "LuauTest", 1, 5)
    make_call(VM, "RefinementTest", 0, 1)
    make_call(VM, "RefinementTest", 0, "hello")
    make_call(VM, "print", 0, "hello! executing on Luau VM from Lua code!")

    LuauHelpers.FreeLuauCodeByte(file_name)
    print("Bytecode freed from registry.")
    LuauHelpers.DestroyVM(VM)
    
    print("=== Test Complete ===")
    love.event.quit()
end