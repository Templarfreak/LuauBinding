--!strict
local GenericCollection = require("GenericCollection")
type SequentialCollection<T> = GenericCollection.SequentialCollection<T>

export type slice<T> = {
    inst: SequentialCollection<T>,
    inst_start: number,
    inst_end: number,
    iter: (self: slice<T>) -> (any, any, number)
}

local slice = {}

local function slice_next<T>(s: slice<T>, index: number): number?
    index += 1
    if (index <= s.inst_end) then
        return index, s.inst[index]
    end

    return nil
end

function slice.NewSlice<T>(inst: SequentialCollection<T>, inst_start: number, inst_end: number)
    local slice: slice<T> 
    slice = {
        inst = inst,
        inst_start = inst_start,
        inst_end = inst_end,

        iter = function()
            return slice_next, slice, slice.inst_start - 1
        end
    }

    return slice
end

return slice