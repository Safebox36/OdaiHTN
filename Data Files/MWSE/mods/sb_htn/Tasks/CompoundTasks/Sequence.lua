local mc = require("sb_htn.Utils.middleclass")
local CompoundTask = require("sb_htn.Tasks.CompoundTasks.CompoundTask")
local IDecomposeAll = require("sb_htn.Tasks.CompoundTasks.IDecomposeAll")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")

---@class Sequence : CompoundTask, IDecomposeAll
local Sequence = mc.class("Sequence", CompoundTask)
Sequence:include(IDecomposeAll)

---@type Queue ITask
Sequence.Plan = {}

function Sequence:IsValid(ctx)
    -- Check that our preconditions are valid first.
    if (self.IsValid(ctx) == false) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.IsValid:Failed:Preconditions not met!") end
        return false
    end

    -- Selector requires there to be subtasks to successfully select from.
    if (#self.Subtasks == 0) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.IsValid:Failed:No sub-tasks!") end
        return false
    end

    if (ctx.LogDecomposition) then mwse.log("Sequence.IsValid:Success!") end
    return true
end

--- In a Sequence decomposition, all sub-tasks must be valid and successfully decomposed in order for the Sequence to
--- be successfully decomposed.
function Sequence:OnDecompose(ctx, startIndex, result)
    self.Plan = {}

    local oldStackDepth = ctx.GetWorldStateChangeDepth(ctx.Factory)

    for taskIndex = startIndex, #self.Subtasks, 1 do
        local task = self.Subtasks[taskIndex]
        if (ctx.LogDecomposition) then mwse.log("Selector.OnDecompose:Task index: %i: %s", taskIndex, task.Name) end

        local status = self:OnDecomposeTask(ctx, task, taskIndex, oldStackDepth, result)
        if (
            status == EDecompositionStatus.Rejected or status == EDecompositionStatus.Failed or
                status == EDecompositionStatus.Partial) then
            ctx.Factory.FreeArray(oldStackDepth)
            return status
        end
    end

    ctx.Factory.FreeArray(oldStackDepth)

    result = self.Plan
    return #result == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
end

function Sequence:OnDecomposeTask(ctx, task, taskIndex, oldStackDepth, result)
    if (task.IsValid(ctx) == false) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeTask:Failed:Task %s.IsValid returned false!",
                task.Name)
        end
        self.Plan = {}
        ctx.TrimToStackDepth(oldStackDepth)
        result = self.Plan
        return task.OnIsValidFailed(ctx)
    end

    if (task.Subtasks ~= nil) then
        return self:OnDecomposeCompoundTask(ctx, task, taskIndex, oldStackDepth, result)
    elseif (task.ExecutingConditions ~= nil) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeTask:Pushed %s to plan!", task.Name) end
        task.ApplyEffects(ctx)
        self.Plan:pushFirst(task)
    elseif (task.Parent ~= nil) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeTask:Return partial plan at index %s!", taskIndex) end
        ctx.HasPausedPartialPlan = true
        ctx.PartialPlanQueue:pushFirst({
            Task = self,
            TaskIndex = taskIndex + 1,
        })

        result = self.Plan
        return EDecompositionStatus.Partial
    elseif (task.SlotId ~= nil) then
        return self:OnDecomposeSlot(ctx, task, taskIndex, oldStackDepth, result)
    end

    result = self.Plan
    local s = #result == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
    if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeTask:%s!", s) end
    return s
end

function Sequence:OnDecomposeCompoundTask(ctx, task, taskIndex, oldStackDepth, result)
    local subPlan = {}
    local status = task.Decompose(ctx, 0, subPlan)

    -- If result is null, that means the entire planning procedure should cancel.
    if (status == EDecompositionStatus.Rejected) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeCompoundTask:%s: Decomposing %s was rejected.",
                status, task.Name)
        end

        self.Plan = {}
        ctx.TrimToStackDepth(oldStackDepth)

        result = {}
        return EDecompositionStatus.Rejected
    end

    -- If the decomposition failed
    if (status == EDecompositionStatus.Failed) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeCompoundTask:%s: Decomposing %s failed.", status,
                task.Name)
        end

        self.Plan = {}
        ctx.TrimToStackDepth(oldStackDepth)
        result = self.Plan
        return EDecompositionStatus.Failed
    end

    while (#subPlan > 0) do
        local p = subPlan:popLast()
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeCompoundTask:Decomposing %s:Pushed %s to plan!",
                task.Name, p.Name)
        end
        self.Plan:pushFirst(p)
    end

    if (ctx.HasPausedPartialPlan) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeCompoundTask:Return partial plan at index %i!",
                taskIndex)
        end
        if (taskIndex < #self.Subtasks) then
            ctx.PartialPlanQueue:pushFirst({
                Task = self,
                TaskIndex = taskIndex + 1,
            })
        end

        result = self.Plan
        return EDecompositionStatus.Partial
    end

    result = self.Plan
    if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeCompoundTask:Succeeded!") end
    return EDecompositionStatus.Succeeded
end

function Sequence:OnDecomposeSlot(ctx, task, taskIndex, oldStackDepth, result)
    local subPlan = {}
    local status = task.Decompose(ctx, 0, subPlan)

    -- If result is null, that means the entire planning procedure should cancel.
    if (status == EDecompositionStatus.Rejected) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeSlot:%s: Decomposing %s was rejected.", status,
                task.Name)
        end

        self.Plan = {}
        ctx.TrimToStackDepth(oldStackDepth)

        result = {}
        return EDecompositionStatus.Rejected
    end

    -- If the decomposition failed
    if (status == EDecompositionStatus.Failed) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeSlot:%s: Decomposing %s failed.", status, task.Name) end

        self.Plan = {}
        ctx.TrimToStackDepth(oldStackDepth)
        result = self.Plan
        return EDecompositionStatus.Failed
    end

    while (#subPlan > 0) do
        local p = subPlan:popLast()
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeSlot:Decomposing %s:Pushed %s to plan!", task.Name,
                p.Name)
        end
        self.Plan:pushFirst(p)
    end

    if (ctx.HasPausedPartialPlan) then
        if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeSlot:Return partial plan at index %i!", taskIndex) end
        if (taskIndex < #self.Subtasks) then
            ctx.PartialPlanQueue:pushFirst({
                Task = self,
                TaskIndex = taskIndex + 1,
            })
        end

        result = self.Plan
        return EDecompositionStatus.Partial
    end

    result = self.Plan
    if (ctx.LogDecomposition) then mwse.log("Sequence.OnDecomposeSlot:Succeeded!") end
    return EDecompositionStatus.Succeeded
end

return Sequence
