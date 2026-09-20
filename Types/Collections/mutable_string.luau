--!strict
local GenericCollection = require("GenericCollection")
local sparse_array = require("sparse_array")
local slice = require("slice")

type SequentialCollection<T> = GenericCollection.SequentialCollection<T>
type sparse_array<T> = sparse_array.sparse_array<T>
type slice<T> = slice.slice<T>

export type mutable_string = SequentialCollection<string> & {
    get_string: () -> string,
    length: () -> number,
    set_string: (string) -> (),
    to_array: () -> (sparse_array<string>),
    at: (number) -> (string),
    slice: (start: number, finish: number) -> (slice<string>),
    remove: (number) -> (),
    replace: (string, number) -> (),
    insert: (string, number) -> ()
}

local mutable_string = {}

function mutable_string.to_array(str: mutable_string)
    local l: sparse_array<string> = sparse_array.new()

    for i = 1, #str do
        l[i] = str[i]
    end

    return l
end

function mutable_string.insert(str, new_chars: string, ind: number)
    local mstr = str.get_string()
    str.set_string(
        string.sub(mstr, 1, ind - 1)
        .. new_chars
        .. string.sub(mstr, ind)
    )
end

function mutable_string.WrapString(str: string): mutable_string
    local mstr = str

    local inst: mutable_string
    inst = {
        get_string = function(): string return mstr end,
        length = function(): number return #mstr end,
        set_string = function(s) mstr = s end,
        to_array = function(): sparse_array<string> return mutable_string.to_array(inst) end,
        at = function(i: number): string return string.sub(mstr, i, i) end,
        slice = function(start: number, finish: number) return slice.NewSlice(inst, start, finish) end,
        remove = function(ind: number) inst[ind] = "" end,
        replace = function(new_char: string, ind: number) inst[ind] = new_char end,
        insert = function(new_chars: string, ind: number) mutable_string.insert(inst, new_chars, ind) end
    }

    local meta = {
        __index = function(t, k)
            if type(k) == "number" then
                if (k % 1 ~= 0) then
                    error("Index must be an integer.")
                end

                return t.at(k)
            end

            local v = rawget(t, k)
            if (v ~= nil) then
                return v
            end

            error("Invalid key access.")
        end,

        __newindex = function(_, k: number, v: string)
            if (typeof(k) == "number") then
                local mstr = mstr
                mstr = string.sub(mstr, 1, k - 1) .. v .. string.sub(mstr, k + 1)
            end
        end,

        __len = function() return #mstr end
    }

    setmetatable(inst, meta)

    return inst
end

return mutable_string