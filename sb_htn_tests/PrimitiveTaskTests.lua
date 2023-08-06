local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")

print(">>> PrimitiveTaskTests")

print("> AddCondition_ExpectedBehavior")
local task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
local t = task:AddCondition(sb_htn.Conditions.FuncCondition:new("TestCondition",
    function(context1) return context1.Done == false end, TestContext))
assert(t == task)
assert(table.size(task.Conditions) == 1)

print("> AddExecutingCondition_ExpectedBehavior")
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
t = task:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new("TestCondition",
    function(context2) return context2.Done == false end, TestContext))
assert(t == task)
assert(table.size(task.ExecutingConditions) == 1)

print("> AddEffect_ExpectedBehavior")
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
t = task:AddEffect(sb_htn.Effects.ActionEffect:new("TestEffect", sb_htn.Effects.EEffectType.Permanent,
    function(context3, type) context3.Done = true end, TestContext))
assert(t == task)
assert(table.size(task.Effects) == 1)

print("> SetOperator_ExpectedBehavior")
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
task:SetOperator(sb_htn.Operators.FuncOperator:new(nil, nil, TestContext))
assert(task.Operator ~= nil)

print("> SetOperatorThrowsExceptionIfAlreadySet_ExpectedBehavior")
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
task:SetOperator(sb_htn.Operators.FuncOperator:new(nil, nil, TestContext))
if (pcall(function() task:SetOperator(sb_htn.Operators.FuncOperator:new(nil, nil, TestContext)) end)) then
    print("Exception not caught.")
end

print("> ApplyEffects_ExpectedBehavior")
local ctx = TestContext:new()
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
t = task:AddEffect(sb_htn.Effects.ActionEffect:new("TestEffect", sb_htn.Effects.EEffectType.Permanent,
    function(context4, type) context4.Done = true end, TestContext))
task:ApplyEffects(ctx)
assert(true == ctx.Done)

print("> StopWithValidOperator_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
task:SetOperator(sb_htn.Operators.FuncOperator:new(nil, function(context5) context5.Done = true end, TestContext))
task:Stop(ctx)
assert(task.Operator ~= nil)
assert(true == ctx.Done)

print("> StopWithNullOperator_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
if (pcall(function() task:Stop(ctx) end)) then
    print("Exception not caught.")
end

print("> IsValid_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
task:AddCondition(sb_htn.Conditions.FuncCondition:new("Done == false",
    function(context6) return context6.Done == false end, TestContext))
local expectTrue = task:IsValid(ctx)
task:AddCondition(sb_htn.Conditions.FuncCondition:new("Done == true", function(context7) return context7.Done == true end
    , TestContext))
local expectFalse = task:IsValid(ctx)
assert(expectTrue)
assert(expectFalse == false)
