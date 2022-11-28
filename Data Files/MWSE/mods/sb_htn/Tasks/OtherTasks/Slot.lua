local ITask = require("Tasks.ITask")
local EDecompositionStatus = require("CompoundTasks.EDecompositionStatus")

---@class Slot : ITask
local Slot = {}

function Slot.new()
    return ITask.new()
end

---@type integer
Slot.SlotId = 0
---@type string
Slot.Name = ""
---@type ICompoundTask
Slot.Parent = {}
---@type table<ICondition>
Slot.Conditions = {}
---@type ICompoundTask
Slot.Subtask = {}

function Slot.OnIsValidFailed(ctx)
    return EDecompositionStatus.Failed
end

function AddCondition(condition)
    assert(condition == nil, "Slot tasks does not support conditions.")
end

---@param subtask ICompoundTask
---@return boolean
function Slot:Set(subtask)

    if (Slot.Subtask ~= {}) then
        return false
    end

    Slot.Subtask = subtask
    return true
end

function Slot:Clear()
    Subtask = {}
end

---@param ctx IContext
---@param startIndex integer
---@param result Queue<ITask> -- out?
---@return EDecompositionStatus, Queue<ITask>
function Slot:Decompose(ctx, startIndex, result)
    if (Subtask ~= {}) then
        return Subtask.Decompose(ctx, startIndex, result)
    end

    result = {}
    return EDecompositionStatus.Failed, {}
end

function Slot:IsValid(ctx)
    local result = Slot.Subtask ~= {}
    if (ctx.LogDecomposition) then mwse.log("Slot.IsValid:%s!", (result and "Success" or "Failed")) end
    return result
end

return Slot
