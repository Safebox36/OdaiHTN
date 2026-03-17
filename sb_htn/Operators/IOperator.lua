local mc = require("sb_htn.Utils.middleclass")

---@class IOperator
local IOperator = mc.class("IOperator")

---@param ctx IContext
---@return ETaskStatus
function IOperator:Start(ctx) return 0 end

---@param ctx IContext
---@return ETaskStatus
function IOperator:Update(ctx) return 0 end

--- Graceful end of task execution.
---@param ctx IContext
function IOperator:Stop(ctx) end

--- Forced termination of task execution.
---@param ctx IContext
function IOperator:Abort(ctx) end

return IOperator