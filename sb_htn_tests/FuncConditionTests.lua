local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")

print("  > FuncConditionTests")

print("    > SetsName_ExpectedBehavior")
local c = sb_htn.Conditions.FuncCondition:new(TestContext, "Name")

assert("Name" == c.Name)

print("    > IsValidFailsWithoutFunctionPtr_ExpectedBehavior")
local ctx = TestContext:new()
c = sb_htn.Conditions.FuncCondition:new(TestContext, "Name")
local result = c:IsValid(ctx)
assert(false == result)

print("    > IsValidThrowsIfBadContext_ExpectedBehavior")
local c = sb_htn.Conditions.FuncCondition:new(TestContext, "Name")
if (pcall(function() c:IsValid(nil) end)) then
    print("Exception not caught.")
end

print("    > IsValidCallsInternalFunctionPtr_ExpectedBehavior")
ctx = TestContext:new()
c = sb_htn.Conditions.FuncCondition:new(TestContext, "Done == false", function(context) return context.Done == false end)
result = c:IsValid(ctx)
assert(true == result)
