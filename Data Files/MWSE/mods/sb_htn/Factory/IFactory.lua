---@class IFactory
local IFactory = {}

function IFactory.new()
	return setmetatable({}, IFactory)
end

---@param length integer
---@return any[]
function IFactory.CreateArray(length) return {} end

---@param array any[]
---@return boolean
function IFactory.FreeArray(array) return false end

---@return Queue<any>
function IFactory.CreateQueue() return {} end

---@param queue Queue<any>
---@return boolean
function IFactory.FreeQueue(queue) return false end

---@return table<any>
function IFactory.CreateList() return {} end

---@param list table<any>
---@return table<any>
function IFactory.FreeList(list) return {} end

---@generic any : table
---@param obj any
---@return boolean
function IFactory.Free(obj) return false end

return IFactory
