---@class ICondition
local ICondition = {}

function ICondition.new()
	return setmetatable({}, ICondition)
end

---@type string
ICondition.Name = ""

---@param ctx IContext
---@return boolean
function ICondition.IsValid(ctx) return false end

return ICondition
