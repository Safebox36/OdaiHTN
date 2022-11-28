local IOperator = require("Operators.IOperator")

---@class FuncOperator<any> : IOperator
local FuncOperator = {}

---@type function<any>
---@return ETaskStatus
FuncOperator.Func = {}
---@type function<any>
FuncOperator.FuncStop = {}

---@param func function<any>
---@param funcStop function<any>
---@return FuncOperator<any>
function FuncOperator.new(func, funcStop)
    local self = IOperator.new()

    self.Func = func
    self.FuncStop = funcStop

    return self
end

function FuncOperator:Update(ctx)
    self.Func()
end

function FuncOperator:Stop(ctx)
    self.FuncStop()
end

return FuncOperator
