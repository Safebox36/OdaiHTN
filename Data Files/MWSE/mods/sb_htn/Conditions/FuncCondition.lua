local mc = require("sb_htn.Utils.middleclass")
local ICondition = require("sb_htn.Conditions.ICondition")

---@class FuncCondition<any> : ICondition
local FuncCondition = mc.class("FuncCondition", ICondition)

---@type function<any>
---@return boolean
FuncCondition.Func = function() return false end

---@param name string
---@param func function
function FuncCondition:init(name, func)
    self.Name = name
    self.Func = func
end

function FuncCondition.IsValid(ctx)
    local result = FuncCondition.Func(ctx) or false
    if (ctx.LogDecomposition) then
        mwse.log("FuncCondition.IsValid:%s\n\t- %i", tostring(type(result) == "boolean" and true or result),
            ctx.CurrentDecompositionDepth +
            1)
    end
    return result
end

return FuncCondition
