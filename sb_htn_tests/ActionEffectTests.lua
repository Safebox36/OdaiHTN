local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")

print("  > ActionEffectTests")

print("    > SetsName_ExpectedBehavior")
local e = sb_htn.Effects.ActionEffect:new(TestContext, "Name", sb_htn.Effects.EEffectType.PlanOnly)
assert("Name" == e.Name)

print("    > SetsType_ExpectedBehavior")
e = sb_htn.Effects.ActionEffect:new(TestContext, "Name", sb_htn.Effects.EEffectType.PlanOnly)
assert(sb_htn.Effects.EEffectType.PlanOnly == e.Type)

print("    > ApplyDoesNothingWithoutFunctionPtr_ExpectedBehavior")
local ctx = TestContext:new()
ctx:init()
e = sb_htn.Effects.ActionEffect:new(TestContext, "Name", sb_htn.Effects.EEffectType.PlanOnly)
e:Apply(ctx)

print("    > ApplyThrowsIfBadContext_ExpectedBehavior")
e = sb_htn.Effects.ActionEffect:new(TestContext, "Name", sb_htn.Effects.EEffectType.PlanOnly)
if (pcall(function() e:Apply(nil) end)) then
    print("Exception not caught.")
end

print("    > ApplyCallsInternalFunctionPtr_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
e = sb_htn.Effects.ActionEffect:new(TestContext, "Name", sb_htn.Effects.EEffectType.PlanOnly,
    function(c) c.Done = true end)
e:Apply(ctx)
assert(true == ctx.Done)
