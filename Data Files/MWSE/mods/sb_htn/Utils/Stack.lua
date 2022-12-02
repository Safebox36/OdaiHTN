local mc = require("sb_htn.Utils.middleclass")

---@class Stack<any>
local Stack = mc.class("Stack")

Stack.first = 0
Stack.last = -1

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
