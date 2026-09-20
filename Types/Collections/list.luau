--!strict
require("../../Backports")
local GenericCollection = require("GenericCollection")

type SequentialCollection<T> = GenericCollection.SequentialCollection<T>

-- guaranteed no holes
export type list<T> = SequentialCollection<T> & {
    add: (T) -> (),
    remove: (number) -> (),
}

local list = {}

function list.new<T>(...): list<T>
    local inst: list<T>
    local optional_init = table.pack(...)

    inst = {
        add = function(what: T)
            table.insert(inst, what)
        end,

        remove = function(index: number)
            table.remove(inst, index)
        end,

        length = function(): number
            return #inst
        end
    }

    if (optional_init.n > 0) then
        for _, v in pairs(optional_init) do
            inst.add(v)
        end
    end

    return inst
end

return list