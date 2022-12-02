local mc = require("sb_htn.Utils.middleclass")
local ITask = require("sb_htn.Tasks.ITask")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")

---@class PausePlanTask : ITask
local PausePlanTask = mc.class("PausePlanTask", ITask)

---@type string
PausePlanTask.Name = ""
---@type ICompoundTask
PausePlanTask.Parent = {}
---@type table<ICondition>
PausePlanTask.Conditions = {}
---@type table<IEffect>
PausePlanTask.Effects = {}

function PausePlanTask.OnIsValidFailed(ctx)
    return EDecompositionStatus.Failed
end

function PausePlanTask.AddCondition(condition)
    assert(condition == nil, "Pause Plan tasks does not support conditions.")
end

function PausePlanTask.AddEffect(effect)
    assert(effect == nil, "Pause Plan tasks does not support effects.")
end

---@param ctx IContext
function PausePlanTask.ApplyEffects(ctx) end

function PausePlanTask.IsValid(ctx)
    if (ctx.LogDecomposition) then mwse.log("PausePlanTask.IsValid:Success!") end
    return true
end

return PausePlanTask
