local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")

print(">>> FuncConditionTests")

print("> SetsName_ExpectedBehavior")
local c = sb_htn.Conditions.FuncCondition:new("Name", nil, TestContext)

assert("Name" == c.Name)

print("> IsValidFailsWithoutFunctionPtr_ExpectedBehavior")
local ctx = TestContext:new()
c = sb_htn.Conditions.FuncCondition:new("Name", nil, TestContext)
local result = c:IsValid(ctx)
assert(false == result)

print("> IsValidThrowsIfBadContext_ExpectedBehavior")
local c = sb_htn.Conditions.FuncCondition:new("Name", nil, TestContext)
if (pcall(function() c:IsValid(nil) end)) then
    print("Exception not caught.")
end

print("> IsValidCallsInternalFunctionPtr_ExpectedBehavior")
ctx = TestContext:new()
c = sb_htn.Conditions.FuncCondition:new("Done == false", function(context) return context.Done == false end, TestContext)
result = c:IsValid(ctx)
assert(true == result)
