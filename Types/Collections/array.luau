--!strict
local GenericCollection = require("GenericCollection")

type SequentialCollection<T> = GenericCollection.SequentialCollection<T>

export type array<T> = SequentialCollection<T> & {
    push: (T) -> (),
    pop: () -> (),
    resize: (number) -> ()
}

local array = {}

local function array_new_core<T>(size: number, provider: (number) -> T): array<T>
    local data: {[number]: T} = {}
    local len: number = size

    for i = 1, size do
        data[i] = provider(i)
    end

    local arr: array<T>
    arr = {
        push = function(val: T)
            len += 1
            data[len] = val
        end,

        pop = function()
            data[len] = nil
            len -= 1
        end,

        resize = function(new_size: number)
            if (new_size < len) then
                for i = len, new_size + 1, -1 do
                    data[i] = nil
                end
            elseif (new_size > len) then
                for i = len + 1, new_size do
                    data[i] = provider(i)
                end
            end

            len = new_size
        end,

        length = function(): number
            return len
        end
    }

    setmetatable(arr, {
        __index = function(_, i)
            return data[i]
        end,

        __newindex = function(_, i, v)
            if i <= len then
                data[i] = v
            else
                error("Array index out of range.")
            end
        end
    })

    return arr
end

function array.fill_new<T>(size: number, default_value: T): array<T>
    return array_new_core(size, function(index: number)
        return default_value
    end)
end

function array.init_new<T>(size: number, factory: (number) -> T): array<T>
    return array_new_core(size, function(index: number)
        return factory(index)
    end)
end

return array