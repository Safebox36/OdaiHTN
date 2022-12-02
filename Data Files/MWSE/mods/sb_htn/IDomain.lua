local mc = require("sb_htn.Utils.middleclass")

---@class IDomain
local IDomain = mc.class("IDomain")

---@type TaskRoot
IDomain.Root = {}

---@param parent ICompoundTask
---@param subtask ITask
function IDomain.AddSubtask(parent, subtask) end

---@param parent ICompoundTask
---@param slot Slot
function IDomain.AddSlot(parent, slot) end

return IDomain
