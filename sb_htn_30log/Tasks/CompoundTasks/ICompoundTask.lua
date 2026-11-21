local class = require("sb_htn.Utils.30log")
local ITask = require("sb_htn.Tasks.ITask")

---@class ICompoundTask : ITask
---@field Subtasks ITask[]
---@field AddSubtask fun(self: ICompoundTask, subtask: ITask): ICompoundTask
--- Decompose the task onto the tasks to process queue, mind it's depth first
---@field Decompose fun(self: ICompoundTask, ctx: IContext, startIndex: integer, result: Queue<ITask>): EDecompositionStatus
local ICompoundTask = ITask:extend("ICompoundTask")

return ICompoundTask