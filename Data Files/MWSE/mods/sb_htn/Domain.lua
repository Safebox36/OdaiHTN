local mc = require("sb_htn.Utils.middleclass")
local IDomain = require("sb_htn.IDomain")
local TaskRoot = require("sb_htn.Tasks.CompoundTasks.TaskRoot")
local IContext = require("sb_htn.Contexts.IContext")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")

---@class Domain<IContext> : IDomain
local Domain = mc.class("Domain", IDomain)

---@type table<integer, Slot>
Domain._slots = {}

---@param name string
function Domain:init(name)
    self.Root = TaskRoot:new()
    self.Name = name
    self.Parent = {}
end

---@param parent ICompoundTask
---@param subtask ITask
function Domain.AddTask(parent, subtask)
    assert(parent ~= subtask, "Parent-task and Sub-task can't be the same instance!")

    parent.AddSubtask(subtask)
    subtask.Parent = parent
end

---@param parent ICompoundTask
---@param slot Slot
function Domain:AddSlot(parent, slot)
    assert(parent ~= slot, "Parent-task and Sub-task can't be the same instance!")

    if (self._slots ~= {}) then
        assert(self._slots[slot.SlotId] ~= nil, "This slot id already exist in the domain definition!")
    end

    parent.AddSubtask(slot)
    slot.Parent = parent

    table.insert(self._slots, { slot.SlotId, slot })
end

---@param ctx IContext
---@param plan Queue ITask
---@return EDecompositionStatus
function Domain:FindPlan(ctx, plan)
    assert(ctx.IsInitialized == false, "Context was not initialized!")

    assert(ctx.MethodTraversalRecord == {}, "We require the Method Traversal Record to have a valid instance.")

    ctx.ContextState = IContext.EContextState.Planning

    plan = {}
    local status = EDecompositionStatus.Rejected

    -- We first check whether we have a stored start task. This is true
    -- if we had a partial plan pause somewhere in our plan, and we now
    -- want to continue where we left off.
    -- If this is the case, we don't erase the MTR, but continue building it.
    -- However, if we have a partial plan, but LastMTR is not 0, that means
    -- that the partial plan is still running, but something triggered a replan.
    -- When this happens, we have to plan from the domain root (we're not
    -- continuing the current plan), so that we're open for other plans to replace
    -- the running partial plan.
    if (ctx.HasPausedPartialPlan and #ctx.LastMTR == 0) then
        ctx.HasPausedPartialPlan = false
        while (#ctx.PartialPlanQueue > 0) do
            local kvp = ctx.PartialPlanQueue:popLast()
            if (plan == {}) then
                status = kvp.Task.Decompose(ctx, kvp.TaskIndex, plan)
            else
                local p = {}
                status = kvp.Task.Decompose(ctx, kvp.TaskIndex, p)
                if (status == EDecompositionStatus.Succeeded or status == EDecompositionStatus.Partial) then
                    while (p.Count > 0) do
                        plan:pushFirst(p:popLast())
                    end
                end
            end

            -- While continuing a partial plan, we might encounter
            -- a new pause.
            if (ctx.HasPausedPartialPlan) then
                break
            end
        end

        -- If we failed to continue the paused partial plan,
        -- then we have to start planning from the root.
        if (status == EDecompositionStatus.Rejected or status == EDecompositionStatus.Failed) then
            ctx.MethodTraversalRecord = {}
            if (ctx.DebugMTR) then ctx.MTRDebug = {} end

            status = self.Root.Decompose(ctx, 0, plan)
        end
    else

        local lastPartialPlanQueue = {}
        if (ctx.HasPausedPartialPlan) then
            ctx.HasPausedPartialPlan = false
            lastPartialPlanQueue = ctx.Factory.CreateQueue()
            while (#ctx.PartialPlanQueue > 0) do
                lastPartialPlanQueue:pushFirst(ctx.PartialPlanQueue:popLast())
            end
        end

        -- We only erase the MTR if we start from the root task of the domain.
        ctx.MethodTraversalRecord = {}
        if (ctx.DebugMTR) then ctx.MTRDebug = {} end

        status = self.Root.Decompose(ctx, 0, plan)

        -- If we failed to find a new plan, we have to restore the old plan,
        -- if it was a partial plan.
        if (lastPartialPlanQueue ~= {}) then
            if (status == EDecompositionStatus.Rejected or status == EDecompositionStatus.Failed) then
                ctx.HasPausedPartialPlan = true
                ctx.PartialPlanQueue = {}
                while (#lastPartialPlanQueue > 0) do
                    ctx.PartialPlanQueue:pushFirst(lastPartialPlanQueue:popLast())
                end
                ctx.Factory.FreeQueue(lastPartialPlanQueue)
            end
        end
    end

    -- If this MTR equals the last MTR, then we need to double check whether we ended up
    -- just finding the exact same plan. During decomposition each compound task can't check
    -- for equality, only for less than, so this case needs to be treated after the fact.
    local isMTRsEqual = #ctx.MethodTraversalRecord == #ctx.LastMTR
    if (isMTRsEqual) then
        for i = 0, i < #ctx.MethodTraversalRecord, 1 do
            if (ctx.MethodTraversalRecord[i] < ctx.LastMTR[i]) then
                isMTRsEqual = false
                break
            end
        end

        if (isMTRsEqual) then
            plan = {}
            status = EDecompositionStatus.Rejected
        end
    end

    if (status == EDecompositionStatus.Succeeded or status == EDecompositionStatus.Partial) then
        -- Trim away any plan-only or plan&execute effects from the world state change stack, that only
        -- permanent effects on the world state remains now that the planning is done.
        ctx.TrimForExecution()

        -- Apply permanent world state changes to the actual world state used during plan execution.
        for i = 0, #ctx.WorldStateChangeStack, 1 do
            local stack = ctx.WorldStateChangeStack[i]
            if (stack ~= {} and #stack > 0) then
                ctx.WorldState[i] = stack[2]
                stack = {}
            end
        end
    else
        -- Clear away any changes that might have been applied to the stack
        -- No changes should be made or tracked further when the plan failed.
        for i = 0, #ctx.WorldStateChangeStack, 1 do
            local stack = ctx.WorldStateChangeStack[i]
            if (stack ~= {} and #stack > 0) then stack = {} end
        end
    end

    ctx.ContextState = IContext.EContextState.Executing
    return status
end

--- At runtime, set a sub-domain to the slot with the given id.
---
--- This can be used with Smart Objects, to extend the behavior
--- of an agent at runtime.
---@param slotId integer
---@param subDomain Domain<IContext>
---@return boolean
function Domain:TrySetSlotDomain(slotId, subDomain)
    if (self._slots ~= {} and self._slots[slotId]) then
        self._slots[slotId] = subDomain.Root
        return true
    end

    return false
end

--- At runtime, clear the sub-domain from the slot with the given id.
---
--- This can be used with Smart Objects, to extend the behavior
--- of an agent at runtime.
---@param slotId integer
function Domain:ClearSlot(slotId)
    if (self._slots ~= {} and self._slots[slotId]) then
        self._slots[slotId] = nil
    end
end

return Domain
