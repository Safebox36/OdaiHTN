local ICondition = require("sb_htn.Conditions.ICondition")

---@class FuncCondition<IContext> : ICondition
---@field private _func fun(ctx: IContext): boolean
local FuncCondition = ICondition:extend("FuncCondition")

---@param name string
---@param func function<IContext>
---@param T IContext
function FuncCondition:init(T, name, func)
    self.Name = name
    self._func = func
    self.T = T
end

---@param ctx IContext
---@return boolean
function FuncCondition:IsValid(ctx)
    assert(ctx:instanceOf(self.T), "Unexpected context type!")
    local result = self._func and self._func(ctx) or false
    if (ctx.LogDecomposition) then
        log("%i - FuncCondition.IsValid:%s", ctx.CurrentDecompositionDepth + 1, result and "True" or "False")
    end
    return result
end

return FuncCondition