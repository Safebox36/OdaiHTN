local mc = require("sb_htn.Utils.middleclass")

---@class ICondition
local ICondition = mc.class("ICondition")

---@type string
ICondition.Name = ""

---@param ctx IContext
---@return boolean
function ICondition.IsValid(ctx) return false end

return ICondition
