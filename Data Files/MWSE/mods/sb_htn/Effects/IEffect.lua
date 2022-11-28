---@class IEffect
local IEffect = {}

function IEffect.new()
    return setmetatable({}, IEffect)
end

---@type string
IEffect.Name = ""
---@type EEffectType
IEffect.Type = 0

---@param ctx IContext
function IEffect.Apply(ctx) end

return IEffect
