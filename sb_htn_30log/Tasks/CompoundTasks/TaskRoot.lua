local class = require("sb_htn.Utils.30log")
local Selector = require("sb_htn.Tasks.CompoundTasks.Selector")

---@class TaskRoot : Selector
local TaskRoot = Selector:extend("TaskRoot")

return TaskRoot