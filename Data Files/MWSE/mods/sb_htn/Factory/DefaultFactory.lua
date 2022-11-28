local IFactory = require("Factory.IFactory")
local Queue = require("Utils.Queue")

---@class DefaultFactory : IFactory
local DefaultFactory = {}

function DefaultFactory.new()
    return IFactory.new()
end

function DefaultFactory.CreateArray(length)
    return table.new(length, length)
end

function DefaultFactory.CreateList()
    return {}
end

function DefaultFactory.CreateQueue()
    return Queue.new()
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
    queue = {}
    return queue == {}
end

function DefaultFactory.Free(obj)
    obj = {}
    return obj == {}
end

return DefaultFactory
