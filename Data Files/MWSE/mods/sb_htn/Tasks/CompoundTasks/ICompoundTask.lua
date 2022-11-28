local ITask = require("Tasks.ITask")

---@class ICompoundTask : ITask
local ICompoundTask = {}

function ICompoundTask.new()
    return ITask.new()
end

---@type table<ITask>
ICompoundTask.Subtasks = {}
---@param subtask ITask
---@return ICompoundTask
function ICompoundTask.AddSubtask(subtask) return {} end

--- Decompose the task onto the tasks to process queue, mind it's depth first
---@param ctx IContext
---@param startIndex integer
---@param result Queue<ITask> -- out?
---@return EDecompositionStatus
function ICompoundTask.Decompose(ctx, startIndex, result) return 0 end

return ICompoundTask
