local mc = require("sb_htn.Utils.middleclass")
local ITask = require("sb_htn.Tasks.ITask")

---@class IPrimitiveTask : ITask
local IPrimitiveTask = mc.class("IPrimitiveTask", ITask)

--- Executing conditions are validated before every call to Operator.Update(...)
---@type table<ICondition>
IPrimitiveTask.ExecutingConditions = {}

--- Add a new executing condition to the primitive task. This will be checked before
--- every call to Operator.Update(...)
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