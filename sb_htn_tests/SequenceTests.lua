local sb_htn = require("sb_htn.interop")
local Queue = require("sb_htn.Utils.Queue")
local TestContext = require("sb_htn_tests.TestContext")

print("  > SequenceTests")

--[[
Verifies that a Sequence correctly adds a condition to its conditions collection and returns itself for method chaining.
A Sequence is a compound task that decomposes by executing all subtasks in strict order, unlike a Selector which tries alternatives.
Conditions gate whether a sequence is applicable before decomposition begins, evaluated against the current world state.
This test ensures the fluent builder pattern works correctly for sequences by confirming conditions are stored and the method returns the task instance.
]]
print("    > AddCondition_ExpectedBehavior")
local task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
local t = task:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
                                                                function(context1) return context1.Done == false end))
assert(t == task)
assert(table.size(task.Conditions) == 1)

--[[
Verifies that a Sequence correctly adds a subtask to its subtasks collection and returns itself for method chaining.
Sequences maintain an ordered list of subtasks that must all decompose successfully in sequence (AND semantics).
Unlike selectors which try alternatives until one succeeds, sequences must decompose every subtask in order.
This test confirms the fluent builder pattern allows chaining subtask additions and that each subtask is properly stored.
]]
print("    > AddSubtask_ExpectedBehavior")
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
t = task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task"
    return p
end)())
assert(t == task)
assert(table.size(task.Subtasks) == 1)

--[[
Verifies that a Sequence with no subtasks is considered invalid and cannot be decomposed.
A sequence requires at least one subtask to execute in sequence; an empty sequence has nothing to accomplish.
During decomposition validation, the planner checks if a sequence is valid before attempting decomposition, rejecting invalid sequences early.
This test ensures sequences properly validate their structure and reject empty sequences that would cause decomposition failures.
]]
print("    > IsValidFailsWithoutSubtasks_ExpectedBehavior")
local ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
assert(task:IsValid(ctx) == false)

--[[
Verifies that a Sequence with subtasks is considered valid and can proceed to decomposition.
A sequence is valid when it has at least one subtask to execute in the sequence.
The planner uses IsValid as a gating check before attempting decomposition, enabling early rejection of unsuitable tasks.
This test confirms that sequences with subtasks properly report validity, allowing decomposition to proceed.
]]
print("    > IsValid_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task"
    return p
end)())
assert(task:IsValid(ctx))

--[[
Verifies that attempting to decompose without initializing the context causes a NullReferenceException.
The context must be initialized to set up world state tracking structures (WorldStateChangeStack) required for decomposition.
This test demonstrates the context initialization requirement and ensures the decomposition process properly validates context prerequisites.
Without initialization, accessing context state structures fails, preventing decomposition from proceeding safely.
]]
print("    > DecomposeRequiresContextInitFails_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
local plan = Queue:new()
if (pcall(function() task:Decompose(ctx, 1, plan) end)) then
    print("Exception not caught.")
end

--[[
Verifies that attempting to decompose a Sequence with no subtasks returns Failed status and an empty plan.
Decomposition breaks down compound tasks into executable primitives based on the current world state.
When a sequence has no subtasks, there are no tasks to execute in sequence, so decomposition fails with an empty plan queue.
This test confirms the sequence properly handles the edge case of an empty subtask list by returning Failed without crashing.
]]
print("    > DecomposeWithNoSubtasks_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
plan = Queue:new()
local status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)

--[[
Verifies that a Sequence with valid subtasks successfully decomposes all of them into the plan in order.
Sequences implement AND semantics, requiring all subtasks to decompose successfully and adding all results to the plan.
Since both primitive tasks always decompose successfully, both are added to the plan in sequence order.
This test demonstrates basic sequence decomposition behavior and confirms all subtasks are included in the plan queue.
]]
print("    > DecomposeWithSubtasks_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) == 2)
assert("Sub-task1" == plan:peek().Name)

--[[
Verifies that a Sequence can decompose nested compound tasks (selectors containing selectors) in sequence.
Sequences recursively decompose all their subtasks in order, including decomposing nested compound tasks.
The nested selector task2/task3 decomposes and produces Sub-task2, which is added to the plan along with Sub-task4 from the sequence.
This test demonstrates that sequences handle complex nesting and properly collect results from all nested decompositions in order.
]]
print("    > DecomposeNestedSubtasks_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
local task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
local task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task3.Name = "Test3"
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) == 2)
assert("Sub-task2" == plan:pop().Name)
assert("Sub-task4" == plan:pop().Name)

--[[
Verifies that a Sequence fails decomposition when any subtask cannot be decomposed.
Sequences require ALL subtasks to decompose successfully for the overall decomposition to succeed (AND semantics).
When the second subtask fails its condition, the sequence cannot proceed and returns Failed with an empty plan.
This test demonstrates the strict sequencing requirement: even if some subtasks decompose, if one fails, the entire sequence fails.
]]
print("    > DecomposeWithSubtasksOneFail_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)

--[[
Verifies that a Sequence fails decomposition when a nested compound task cannot decompose.
Nested compound tasks (like empty selectors) may fail to decompose if they have no valid alternatives.
When a nested compound subtask fails, the entire sequence decomposition fails, and no plan is returned.
This test demonstrates that sequences properly propagate failures from nested decompositions, maintaining AND semantics across nesting levels.
]]
print("    > DecomposeWithSubtasksCompoundSubtaskFails_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function()
    local s = sb_htn.Tasks.CompoundTasks.Selector:new()
    s.Name = "Sub-task1"
    return s
end)())
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)

--[[
Verifies that when a Sequence fails decomposition, all applied effects are rolled back to restore the previous world state.
During planning, effects applied during subtask decomposition are tracked on the WorldStateChangeStack for rollback capability.
When a sequence fails (because a later subtask fails), the planner must undo all effects applied during the failed decomposition attempt.
This test demonstrates rollback mechanism: despite effects being applied during the first subtask, they're rolled back when the sequence ultimately fails, maintaining planning consistency.
]]
print("    > DecomposeFailureReturnToPreviousWorldState_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.PlanAndExecute)
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
ctx:SetState(TestContext.TestEnum.StateC, true, sb_htn.Effects.EEffectType.PlanOnly)
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
                                                function(context2, effectType)
                                                    context2:SetState(TestContext.TestEnum.StateA, false,
                                                                      sb_htn.Effects.EEffectType.PlanOnly)
                                                end))
    return p
end)())
task:AddSubtask((function()
    local s = sb_htn.Tasks.CompoundTasks.Selector:new()
    s.Name = "Sub-task2"
    return s
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateC].list) == 1)
assert(1 == ctx:GetState(TestContext.TestEnum.StateA))
assert(1 == ctx:GetState(TestContext.TestEnum.StateB))
assert(1 == ctx:GetState(TestContext.TestEnum.StateC))

--[[
Verifies that a Sequence rejects decomposition when a nested selector's MTR choice fails.
Sequences decompose all subtasks in order, tracking MTR choices for each nested selector encountered.
The LastMTR indicates [0, 0] was previously used, but when attempting the same path, the nested selector fails at index 0 and records -1.
This test demonstrates MTR-based rejection in nested sequences: if a previously successful decomposition path no longer works, the sequence rejects.
]]
print("    > DecomposeNestedCompoundSubtaskLoseToMTR_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task3.Name = "Test3"
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
table.insert(ctx.LastMTR, 1)
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 0)

--[[
Verifies that a Sequence rejects decomposition when a different nested selector's MTR choice fails.
Each selector in the task hierarchy contributes to the MTR path, and sequences must track all of them.
The LastMTR is [1, 0], but when decomposing, the second nested selector at index 0 fails and records -1.
This test demonstrates that MTR rejection cascades through sequence decomposition: one nested selector's failure rejects the entire sequence.
]]
print("    > DecomposeNestedCompoundSubtaskLoseToMTR2_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task3.Name = "Test3"
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task2:AddSubtask(task3)
task:AddSubtask(task2)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
table.insert(ctx.LastMTR, 2)
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 2)
assert(ctx.MethodTraversalRecord[2] == 0)

--[[
Verifies that a Sequence succeeds decomposition when nested selector MTR choices match and decompose successfully.
When the LastMTR indicates [1, 1] (second option at each selector level), and both nested selectors can decompose to those options, the sequence succeeds.
The plan includes Sub-task3 from the first selector and Sub-task4 from the sequence, matching the MTR-indicated choices.
This test demonstrates that sequences properly handle MTR-constrained decomposition when all nested selectors can satisfy the MTR path.
]]
print("    > DecomposeNestedCompoundSubtaskEqualToMTR_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task3.Name = "Test3"
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task2:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task2:AddSubtask(task3)
task:AddSubtask(task2)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
table.insert(ctx.LastMTR, 2)
table.insert(ctx.LastMTR, 2)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) == 2)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 2)
assert(ctx.MethodTraversalRecord[2] == 2)
assert("Sub-task3" == plan:pop().Name)
assert("Sub-task4" == plan:pop().Name)

--[[
Verifies that when a Sequence rejects decomposition due to MTR failure, all applied effects are rolled back to restore previous state.
Effects are applied during decomposition and tracked on the change stack for potential rollback if decomposition fails later.
When a nested selector rejects due to MTR conflict, all effects applied by previous subtasks must be undone to restore consistency.
This test demonstrates combined mechanics: MTR-based rejection coupled with state rollback, ensuring planning maintains a consistent state despite decomposition failures.
]]
print("    > DecomposeNestedCompoundSubtaskLoseToMTRReturnToPreviousWorldState_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.PlanAndExecute)
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
ctx:SetState(TestContext.TestEnum.StateC, true, sb_htn.Effects.EEffectType.PlanOnly)
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task3.Name = "Test3"
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
                                                function(context3, effectType)
                                                    context3:SetState(TestContext.TestEnum.StateA, false,
                                                                      sb_htn.Effects.EEffectType.PlanOnly)
                                                end))
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
                                                function(context4, effectType)
                                                    context4:SetState(TestContext.TestEnum.StateB, false,
                                                                      sb_htn.Effects.EEffectType.PlanOnly)
                                                end))
    return p
end)())
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
                                                function(context5, effectType)
                                                    context5:SetState(TestContext.TestEnum.StateA, false,
                                                                      sb_htn.Effects.EEffectType.PlanOnly)
                                                end))
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task5"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
                                                function(context6, effectType)
                                                    context6:SetState(TestContext.TestEnum.StateC, false,
                                                                      sb_htn.Effects.EEffectType.PlanOnly)
                                                end))
    return p
end)())
table.insert(ctx.LastMTR, 1)
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateC].list) == 1)
assert(1 == ctx:GetState(TestContext.TestEnum.StateA))
assert(1 == ctx:GetState(TestContext.TestEnum.StateB))
assert(1 == ctx:GetState(TestContext.TestEnum.StateC))

--[[
Verifies that when a Sequence fails decomposition due to nested sequence failure, all applied effects are rolled back.
Nested sequences themselves must decompose successfully for the outer sequence to continue.
When a deeply nested sequence fails (because its subtasks have failing conditions), all effects applied during attempts must be undone.
This test demonstrates comprehensive rollback: all effects applied during the entire failed decomposition attempt are rolled back, restoring the initial state exactly.
]]
print("    > DecomposeNestedCompoundSubtaskFailReturnToPreviousWorldState_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.PlanAndExecute)
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
ctx:SetState(TestContext.TestEnum.StateC, true, sb_htn.Effects.EEffectType.PlanOnly)
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task3.Name = "Test3"
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
                                                function(context7, effectType)
                                                    context7:SetState(TestContext.TestEnum.StateA, false,
                                                                      sb_htn.Effects.EEffectType.PlanOnly)
                                                end))
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
                                                function(context8, effectType)
                                                    context8:SetState(TestContext.TestEnum.StateB, false,
                                                                      sb_htn.Effects.EEffectType.PlanOnly)
                                                end))
    return p
end)())
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
                                                function(context9, effectType)
                                                    context9:SetState(TestContext.TestEnum.StateA, false,
                                                                      sb_htn.Effects.EEffectType.PlanOnly)
                                                end))
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task5"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
                                                function(context10, effectType)
                                                    context10:SetState(TestContext.TestEnum.StateC, false,
                                                                       sb_htn.Effects.EEffectType.PlanOnly)
                                                end))
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateC].list) == 1)
assert(1 == ctx:GetState(TestContext.TestEnum.StateA))
assert(1 == ctx:GetState(TestContext.TestEnum.StateB))
assert(1 == ctx:GetState(TestContext.TestEnum.StateC))

--[[
Verifies that a Sequence stops decomposition when encountering a PausePlanTask and returns a partial plan.
PausePlanTask is a special task that interrupts decomposition, allowing the planner to resume later at a specific point.
The sequence decomposes up to the pause point (Sub-task1), returns that as a plan, and queues the remaining decomposition for later resumption.
This test demonstrates partial planning: the planner can decompose incrementally, execute some tasks, and resume decomposition from a saved point.
]]
print("    > PausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:peek().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 1)
assert(task == ctx.PartialPlanQueue:peek().Task)
assert(3 == ctx.PartialPlanQueue:peek().TaskIndex)

--[[
Verifies that resuming a paused sequence decomposition continues from the saved point and completes the plan.
When a sequence is paused, the context maintains a queue of partially decomposed tasks with their resume indices.
Resuming decomposition resumes the paused sequence from the saved index, completing the remaining subtasks.
This test demonstrates the complete pause/resume cycle: pause to get Sub-task1, resume to decompose Sub-task2, combining for the full plan.
]]
print("    > ContinuePausedPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:pop().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 1)
assert(task == ctx.PartialPlanQueue:peek().Task)
assert(3 == ctx.PartialPlanQueue:peek().TaskIndex)
ctx.HasPausedPartialPlan = false
plan = Queue:new()
while (table.size(ctx.PartialPlanQueue.list) > 0) do
    local kvp = ctx.PartialPlanQueue:pop()
    local p = Queue:new()
    local s = kvp.Task:Decompose(ctx, kvp.TaskIndex, p)
    if (s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded or s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial) then
        while (table.size(p.list) > 0) do
            plan:push(p:pop())
        end
    end
end
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)

--[[
Verifies that pause points in nested tasks are queued in the correct order for later resumption.
When nested sequences encounter pause points, each pause level must maintain its own decomposition state.
The pause queue tracks multiple paused tasks: the innermost paused sequence task3 and the outer sequence task, enabling proper resumption order.
This test demonstrates pause point stacking: pauses at different nesting levels are queued and can be resumed in sequence to complete the entire plan.
]]
print("    > NestedPausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task3.Name = "Test3"
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task3:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:peek().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 2)
local queueAsArray = ctx.PartialPlanQueue.list
assert(task3 == queueAsArray[1].Task)
assert(3 == queueAsArray[1].TaskIndex)
assert(task == queueAsArray[2].Task)
assert(2 == queueAsArray[2].TaskIndex)

--[[
Verifies that resuming nested pause points decomposes in the correct order and produces the complete plan.
When resuming paused nested sequences, each pause level is resumed in the proper order (innermost first).
Resuming the innermost pause (task3 at index 2) produces Sub-task2, then continuing produces Sub-task4 from the outer sequence.
This test demonstrates complete nested pause/resume execution: pauses at multiple levels are resumed in sequence to produce the full plan incrementally.
]]
print("    > ContinueNestedPausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task3.Name = "Test3"
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task3:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:pop().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 2)
queueAsArray = ctx.PartialPlanQueue.list
assert(task3 == queueAsArray[1].Task)
assert(3 == queueAsArray[1].TaskIndex)
assert(task == queueAsArray[2].Task)
assert(2 == queueAsArray[2].TaskIndex)
ctx.HasPausedPartialPlan = false
plan = Queue:new()
while (table.size(ctx.PartialPlanQueue.list) > 0) do
    local kvp = ctx.PartialPlanQueue:pop()
    local p = Queue:new()
    local s = kvp.Task:Decompose(ctx, kvp.TaskIndex, p)
    if (s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded or s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial) then
        while (table.size(p.list) > 0) do
            plan:push(p:pop())
        end
    end
    if (ctx.HasPausedPartialPlan) then
        break
    end
end
assert(table.size(plan.list) == 2)
assert("Sub-task2" == plan:pop().Name)
assert("Sub-task4" == plan:pop().Name)

--[[
Verifies that multiple pause points at different nesting levels are correctly queued and resumed in proper order.
Partial planning with multiple pauses requires managing a stack of paused decomposition points at different levels.
The sequence encounters pauses at nested levels (task3 and task4), queueing them and resuming them in sequence to progressively expand the plan.
This test demonstrates multi-phase partial planning: pauses at different depths are resumed incrementally, eventually producing the complete plan across multiple decomposition phases.
]]
print("    > ContinueMultipleNestedPausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task3.Name = "Test3"
local task4 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task4.Name = "Test4"
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task3:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task3:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task4:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task5"
    return p
end)())
task4:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task4:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task6"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
task:AddSubtask(task4)
task:AddSubtask((function()
    local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task7"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:pop().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 2)
queueAsArray = ctx.PartialPlanQueue.list
assert(task3 == queueAsArray[1].Task)
assert(3 == queueAsArray[1].TaskIndex)
assert(task == queueAsArray[2].Task)
assert(2 == queueAsArray[2].TaskIndex)
ctx.HasPausedPartialPlan = false
plan = Queue:new()
while (table.size(ctx.PartialPlanQueue.list) > 0) do
    local kvp = ctx.PartialPlanQueue:pop()
    local p = Queue:new()
    local s = kvp.Task:Decompose(ctx, kvp.TaskIndex, p)
    if (s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded or s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial) then
        while (table.size(p.list) > 0) do
            plan:push(p:pop())
        end
    end
    if (ctx.HasPausedPartialPlan) then
        break
    end
end
assert(table.size(plan.list) == 3)
assert("Sub-task2" == plan:pop().Name)
assert("Sub-task4" == plan:pop().Name)
assert("Sub-task5" == plan:pop().Name)
ctx.HasPausedPartialPlan = false
plan = Queue:new()
while (table.size(ctx.PartialPlanQueue.list) > 0) do
    local kvp = ctx.PartialPlanQueue:pop()
    local p = Queue:new()
    local s = kvp.Task:Decompose(ctx, kvp.TaskIndex, p)
    if (s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded or s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial) then
        while (table.size(p.list) > 0) do
            plan:push(p:pop())
        end
    end
    if (ctx.HasPausedPartialPlan) then
        break
    end
end
assert(table.size(plan.list) == 2)
assert("Sub-task6" == plan:pop().Name)
assert("Sub-task7" == plan:pop().Name)