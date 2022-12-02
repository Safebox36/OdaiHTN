local mc = require("sb_htn.Utils.middleclass")
local IEffect = require("sb_htn.Effects.IEffect")

---@class ActionEffect<any> : IEffect
local ActionEffect = mc.class("ActionEffect", IEffect)

---@type function<any>
---@return EEffectType
ActionEffect.Func = function() return 0 end

---@param name string
---@param type EEffectType
---@param func function<any>
function ActionEffect:init(name, type, func)
    self.Name = name
    self.Type = type
    self.Func = func
end

function ActionEffect:Apply(ctx)
    if (ctx.LogDecomposition) then
        mwse.log("ActionEffect.Apply:%i\n\t- %i", self.Type, ctx.CurrentDecompositionDepth + 1)
    end
    self.Func(ctx)
end

return ActionEffect
