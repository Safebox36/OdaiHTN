local mc = require("sb_htn.Utils.middleclass")
local IOperator = require("sb_htn.Operators.IOperator")
local ETaskStatus = require("sb_htn.Tasks.ETaskStatus")

---@class FuncOperator<IContext> : IOperator
local FuncOperator = mc.class("FuncOperator", IOperator)

---@param func function<IContext>
---@param funcStop function<IContext>
---@param T IContext
function FuncOperator:initialize(T, func, funcStop)
    ---@type function<IContext>
    ---@return ETaskStatus
    self.Func = func
    ---@type function<IContext>
    ---@return boolean
    self.FuncStop = funcStop
    self.T = T
end

---@param ctx IContext
function FuncOperator:Update(ctx)
    assert(ctx:isInstanceOf(self.T), "Unexpected context type!")
    if (self.Func) then return self.Func(ctx) else return ETaskStatus.Failure end
end

---@param ctx IContext
function FuncOperator:Stop(ctx)
    assert(ctx:isInstanceOf(self.T), "Unexpected context type!")
    if (self.FuncStop) then self.FuncStop(ctx) end
end

return FuncOperator
