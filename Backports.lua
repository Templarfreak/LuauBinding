table.pack = table.pack or function(...)
    return { n = select("#", ...), ... }
end

return true