local mc = require("sb_htn.Utils.middleclass")
local IOperator = require("sb_htn.Operators.IOperator")

---@class FuncOperator<any> : IOperator
local FuncOperator = mc.class("FuncOperator", IOperator)

---@type function<any>
---@return ETaskStatus
FuncOperator.Func = function() return 0 end
---@type function<any>
FuncOperator.FuncStop = function() end

---@param func function<any>
---@param funcStop function<any>
function FuncOperator:init(func, funcStop)
    self.Func = func
    self.FuncStop = funcStop
end

function FuncOperator:Update(ctx)
    self.Func()
end

function FuncOperator:Stop(ctx)
    self.FuncStop()
end

return FuncOperator
