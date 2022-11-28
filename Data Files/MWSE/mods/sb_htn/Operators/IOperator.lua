---@class IOperator
local IOperator = {}

function IOperator.new()
	return setmetatable({}, IOperator)
end

---@param ctx IContext
---@return ETaskStatus
function IOperator.Update(ctx) return {} end

---@param ctx IContext
function IOperator.Stop(ctx) end

return IOperator
