local ICondition = require("Conditions.ICondition")

---@class FuncCondition<any> : ICondition
local FuncCondition = {}

---@type function<any>
---@return boolean
FuncCondition.Func = function() return false end

---@param name string
---@param func function
---@return FuncCondition<any>
function FuncCondition.new(name, func)
    local self = ICondition.new()

    self.Name = name
    self.Func = func

    return self
end

function FuncCondition.IsValid(ctx)
    local result = FuncCondition.Func() or false
    if (ctx.LogDecomposition) then
        mwse.log("FuncCondition.IsValid:%s\n\t- %i", tostring(type(result) == "boolean" and true or result),
            ctx.CurrentDecompositionDepth +
            1)
    end
    return result
end

return FuncCondition
