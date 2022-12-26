local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")

print(">>> FuncOperatorTests")

print("> UpdateDoesNothingWithoutFunctionPtr_ExpectedBehavior")
local ctx = TestContext:new()
local e = sb_htn.Operators.FuncOperator:new(nil, nil, TestContext)
e:Update(ctx)

print("> StopDoesNothingWithoutFunctionPtr_ExpectedBehavior")
ctx = TestContext:new()
e = sb_htn.Operators.FuncOperator:new(nil, nil, TestContext)
e:Stop(ctx)

print("> UpdateThrowsIfBadContext_ExpectedBehavior")
e = sb_htn.Operators.FuncOperator:new(nil, nil, TestContext)
if (pcall(function() e:Update(nil) end)) then
    print("Exception not caught.")
end

print("> StopThrowsIfBadContext_ExpectedBehavior")
e = sb_htn.Operators.FuncOperator:new(nil, nil, TestContext)
if (pcall(function() e:Stop(nil) end)) then
    print("Exception not caught.")
end

print("> UpdateReturnsStatusInternalFunctionPtr_ExpectedBehavior")
ctx = TestContext:new()
e = sb_htn.Operators.FuncOperator:new(function(context1) return sb_htn.Tasks.ETaskStatus.Success end, nil, TestContext)
local status = e:Update(ctx)
assert(sb_htn.Tasks.ETaskStatus.Success == status)

print("> StopCallsInternalFunctionPtr_ExpectedBehavior")
ctx = TestContext:new()
e = sb_htn.Operators.FuncOperator:new(nil, function(context2) context2.Done = true end, TestContext)
e:Stop(ctx)
assert(true == ctx.Done)
