---@class IDomain
local IDomain = {}

function IDomain.new()
    return setmetatable({}, IDomain)
end

---@type TaskRoot
IDomain.Root = {}

---@param parent ICompoundTask
---@param subtask ITask
function IDomain.AddSubtask(parent, subtask) end

---@param parent ICompoundTask
---@param slot Slot
function IDomain.AddSlot(parent, slot) end

return IDomain
