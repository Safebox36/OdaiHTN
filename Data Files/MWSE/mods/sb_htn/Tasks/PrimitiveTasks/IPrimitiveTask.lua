local ITask = require("Tasks.ITask")

---@class IPrimitiveTask : ITask
local IPrimitiveTask = {}

function IPrimitiveTask.new()
    return ITask.new()
end

--- Executing conditions are validated before every call to Operator.Update(...)
---@type table<ICondition>
IPrimitiveTask.ExecutingConditions = {}

--- Add a new executing condition to the primitive task. This will be checked before
---		every call to Operator.Update(...)
---@param condition ICondition
---@return ITask
function IPrimitiveTask.AddExecutingCondition(condition) return {} end

---@type IOperator
IPrimitiveTask.Operator = {}
---@param action IOperator
function IPrimitiveTask.SetOperator(action) end

---@type table<IEffect>
IPrimitiveTask.Effects = {}
---@param effect IEffect
---@return ITask
function IPrimitiveTask.AddEffect(effect) return {} end

---@param ctx IContext
function IPrimitiveTask.ApplyEffects(ctx) end

---@param ctx IContext
function IPrimitiveTask.Stop(ctx) end

return IPrimitiveTask
