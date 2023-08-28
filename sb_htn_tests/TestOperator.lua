local mc = require("sb_htn.Utils.middleclass")
local sb_htn = require("sb_htn.interop")

local TestOperator = mc.class("TestOperator", sb_htn.Operators.IOperator)

function TestOperator:Update(ctx)
    return sb_htn.Tasks.ETaskStatus.Continue
end

return TestOperator
