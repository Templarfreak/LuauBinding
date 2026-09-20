--!strict
local collections = require("../Collections/list")
type list<T> = collections.list<T>

export type node<T> = {
    element: T,
    next: node<T>?,
    previous: node<T>?,
    sort_num: number,

    -- methods
    add: (T) -> (node<T>),
    link: (node<T>) -> (),
    unlink: () -> (T),
    get_head: () -> (node<T>),
    get_tail: () -> (node<T>),
    sort: (boolean) -> (node<T>)
}

--doubly-linked specifically
local LinkedList = {}

local LastSortNum = 0

function LinkedList.GetHead<T>(node: node<T>)
    local current = node
    
    while (current.previous) do
        current = current.previous :: node<T>
    end

    return current
end

function LinkedList.GetTail<T>(node: node<T>)
    local current = node
    
    while (current.next) do
        current = current.next :: node<T>
    end

    return current
end

function LinkedList.Add<T>(node: node<T>, new_obj: T)
    local new_node = LinkedList.New(new_obj)
    new_node.previous = node
    new_node.next = node.next

    if (node.next) then
        node.next.previous = new_node
    end

    node.next = new_node

    return new_node
end

function LinkedList.Link<T>(node: node<T>, linkto: node<T>)
    if node.previous or node.next then
        LinkedList.Unlink(node)
    end

    if linkto.next then
        node.next = linkto.next
        linkto.next.previous = node
    end

    linkto.next = node
    node.previous = linkto
end

function LinkedList.Unlink<T>(node: node<T>): T
    local val = node.element

    if (node.previous) then
        node.previous.next = node.next
    end

    if (node.next) then
        node.next.previous = node.previous
    end

    node.previous = nil
    node.next = nil

    return val
end

--radix sort
function LinkedList.Sort<T>(node: node<T>, ascending: boolean): node<T>
    local node_list: {[number]: node<T>} = {}
    local max_val = 0
    local total_count = 0
    local start = LinkedList.GetHead(node)
    local searched_node: node<T>? = start

    while (searched_node ~= nil) do
        total_count += 1
        node_list[total_count] = searched_node
        
        if (searched_node.sort_num > max_val) then
            max_val = searched_node.sort_num
        end
        
        searched_node = searched_node.next
    end

    local biggest_digit = if max_val == 0 then 1 else math.floor(math.log10(max_val)) + 1
    
    local digit_lists: {{node<T>}} = {}
    for i = 0, 9 do
        digit_lists[i] = {}
    end

    for i = 1, biggest_digit do
        local power_of_10 = 10 ^ (i - 1)
        
        for _, n in ipairs(node_list) do
            local digit = math.floor(n.sort_num / power_of_10) % 10
            table.insert(digit_lists[digit], n)
        end

        table.clear(node_list)
        
        local from, to, step = 0, 9, 1
        if (ascending == false) then
            from, to, step = 9, 0, -1
        end

        for j = from, to, step do
            for _, n in ipairs(digit_lists[j]) do
                table.insert(node_list, n)
            end
            table.clear(digit_lists[j])
        end
    end

    node_list[1].previous = nil
    node_list[#node_list].next = nil
    
    for i = 1, #node_list do
        local curr = node_list[i]

        curr.next = node_list[i + 1]
        curr.previous = node_list[i - 1]
    end
    
    return node_list[1]
end

function LinkedList.New<T>(obj: T, sort_num: number?): node<T>
    local final_num: number

    if (sort_num == nil) then
        final_num = LastSortNum
        LastSortNum = LastSortNum + 1
    else
        final_num = sort_num
    end

    local node: node<T> 
    node = {
        element = obj,
        sort_num = final_num,
        next = nil,
        previous = nil,

        --methods
        add = function(new_obj: T) return LinkedList.Add(node, new_obj) end,
        link = function(linkto: node<T>) LinkedList.Link(node, linkto) end,
        unlink = function(): T return LinkedList.Unlink(node) end,
        get_head = function(): node<T> return LinkedList.GetHead(node) end,
        get_tail = function(): node<T> return LinkedList.GetTail(node) end,
        sort = function(ascending: boolean): node<T> return LinkedList.Sort(node, ascending) end
    }

    return node
end

return LinkedList