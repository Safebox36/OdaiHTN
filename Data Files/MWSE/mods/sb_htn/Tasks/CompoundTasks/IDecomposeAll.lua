local ICompoundTask = require("CompoundTasks.ICompoundTask")

---@class IDecomposeAll : ICompoundTask
local IDecomposeAll = {}

function IDecomposeAll.new()
    return ICompoundTask.new()
end

return IDecomposeAll
