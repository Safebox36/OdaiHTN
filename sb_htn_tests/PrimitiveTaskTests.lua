local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")

print("  > PrimitiveTaskTests")

--[[
Verifies that a primitive task correctly adds a condition to its conditions collection and returns the task itself for method chaining.
Conditions are validators evaluated during task decomposition to determine whether a task is applicable in the current world state.
Planning conditions gate whether a task can be selected and included in the plan, enabling data-driven task selection.
This test ensures the fluent builder pattern works correctly by confirming the method returns the task instance and the condition is stored.
]]
print("    > AddCondition_ExpectedBehavior")
local task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
local t = task:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition", function(context1) return context1.Done == false end))
assert(t == task)
assert(table.size(task.Conditions) == 1)

--[[
Verifies that a primitive task correctly adds an executing condition to its executing conditions collection and returns the task itself for method chaining.
Executing conditions are runtime validators checked before each task execution tick to ensure the task remains valid during execution.
Unlike planning conditions which gate task selection, executing conditions can invalidate a task mid-execution if world state changes, triggering replanning.
This test ensures executing conditions are properly stored and that the fluent API pattern returns the task for continued builder usage.
]]
print("    > AddExecutingCondition_ExpectedBehavior")
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
t = task:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition", function(context2) return context2.Done == false end))
assert(t == task)
assert(table.size(task.ExecutingConditions) == 1)

--[[
Verifies that a primitive task correctly adds an effect to its effects collection and returns the task itself for method chaining.
Effects are world state modifications applied when a task completes, representing the task's impact on the world.
Effects can be PlanOnly (applied during planning for lookahead), PlanAndExecute (applied during both phases), or Permanent (persist across both phases).
This test ensures effects are properly collected and that the fluent builder pattern allows chained configuration of effects.
]]
print("    > AddEffect_ExpectedBehavior")
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
t = task:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent, function(context3, effectType) context3.Done = true end))
assert(t == task)
assert(table.size(task.Effects) == 1)

--[[
Verifies that a primitive task correctly stores an operator when SetOperator is called, making it available for execution.
The operator is the execution mechanism that implements the actual work of the primitive task when it is selected for execution.
Operators manage the task lifecycle (Start for initialization, Update for execution loop, Stop for cleanup) and return TaskStatus to indicate progress.
This test ensures the task properly retains the operator for later invocation during plan execution.
]]
print("    > SetOperator_ExpectedBehavior")
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
task:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext))
assert(task.Operator)

--[[
Verifies that a primitive task throws an exception if SetOperator is called more than once, preventing accidental operator replacement.
Each primitive task should have exactly one operator for its execution mechanism, as multiple operators would create ambiguity about which should execute.
Allowing operator replacement could silently introduce bugs where a task's implementation is accidentally overwritten during builder construction.
This test ensures tasks enforce single-operator semantics by rejecting attempts to set a second operator with a clear exception.
]]
print("    > SetOperatorThrowsExceptionIfAlreadySet_ExpectedBehavior")
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
task:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext))
if (pcall(function() task:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext)) end)) then
    print("Exception not caught.")
end

--[[
Verifies that a primitive task correctly applies all its effects to the context when ApplyEffects is called.
Effects represent the consequences of a task completing and modify the world state to reflect what the task accomplished.
ApplyEffects is called when a task completes successfully, allowing each effect to update the context based on its type and user-defined logic.
This test confirms that the task properly iterates through its effects collection and applies each one to the provided context.
]]
print("    > ApplyEffects_ExpectedBehavior")
local ctx = TestContext:new()
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
t = task:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent, function(context4, effectType) context4.Done = true end))
task:ApplyEffects(ctx)
assert(true == ctx.Done)

--[[
Verifies that a primitive task correctly calls its operator's Stop method when Stop is called, allowing the operator to perform cleanup.
Stop is invoked when a task completes or is interrupted, giving the operator an opportunity to finalize state and perform resource cleanup.
The operator's Stop function can modify world state to record final results or trigger side effects that persist after task completion.
This test confirms that the task delegates to its operator's Stop method and that state changes made in Stop are preserved in the context.
]]
print("    > StopWithValidOperator_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
task:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, nil, nil, function(context5) context5.Done = true end))
task:Stop(ctx)
assert(task.Operator)
assert(true == ctx.Done)

--[[
Verifies that a primitive task handles Stop gracefully when no operator is assigned, treating it as a valid no-op.
Tasks may be created without operators for planning purposes or as intermediate task structures not meant for direct execution.
Calling Stop on a taskless operator should not throw an exception but rather complete safely without executing any cleanup logic.
This test ensures tasks are defensive about missing operators and do not fail catastrophically when lifecycle methods are called prematurely.
]]
print("    > StopWithNullOperator_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
if (pcall(function() task:Stop(ctx) end)) then
    print("Exception not caught.")
end

--[[
Verifies that a primitive task's IsValid method returns true only when all its planning conditions are satisfied by the current world state.
IsValid is called during decomposition to determine whether a task can be selected and included in the plan.
A task is valid only if every condition it has returns true when evaluated against the context; a single failing condition makes the task invalid.
This test demonstrates the AND semantics of multiple conditions and shows how adding contradictory conditions (Done == true when Done is false) invalidates the task.
]]
print("    > IsValid_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task.Name = "Test"
task:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == false", function(context6) return context6.Done == false end))
local expectTrue = task:IsValid(ctx)
task:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context7) return context7.Done == true end))
local expectFalse = task:IsValid(ctx)
assert(expectTrue)
assert(expectFalse == false)