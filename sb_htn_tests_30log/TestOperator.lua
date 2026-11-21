local sb_htn = require("sb_htn.interop")

---@class TestOperator : IOperator
local TestOperator = sb_htn.Operators.IOperator:extend("TestOperator")

function TestOperator:Start(ctx)
    return sb_htn.Tasks.ETaskStatus.Continue
end

function TestOperator:Update(ctx)
    return sb_htn.Tasks.ETaskStatus.Continue
end

function TestOperator:Stop(ctx)
end

function TestOperator:Abort(ctx)
end

return TestOperator