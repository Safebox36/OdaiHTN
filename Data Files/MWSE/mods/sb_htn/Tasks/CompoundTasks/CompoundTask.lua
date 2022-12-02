local mc = require("sb_htn.Utils.middleclass")
local ICompoundTask = require("sb_htn.Tasks.CompoundTasks.ICompoundTask")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")

---@class CompoundTask : ICompoundTask
local CompoundTask = mc.class("CompoundTask", ICompoundTask)

---@type string
CompoundTask.Name = ""
---@type ICompoundTask
CompoundTask.Parent = {}
---@type table<ICondition>
CompoundTask.Conditions = {}
---@type table<ITask>
CompoundTask.Subtasks = {}

function CompoundTask.OnIsValidFailed(ctx)
    return EDecompositionStatus.Failed
end

function CompoundTask:AddCondition(condition)
    table.insert(CompoundTask.Conditions, condition)
    return self
end

function CompoundTask:AddSubtask(subtask)
    table.insert(CompoundTask.Subtasks, subtask)
    return self
end

function CompoundTask.Decompose(ctx, startIndex, result)
    if (ctx.LogDecomposition) then ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth + 1 end
    local status = CompoundTask.OnDecompose(ctx, startIndex, result)
    if (ctx.LogDecomposition) then ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth - 1 end
    return status
end

---@param ctx IContext
---@param startIndex integer
---@param result Queue ITask - out
---@return EDecompositionStatus
function CompoundTask.OnDecompose(ctx, startIndex, result) return 0 end

---@param ctx IContext
---@param task ITask
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue ITask - out
---@return EDecompositionStatus
function CompoundTask.OnDecomposeTask(ctx, task, taskIndex, oldStackDepth, result) return 0 end

---@param ctx IContext
---@param task ICompoundTask
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue ITask - out
---@return EDecompositionStatus
function CompoundTask.OnDecomposeCompoundTask(ctx, task, taskIndex, oldStackDepth, result) return 0 end

---@param ctx IContext
---@param task Slot
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue ITask - out
---@return EDecompositionStatus
function CompoundTask.OnDecomposeSlot(ctx, task, taskIndex, oldStackDepth, result) return 0 end

function CompoundTask:IsValid(ctx)
    for _, condition in ipairs(self.Conditions) do
        local result = condition.IsValid(ctx)
        if (ctx.LogDecomposition) then mwse.log("CompoundTask.IsValid:%s:%s is%s valid!",
                result and "Success" or "Failed", condition.Name, result and "" or " not")
        end
        if (result == false) then
            return false
        end
    end

    return true
end

return CompoundTask
