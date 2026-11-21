local TestContext = require("sb_htn_tests_30log.TestContext")

---@class TestDebugContext : TestContext
local TestDebugContext = TestContext:extend("TestDebugContext")

function TestDebugContext:init()
    TestDebugContext.super.init(self)

    self.DebugMTR = true
    self.LogDecomposition = true
end

return TestDebugContext