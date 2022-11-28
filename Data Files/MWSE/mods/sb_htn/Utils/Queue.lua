---@class Queue<any>
local Queue = {}

function Queue.new()
    return { first = 0, last = -1 }
end

function Queue:pushFirst(value)
    local first = self.first - 1
    self.first = first
    self[first] = value
end

function Queue:pushLast(value)
    local last = self.last + 1
    self.last = last
    self[last] = value
end

function Queue:popFirst()
    local first = self.first
    if first > self.last then error("ERROR - QUEUE IS EMPTY") end
    local value = self[first]
    self[first] = nil
    self.first = first + 1
    return value
end

function Queue:popLast()
    local last = self.last
    if self.first > last then error("ERROR - QUEUE IS EMPTY") end
    local value = self[last]
    self[last] = nil
    self.last = last - 1
    return value
end

return Queue
