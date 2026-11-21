local class = require("sb_htn.Utils.30log")
local IEffect = require("sb_htn.Effects.IEffect")
local EEffectType = require("sb_htn.Effects.EEffectType")
local GetKey = require("sb_htn.Utils.GetKey")

---@class ActionEffect<IContext> : IEffect
---@field private _action fun(IContext, EEffectType)
local ActionEffect = IEffect:extend("ActionEffect")

---@param name string
---@param effectType EEffectType
---@param action function<IContext>
---@param T IContext
function ActionEffect:init(T, name, effectType, action)
    self.Name = name
    self.Type = effectType
    self._action = action
    self.T = T
end

---@param ctx IContext
function ActionEffect:Apply(ctx)
    assert(ctx:instanceOf(self.T), "Unexpected context type!")
    if (ctx.LogDecomposition) then
        log("%i - ActionEffect.Apply:%s", ctx.CurrentDecompositionDepth, GetKey(self.Type, EEffectType))
    end
    if (self._action) then self._action(ctx, self.Type) end
end

return ActionEffect