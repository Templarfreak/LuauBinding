--!nocheck
--!nolint
local ffi = require("ffi")

function PtrToAddress(ptr)
    local address = tonumber(ffi.cast("uintptr_t", ptr))
    return address
end