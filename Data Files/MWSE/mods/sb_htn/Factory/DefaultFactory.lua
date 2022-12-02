local mc = require("sb_htn.Utils.middleclass")
local IFactory = require("sb_htn.Factory.IFactory")
local Queue = require("sb_htn.Utils.Queue")

---@class DefaultFactory : IFactory
local DefaultFactory = mc.class("DefaultFactory", IFactory)

function DefaultFactory.CreateArray(length)
    return table.new(length, length)
end

function DefaultFactory.CreateList()
    return {}
end

function DefaultFactory.CreateQueue()
    return Queue:new()
end

function DefaultFactory.FreeArray(array)
    array = {}
    return array == {}
end

function DefaultFactory.FreeList(list)
    list = {}
    return list == {}
end

function DefaultFactory.FreeQueue(queue)
    queue = Queue:new()
    return queue:isInstanceOf(Queue)
end

function DefaultFactory.Free(obj)
    obj = {}
    return obj == {}
end

return DefaultFactory
