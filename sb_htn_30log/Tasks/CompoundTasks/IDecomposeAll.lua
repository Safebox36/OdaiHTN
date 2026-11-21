local class = require("sb_htn.Utils.30log")
local ICompoundTask = require("sb_htn.Tasks.CompoundTasks.ICompoundTask")

---@class IDecomposeAll : ICompoundTask
local IDecomposeAll = ICompoundTask:extend("IDecomposeAll")

return IDecomposeAll