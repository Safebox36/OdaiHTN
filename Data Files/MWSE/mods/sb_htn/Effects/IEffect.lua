local mc = require("sb_htn.Utils.middleclass")

---@class IEffect
local IEffect = mc.class("IEffect")

---@type string
IEffect.Name = ""
---@type EEffectType
IEffect.Type = 0

---@param ctx IContext
function IEffect.Apply(ctx) end

return IEffect
