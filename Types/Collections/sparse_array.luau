--!strict
local GenericCollection = require("GenericCollection")
type GenericCollection<T> = GenericCollection.GenericCollection<T>

export type sparse_array<T> = GenericCollection<T> & {
    [number]: T | nil
}

local sparse_array = {}

function sparse_array.new<T>(): sparse_array<T>
    local arr: {[number]: T?} = {}
    local highest_index = 0

    local front: sparse_array<T> = {
        length = function() return highest_index end
    }

    local meta = {
        __newindex = function(t, n: number, v: T?)
            if (type(n) ~= "number" or n % 1 ~= 0) then
                error("Non-integer access not allowed on arrays.")
            end

            arr[n] = v

            if (n == highest_index and v == nil) then
                local i = n - 1

                while (i > 0 and arr[i] == nil) do
                    i -= 1
                end

                highest_index = i
            elseif (v ~= nil and n > highest_index) then
                highest_index = n
            end
        end,

        __index = function(t, n: number)
            return arr[n]
        end,

        __len = function() error("Length operator does not give consistent results for arrays with holes. Use length method instead.") end
    }

    setmetatable(front, meta)

    return front
end

return sparse_array