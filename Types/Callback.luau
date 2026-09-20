--!strict
local list_table = require("Collections\\list")
type list<T> = list_table.list<T>
local callback = {}

export type callback = {
    name: string,
    func: (...any) -> ...any,
    args: {},
    do_callback: (...any) -> ...any
}

function callback.NewCallback(name, func, ...)
    local new_callback: callback

    new_callback = {
        name = name,
        func = func,
        args = {...},
        do_callback = function() return func(unpack(new_callback.args)) end
    }

    return new_callback
end

function callback.DoTableOfCallbacks(which_callbacks: list<callback>)
    for _, callback in ipairs(which_callbacks) do
        callback.do_callback()
    end
end

return callback