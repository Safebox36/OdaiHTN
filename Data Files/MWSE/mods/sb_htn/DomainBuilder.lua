local BaseDomainBuilder = require("BaseDomainBuilder")
local DefaultFactory = require("Factory.DefaultFactory")

--- A simple domain builder for easy use when one just need the core functionality
--- of the BaseDomainBuilder. This class is sealed, so if you want to extend the
--- functionality of the domain builder, extend BaseDomainBuilder instead.
---@class DomainBuilder<IContext> : BaseDomainBuilder<DomainBuilder, IContext>
local DomainBuilder = {}

---@param domainName string
---@param factory IFactory
---@return DomainBuilder
function DomainBuilder.new(domainName, factory)
    return BaseDomainBuilder.new(domainName, factory or DefaultFactory.new())
end

return DomainBuilder
