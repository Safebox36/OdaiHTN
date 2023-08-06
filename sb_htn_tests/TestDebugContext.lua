local mc = require("sb_htn.Utils.middleclass")
local TestContext = require("sb_htn_tests.TestContext")

local TestDebugContext = mc.class("TestDebugContext", TestContext)

function TestDebugContext:initialize()
    TestContext.initialize(self)

    self.DebugMTR = true
    self.LogDecomposition = true
end

return TestDebugContext
