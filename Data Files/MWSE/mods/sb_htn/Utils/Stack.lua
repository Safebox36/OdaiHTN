---@class Stack<any>
local Stack = {}

function Stack.new()
    return { first = 0, last = -1 }
end

function Stack:push(value)
    local first = self.first - 1
    self.first = first
    self[first] = value
end

function Stack:pop()
    local last = self.last
    if self.first > last then error("ERROR - STACK IS EMPTY") end
    local value = self[last]
    self[last] = nil
    self.last = last - 1
    return value
end

return Stack
