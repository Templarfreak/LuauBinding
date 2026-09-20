--!strict
local luau = ffi.load("luau.dll")
local luau2 = ffi.load("luau.dll")
local luau_state = luau.luaL_newstate()
local luau_state2 = luau2.luaL_newstate()
print("from luau: " .. tostring(luau_state))



function LuauTest(val: number): number
    local calc: number = 5
    calc += val
    
    return calc
end

function RefinementTest(input: string | number)
    if type(input) == "string" then
        -- Luau should know 'input' is a string here
        print(input:lower())
    else
        -- Luau should know 'input' is a number here
        print("RefinementTest: " .. input + 10)
    end
end