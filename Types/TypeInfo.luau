type type_info<ID> = typeof(setmetatable(
    {} :: { type_id: ID },
    {} :: { __index: { _brand: ID } }
))

export type test_a = type_info<"test_a">
export type test_b = type_info<"test_b">

-- construction has to go through a constructor that actually calls setmetatable
local function make<ID>(id: ID): type_info<ID>
    return setmetatable({ type_id = id }, { __index = { _brand = id } })
end

local v  = make("test_a") -- type: type_info<"test_a">
local v2 = make("test_b") -- type: type_info<"test_b">

local bad: test_a = v2    -- ERROR: type_info<"test_b"> is not assignable to type_info<"test_a">
local bad2: test_a = { type_id = "test_a" }  -- ERROR: plain table not assignable

local bad: test_a = v2
print(bad.type_id) -- does the typechecker think this is "test_a" or string?