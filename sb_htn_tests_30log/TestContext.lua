local sb_htn = require("sb_htn.interop")

---@class TestContext : BaseContext
local TestContext = sb_htn.Contexts.BaseContext:extend("TestContext")

TestContext.TestEnum = {
    StateA = 1,
    StateB = 2,
    StateC = 3
}

function TestContext:init()
    TestContext.super.init(self)

    self.WorldState       = {}
    self.Factory          = sb_htn.Factory.DefaultFactory()
    self.PlannerState     = sb_htn.Planners.DefaultPlannerState()
    self.DebugMTR         = false
    self.Done             = false
    self.ExecutionDepth   = 0
    self.LogDecomposition = false

    for _, v in pairs(self.TestEnum) do
        self.WorldState[v] = 0
    end
end

function TestContext:HasState(state, value)
    if (value ~= nil) then
        return TestContext.super.HasState(self, state, (value and 1 or 0))
    else
        return TestContext.super.HasState(self, state, 1)
    end
end

function TestContext:SetState(state, value, T)
    TestContext.super.SetState(self, state, (value and 1 or 0), true, T)
end

return TestContext