--!strict
local list_table = require("../Collections/list")
type list<T> = list_table.list<T>

local stack = {}

export type stack<T> = {
    elements: list<T>,
    top: (stack<T>) -> (T?),
    pop: (stack<T>) -> (T?),
    push: (T) -> (),
    is_empty: (stack<T>) -> (boolean)
}

function stack.IsEmpty<T>(stack_inst: stack<T>): boolean
    if (#stack_inst.elements == 0) then
        return true
    end
    
    return false
end

function stack.Top<T>(stack_inst: stack<T>): T?
    if (stack.IsEmpty(stack_inst)) then
        return nil
    end

    return stack_inst[#stack_inst.elements]
end

function stack.Pop<T>(stack_inst: stack<T>): T?
    if (stack.IsEmpty(stack_inst) == true) then
        return nil
    end

    local v = stack.Top(stack_inst)
    table.remove(stack_inst.elements)

    return v
end

function stack.Push<T>(stack_inst: stack<T>, obj: T)
    table.insert(stack_inst.elements, obj)
end

function stack.NewStack<T>(): stack<T>
    local stack_inst: stack<T>
    stack_inst = {
        elements = list_table.new(),
        top = function(): T? return stack.Top(stack_inst) end,
        pop = function(): T? return stack.Pop(stack_inst) end,
        push = function(obj) stack.Push(stack_inst, obj) end,
        is_empty = function(): boolean return stack.IsEmpty(stack_inst) end
    }

    return stack_inst
end

return stack