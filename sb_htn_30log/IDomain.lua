local class = require("sb_htn.Utils.30log")

---@class IDomain
---@field Root TaskRoot
---@field AddSubtask fun(self: IDomain, parent: ICompoundTask, subtask: ITask): ICompoundTask
---@field AddSlot fun(self: IDomain, parent: ICompoundTask, slot: Slot): ICompoundTask
local IDomain = class("IDomain")

return IDomain