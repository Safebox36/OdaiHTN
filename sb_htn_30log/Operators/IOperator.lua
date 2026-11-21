local class = require("sb_htn.Utils.30log")

---@class IOperator
---@field Start fun(self: IOperator, ctx: IContext): ETaskStatus
---@field Update fun(self: IOperator, ctx: IContext): ETaskStatus
--- Graceful end of task execution.
---@field Stop fun(self: IOperator, ctx: IContext)
--- Forced termination of task execution.
---@field Abort fun(self: IOperator, ctx: IContext)
local IOperator = class("IOperator")

return IOperator