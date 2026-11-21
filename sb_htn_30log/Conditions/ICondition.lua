local class = require("sb_htn.Utils.30log")

---@class ICondition
---@field Name string
---@field IsValid fun(ctx: IContext): boolean
local ICondition = class("ICondition")

return ICondition