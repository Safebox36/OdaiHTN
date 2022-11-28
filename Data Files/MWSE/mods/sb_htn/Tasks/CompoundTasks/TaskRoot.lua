local Selector = require("CompoundTasks.Selector")

---@class TaskRoot : Selector
local TaskRoot = {}

function TaskRoot.new()
    return Selector.new()
end

return TaskRoot
