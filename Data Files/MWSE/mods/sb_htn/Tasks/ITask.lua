---@class ITask
local ITask = {}

function ITask.new()
	return setmetatable({}, ITask)
end

--- Used for debugging and identification purposes
---@type string
ITask.Name = ""

--- The parent of this task in the hierarchy
---@type ICompoundTask
ITask.Parent = {}

--- The conditions that must be satisfied for this task to pass as valid.
---@type table<ICondition>
ITask.Conditions = {}

--- Add a new condition to the task.
---@param condition ICondition
---@return ITask
function ITask.AddCondition(condition) return {} end

--- Check the task's preconditions, returns true if all preconditions are valid.
---@param ctx IContext
---@return boolean
function ITask.IsValid(ctx) return false end

---@param ctx IContext
---@return EDecompositionStatus
function ITask.OnIsValidFailed(ctx) return 0 end

return ITask
