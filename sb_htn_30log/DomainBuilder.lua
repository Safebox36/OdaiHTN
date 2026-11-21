local class = require("sb_htn.Utils.30log")
local BaseDomainBuilder = require("sb_htn.BaseDomainBuilder")
local DefaultFactory = require("sb_htn.Factory.DefaultFactory")

--- A simple domain builder for easy use when one just need the core functionality
--- of the BaseDomainBuilder. This class is sealed, so if you want to extend the
--- functionality of the domain builder, extend BaseDomainBuilder instead.
---@class DomainBuilder<IContext> : BaseDomainBuilder<DomainBuilder, IContext>
local DomainBuilder = BaseDomainBuilder:extend("DomainBuilder")

---@param domainName string
---@param factory IFactory
---@param T IContext
function DomainBuilder:init(T, domainName, factory)
    DomainBuilder.super.init(self, T, domainName, factory or DefaultFactory(), DomainBuilder)
end

return DomainBuilder