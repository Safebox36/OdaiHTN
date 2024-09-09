local mc = require("sb_htn.Utils.middleclass")
local sb_htn = require("sb_htn.interop")

local TestContext = mc.class("TestContext", sb_htn.Contexts.BaseContext)

TestContext.TestEnum = {
    StateA = 1,
    StateB = 2,
    StateC = 3
}

function TestContext:initialize()
    sb_htn.Contexts.BaseContext.initialize(self)

    self.WorldState       = {}
    self.Factory          = sb_htn.Factory.DefaultFactory:new()
    self.PlannerState     = sb_htn.Planners.DefaultPlannerState:new()
    self.DebugMTR         = false
    self.Done             = false
    self.LogDecomposition = false

    for _, v in pairs(self.TestEnum) do
        self.WorldState[v] = 0
    end
end

function TestContext:HasState(state, value)
    if (value ~= nil) then
        return sb_htn.Contexts.BaseContext.HasState(self, state, (value and 1 or 0))
    else
        return sb_htn.Contexts.BaseContext.HasState(self, state, 1)
    end
end

function TestContext:SetState(state, value, T)
    sb_htn.Contexts.BaseContext.SetState(self, state, (value and 1 or 0), true, T)
end

return TestContext
