local class = require("sb_htn.Utils.30log")

---@class IEffect
---@field Name string
---@field Type EEffectType
---@field Apply fun(self: IEffect, ctx: IContext)
local IEffect = class("IEffect")

return IEffect