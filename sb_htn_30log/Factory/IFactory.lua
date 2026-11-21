local class = require("sb_htn.Utils.30log")

---@class IFactory
---@field CreateArray fun(self: IFactory, T: any, length: integer): any[]
---@field FreeArray fun(self: IFactory, T: any, array: any[]): boolean
---@field CreateQueue fun(self: IFactory, T: any): Queue<any>
---@field FreeQueue fun(self: IFactory, T: any, queue: Queue<any>): boolean
---@field CreateList fun(self: IFactory, T: any): any[]
---@field FreeList fun(self: IFactory, T: any, list: any[]): any[]
---@field Free fun(self: IFactory, T: any, obj: any): boolean
local IFactory = class("IFactory")

return IFactory