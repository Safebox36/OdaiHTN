local IEffect = require("Effects.IEffect")

---@class ActionEffect<any> : IEffect
local ActionEffect = {}

---@type function<any>
---@return EEffectType
ActionEffect.Func = {}

---@param name string
---@param type EEffectType
---@param func function<any>
---@return ActionEffect<any>
function ActionEffect.new(name, type, func)
    local self = IEffect.new()

    self.Name = name
    self.Type = type
    self.Func = func

    return self
end

function ActionEffect:Apply(ctx)
    if (ctx.LogDecomposition) then
        mwse.log("ActionEffect.Apply:%i\n\t- %i", self.Type, ctx.CurrentDecompositionDepth + 1)
    end
end

return ActionEffect
