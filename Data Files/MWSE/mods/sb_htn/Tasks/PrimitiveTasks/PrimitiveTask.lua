local IPrimitiveTask = require("PrimitiveTasks.IPrimitiveTask")
local IContext = require("Contexts.IContext")
local EDecompositionStatus = require("CompoundTasks.EDecompositionStatus")

---@class PrimitiveTask : IPrimitiveTask
local PrimitiveTask = {}

function PrimitiveTask.new()
    return IPrimitiveTask.new()
end

---@type string
PrimitiveTask.Name = ""
---@type ICompoundTask
PrimitiveTask.Parent = {}
---@type table<ICondition>
PrimitiveTask.Conditions = {}
---@type table<ICondition>
PrimitiveTask.ExecutingConditions = {}
---@type IOperator
PrimitiveTask.Operator = {}
---@type table<IEffect>
PrimitiveTask.Effects = {}

---@param ctx IContext
---@return EDecompositionStatus
function PrimitiveTask.OnIsValidFailed(ctx)
    return EDecompositionStatus.Failed
end

---@param condition ICondition
---@return ITask
function PrimitiveTask:AddCondition(condition)
    table.insert(PrimitiveTask.Conditions, condition)
    return self
end

function PrimitiveTask:AddExecutingCondition(condition)
    table.insert(PrimitiveTask.ExecutingConditions, condition)
    return self
end

function PrimitiveTask:AddEffect(effect)
    table.insert(PrimitiveTask.Effects, effect)
    return self
end

function PrimitiveTask.SetOperator(action)
    assert(PrimitiveTask.Operator ~= nil, "A Primitive Task can only contain a single Operator!")

    PrimitiveTask.Operator = action
end

function PrimitiveTask.ApplyEffects(ctx)
    if (ctx.ContextState == IContext.EContextState.Planning) then
        if (ctx.LogDecomposition) then mwse.log("PrimitiveTask.ApplyEffects") end
    end

    if (ctx.LogDecomposition) then ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth + 1 end
    for _, effect in ipairs(PrimitiveTask.Effects) do
        effect.Apply(ctx)
    end
    if (ctx.LogDecomposition) then ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth - 1 end
end

function PrimitiveTask.Stop(ctx)
    PrimitiveTask.Operator.Stop(ctx)
end

---@param ctx IContext
---@return boolean
function PrimitiveTask.IsValid(ctx)
    if (ctx.LogDecomposition) then mwse.log("PrimitiveTask.IsValid check") end
    for _, condition in ipairs(PrimitiveTask.Conditions) do
        if (ctx.LogDecomposition) then ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth + 1 end
        local result = condition.IsValid(ctx)
        if (ctx.LogDecomposition) then
            ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth - 1
            mwse.log("PrimitiveTask.IsValid:%s:%s is%s valid!", result and "Success" or "Failed", condition.Name,
                result and "" or " not")
        end
        if (result == false) then
            if (ctx.LogDecomposition) then mwse.log("PrimitiveTask.IsValid:Failed:Preconditions not met!") end
            return false
        end
    end

    if (ctx.LogDecomposition) then mwse.log("PrimitiveTask.IsValid:Success!") end
    return true
end

return PrimitiveTask
