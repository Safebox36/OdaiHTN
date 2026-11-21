local class = require("sb_htn.Utils.30log")

---@class Stack<any>
local Stack = class("Stack")

function Stack:init()
    self.list = {}
end

function Stack:push(item)
    self.list[table.size(self.list) + 1] = item
end

function Stack:pop()
    if table.size(self.list) > 0 then
        return table.remove(self.list, table.size(self.list))
    end
end

function Stack:peek()
    return self.list[table.size(self.list)]
end

function Stack:clear()
    self.list = {}
end

function Stack:copy(s)
    self.list = s.list
end

return Stack