local mc = require("sb_htn.Utils.middleclass")
local CompoundTask = require("sb_htn.Tasks.CompoundTasks.CompoundTask")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")

---@class Selector : CompoundTask
local Selector = mc.class("Selector", CompoundTask)

function Selector:IsValid(ctx)
  -- Check that our preconditions are valid first.
  if (self:IsValid(ctx) == false) then
    if (ctx.LogDecomposition) then mwse.log("Selector.IsValid:Failed:Preconditions not met!") end
    return false
  end

  -- Selector requires there to be at least one sub-task to successfully select from.
  if (#self.Subtasks == 0) then
    if (ctx.LogDecomposition) then mwse.log("Selector.IsValid:Failed:No sub-tasks!") end
    return false
  end

  if (ctx.LogDecomposition) then mwse.log("Selector.IsValid:Success!") end
  return true
end

---@param ctx IContext
---@param taskIndex integer
---@param currentDecompositionIndex integer
---@return boolean
function Selector.BeatsLastMTR(ctx, taskIndex, currentDecompositionIndex)
  -- If the last plan's traversal record for this decomposition layer
  -- has a smaller index than the current task index we're about to
  -- decompose, then the new decomposition can't possibly beat the
  -- running plan, so we cancel finding a new plan.
  if (ctx.LastMTR[currentDecompositionIndex] < taskIndex) then
    -- But, if any of the earlier records beat the record in LastMTR, we're still good, as we're on a higher priority branch.
    -- This ensures that [0,0,1] can beat [0,1,0]
    for i = 0, #ctx.MethodTraversalRecord, 1 do
      local diff = ctx.MethodTraversalRecord[i] - ctx.LastMTR[i]
      if (diff < 0) then
        return true
      end
      if (diff > 0) then
        -- We should never really be able to get here, but just in case.
        return false
      end
    end

    return false
  end

  return true
end

--- In a Selector decomposition, just a single sub-task must be valid and successfully decompose for the Selector to be
--- successfully decomposed.
function Selector:OnDecompose(ctx, startIndex, result)
  self.Plan = {}

  for taskIndex = startIndex, #self.Subtasks, 1 do
    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecompose:Task index: %i: %s", taskIndex,
        self.Subtasks[taskIndex].Name)
    end
    -- If the last plan is still running, we need to check whether the
    -- new decomposition can possibly beat it.
    if (ctx.LastMTR ~= {} and #ctx.LastMTR > 0) then
      if (#ctx.MethodTraversalRecord < #ctx.LastMTR) then
        local currentDecompositionIndex = #ctx.MethodTraversalRecord
        if (self.BeatsLastMTR(ctx, taskIndex, currentDecompositionIndex) == false) then
          table.insert(ctx.MethodTraversalRecord, -1)
          if (ctx.DebugMTR) then table.insert(ctx.MTRDebug,
              string.format("REPLAN FAIL %s", self.Subtasks[taskIndex].Name))
          end

          if (ctx.LogDecomposition) then mwse.log("Selector.OnDecompose:Rejected:Index %i is beat by last method traversal record!"
              , currentDecompositionIndex)
          end
          result = {}
          return EDecompositionStatus.Rejected
        end
      end
    end

    local task = self.Subtasks[taskIndex]

    local status = self.OnDecomposeTask(ctx, task, taskIndex, {}, result)
    if (
        status == EDecompositionStatus.Rejected or status == EDecompositionStatus.Succeeded or
            status == EDecompositionStatus.Partial) then
      return status
    end
  end

  result = self.Plan
  return #result == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
end

function Selector:OnDecomposeTask(ctx, task, taskIndex, oldStackDepth, result)
  if (task.IsValid(ctx) == false) then
    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeTask:Failed:Task %s.IsValid returned false!", task.Name) end
    result = self.Plan
    return task.OnIsValidFailed(ctx)
  end

  if (task.Subtasks ~= nil) then
    return self.OnDecomposeCompoundTask(ctx, task, taskIndex, {}, result)
  end

  if (task.ExecutingConditions ~= nil) then
    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeTask:Pushed %s to plan!", task.Name) end
    task.ApplyEffects(ctx)
    self.Plan:pushFirst(task)
  end

  if (task.SlotId ~= nil) then
    return self.OnDecomposeSlot(ctx, task, taskIndex, {}, result)
  end

  result = self.Plan
  local status = #result == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded

  if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeTask:%s!", status) end
  return status
end

function Selector:OnDecomposeCompoundTask(ctx, task, taskIndex, oldStackDepth, result)
  -- We need to record the task index before we decompose the task,
  -- so that the traversal record is set up in the right order.
  ctx.MethodTraversalRecord.Add(taskIndex)
  if (ctx.DebugMTR) then table.insert(ctx.MTRDebug, task.Name) end

  local subPlan = {}
  local status = task:Decompose(ctx, 0, subPlan)

  -- If status is rejected, that means the entire planning procedure should cancel.
  if (status == EDecompositionStatus.Rejected) then
    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeCompoundTask:%s: Decomposing %s was rejected.", status,
        task.Name)
    end
    result = {}
    return EDecompositionStatus.Rejected
  end

  -- If the decomposition failed
  if (status == EDecompositionStatus.Failed) then
    -- Remove the taskIndex if it failed to decompose.
    table.remove(ctx.MethodTraversalRecord, #ctx.MethodTraversalRecord)
    if (ctx.DebugMTR) then table.remove(ctx.MTRDebug, #ctx.MTRDebug) end

    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeCompoundTask:%s: Decomposing %s failed.", status,
        task.Name)
    end
    result = self.Plan
    return EDecompositionStatus.Failed
  end

  while (#subPlan > 0) do
    local p = subPlan:popLast()
    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeCompoundTask:Decomposing %s:Pushed %s to plan!",
        task.Name, p.Name)
    end
    self.Plan:pushFirst(p)
  end

  if (ctx.HasPausedPartialPlan) then
    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeCompoundTask:Return partial plan at index %i!",
        taskIndex)
    end
    result = self.Plan
    return EDecompositionStatus.Partial
  end

  result = self.Plan
  local s = #result == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
  if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeCompoundTask:%s!", tostring(s)) end
  return s
end

function Selector:OnDecomposeSlot(ctx, task, taskIndex, oldStackDepth, result)
  -- We need to record the task index before we decompose the task,
  -- so that the traversal record is set up in the right order.
  ctx.MethodTraversalRecord.Add(taskIndex)
  if (ctx.DebugMTR) then ctx.MTRDebug.Add(task.Name) end

  local subPlan = {}
  local status = task:Decompose(ctx, 0, subPlan)

  -- If status is rejected, that means the entire planning procedure should cancel.
  if (status == EDecompositionStatus.Rejected) then
    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeSlot:%s: Decomposing %s was rejected.", status,
        task.Name)
    end
    result = {}
    return EDecompositionStatus.Rejected
  end

  -- If the decomposition failed
  if (status == EDecompositionStatus.Failed) then
    -- Remove the taskIndex if it failed to decompose.
    table.remove(ctx.MethodTraversalRecord, #ctx.MethodTraversalRecord)
    if (ctx.DebugMTR) then table.remove(ctx.MTRDebug, #ctx.MTRDebug) end

    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeSlot:%s: Decomposing %s failed.", status, task.Name) end
    result = self.Plan
    return EDecompositionStatus.Failed
  end

  while (#subPlan) do
    local p = subPlan:popLast()
    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeSlot:Decomposing %s:Pushed %s to plan!", task.Name,
        p.Name)
    end
    self.Plan:pushFirst(p)
  end

  if (ctx.HasPausedPartialPlan) then
    if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeSlot:Return partial plan!") end
    result = self.Plan
    return EDecompositionStatus.Partial
  end

  result = self.Plan
  local s = #result == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
  if (ctx.LogDecomposition) then mwse.log("Selector.OnDecomposeSlot:%s!", s) end
  return s
end

return Selector
