local sb_htn = require("sb_htn.interop")
local Queue = require("sb_htn.Utils.Queue")
local TestContext = require("sb_htn_tests.TestContext")

print("  > DomainTests")

--[[
Verifies that a Domain is created with a TaskRoot as its root task, initialized with the domain's name.
The domain is the top-level container for the entire HTN task hierarchy, and TaskRoot is the starting point for decomposition.
TaskRoot is a special compound task that serves as the root of the decomposition tree when the planner begins planning.
This test confirms that domains properly initialize their root task with the provided domain name for identification.
]]
print("    > DomainHasRootWithDomainName_ExpectedBehavior")
local domain = sb_htn.Domain:new(TestContext, "Test")
assert(table.size(domain.Root) > 0)
assert(domain.Root.Name == "Test")

--[[
Verifies that domain.Add correctly establishes parent-child relationships between tasks.
Add registers a task as a subtask of a parent task and sets up the parent reference.
This fluent API enables building task hierarchies where compound tasks contain subtasks that represent alternative or sequential decompositions.
This test confirms the foundational mechanism for constructing HTN task trees.
]]
print("    > AddSubtaskToParent_ExpectedBehavior")
domain = sb_htn.Domain:new(TestContext, "Test")
local task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
local task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Test"
domain:AddTask(task1, task2)
assert(function()
    for _, value in ipairs(task1.Subtasks) do if (value == task2) then return true end end
    return false
end)
assert(task2.Parent == task1)

--[[
Verifies that FindPlan throws a NullReferenceException when passed a null context parameter.
FindPlan requires a valid context to access world state and evaluate conditions during decomposition.
Passing null is a programming error that indicates the planner was not properly initialized.
This test ensures the domain fails fast with a clear exception rather than allowing silent failures.
]]
print("    > FindPlanNoCtxThrowsNRE_ExpectedBehavior")
domain = sb_htn.Domain:new(TestContext, "Test")
local plan = Queue:new()
if (pcall(function() domain:FindPlan(nil, plan) end)) then
    print("Exception not caught.")
end

--[[
Verifies that FindPlan throws an exception when the context has not been initialized by calling Init.
Init is required to set up the WorldStateChangeStack and other internal structures that FindPlan depends on.
Calling FindPlan without initialization indicates a setup error and should fail fast.
This test ensures the domain validates context state before attempting decomposition.
]]
print("    > FindPlanUninitializedContextThrowsException_ExpectedBehavior")
local ctx = TestContext:new()
domain = sb_htn.Domain:new(TestContext, "Test")
plan = Queue:new()
local status = false
if (pcall(function() status = domain:FindPlan(ctx, plan) end)) then
    assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
    assert(plan.list)
    assert(table.size(plan.list) == 0)
end

--[[
Verifies that FindPlan returns Rejected status and null plan when the domain has no tasks to decompose.
An empty domain with only a TaskRoot and no subtasks cannot produce a valid plan since there is no work to be done.
FindPlan returns Rejected to indicate that no viable plan could be constructed from the given domain structure.
This test demonstrates graceful handling of empty or invalid domain configurations.
]]
print("    > FindPlanNoTasksThenNullPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)

--[[
Verifies that FindPlan throws an exception when the context's MethodTraversalRecord is null.
MTR is used to track the path through selector decisions during decomposition and must be initialized before planning.
Without a valid MTR, the planner cannot track decomposition choices or compare plans via MTR equality.
This test ensures the domain validates critical planner state before attempting decomposition.
]]
print("    > MTRNullThrowsException_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.MethodTraversalRecord = {}
domain = sb_htn.Domain:new(TestContext, "Test")
plan = Queue:new()
status = domain:FindPlan(ctx, plan)

--[[
Verifies that FindPlan transitions the context state back to Executing after planning completes.
FindPlan sets context state to Planning during decomposition, then restores it to Executing afterward.
This ensures the context is in the correct state for the planner to begin executing the resulting plan.
This test confirms the planning-to-execution state transition is properly managed by the domain.
]]
print("    > AfterFindPlanContextStateIsExecuting_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(ctx.ContextState == sb_htn.Contexts.IContext.EContextState.Executing)

--[[
Verifies that FindPlan successfully decomposes a simple domain hierarchy into an executable plan.
FindPlan recursively decomposes compound tasks into primitive tasks, building a queue of primitive tasks ready for execution.
The resulting plan queue can be popped to execute tasks in order until completion.
This test demonstrates the fundamental planning operation where a domain specification becomes an executable task sequence.
]]
print("    > FindPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
domain:AddTask(domain.Root, task1)
domain:AddTask(task1, task2)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert(plan:peek().Name == "Sub-task")

--[[
Verifies that FindPlan correctly trims non-Permanent effects and applies only Permanent effects to world state after planning.
After successful planning, TrimForExecution removes PlanOnly effects (they're no longer needed) and transitions state changes to execution mode.
Permanent effects remain and propagate to the actual world state, while PlanAndExecute effects are cleaned from the stack.
This test demonstrates the effect handling during the transition from planning to execution phase.
]]
print("    > FindPlanTrimsNonPermanentStateChange_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task1"
task2:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect1", sb_htn.Effects.EEffectType.PlanOnly,
    function(context1, effectType1) context1:SetState(TestContext.TestEnum.StateA, true, effectType1) end))
local task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Sub-task2"
task3:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect2", sb_htn.Effects.EEffectType.PlanAndExecute,
    function(context2, effectType2) context2:SetState(TestContext.TestEnum.StateB, true, effectType2) end))
local task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task4.Name = "Sub-task3"
task4:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect3", sb_htn.Effects.EEffectType.Permanent,
    function(context3, effectType3) context3:SetState(TestContext.TestEnum.StateC, true, effectType3) end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1, task2)
domain:AddTask(task1, task3)
domain:AddTask(task1, task4)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateC].list) == 0)
assert(ctx.WorldState[TestContext.TestEnum.StateA] == 0)
assert(ctx.WorldState[TestContext.TestEnum.StateB] == 0)
assert(ctx.WorldState[TestContext.TestEnum.StateC] == 1)
assert(table.size(plan.list) == 3)

--[[
Verifies that when FindPlan fails to create a plan (Rejected status), all speculative state changes are cleared.
If planning fails, the world state and change stack must be restored to their original state before planning began.
This prevents failed planning attempts from corrupting the world state with partial effects.
This test confirms the rollback mechanism that ensures planning failures don't leave the context in an invalid state.
]]
print("    > FindPlanClearsStateChangeWhenPlanIsNull_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task1"
task2:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect1", sb_htn.Effects.EEffectType.PlanOnly,
    function(context4, effectType4) context4:SetState(TestContext.TestEnum.StateA, true, effectType4) end))
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Sub-task2"
task3:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect2", sb_htn.Effects.EEffectType.PlanAndExecute,
    function(context5, effectType5) context5:SetState(TestContext.TestEnum.StateB, true, effectType5) end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task4.Name = "Sub-task3"
task4:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect3", sb_htn.Effects.EEffectType.Permanent,
    function(context6, effectType6) context6:SetState(TestContext.TestEnum.StateC, true, effectType6) end))
local task5 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task5.Name = "Sub-task4"
task5:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context7) return context7.Done == true end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1, task2)
domain:AddTask(task1, task3)
domain:AddTask(task1, task4)
domain:AddTask(task1, task5)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateC].list) == 0)
assert(ctx.WorldState[TestContext.TestEnum.StateA] == 0)
assert(ctx.WorldState[TestContext.TestEnum.StateB] == 0)
assert(ctx.WorldState[TestContext.TestEnum.StateC] == 0)
assert(table.size(plan.list) == 0)

--[[
Verifies that FindPlan returns Rejected when the Method Traversal Record matches the previous plan's MTR.
MTR equality indicates that the new decomposition follows the same selector choices as the last plan, making them equivalent.
Returning the same plan repeatedly would create an infinite loop, so the planner must reject MTR-equal plans to force exploration of alternatives.
This test demonstrates the MTR-based plan comparison mechanism that prevents repetitive planning cycles.
]]
print("    > FindPlanIfMTRsAreEqualThenReturnNullPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
table.insert(ctx.LastMTR, 2)
table.insert(ctx.LastMTR, 1)
-- Root is a Selector that branch off into task1 selector or task2 sequence.
-- MTR only tracks decomposition of compound tasks, so our MTR is only 1 layer deep here,
-- Since both compound tasks decompose into primitive tasks.
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task1.Name = "Test1"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Sub-task1"
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context8) return context8.Done == true end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task4.Name = "Sub-task1"
task5 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task5.Name = "Sub-task2"
task5:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context9) return context9.Done == true end))
domain:AddTask(domain.Root, task1)
domain:AddTask(domain.Root, task2)
domain:AddTask(task1, task3)
domain:AddTask(task2, task4)
domain:AddTask(task2, task5)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == ctx.LastMTR[1])
assert(ctx.MethodTraversalRecord[2] == ctx.LastMTR[2])

--[[
Verifies that FindPlan treats plans with equal MTRs as equivalent even if their actual task sequences differ.
MTR equality is the primary metric for plan comparison; if MTRs are equal, the plans are considered equivalent from a planning perspective.
This prevents the planner from cycling between different permutations of the same decomposition choices.
This test confirms that MTR-based equivalence takes precedence over literal task sequence comparison.
]]
print("    > FindPlanIfPlansAreDifferentButMTRsAreEqualThenReturnNullPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
table.insert(ctx.LastMTR, 2)
table.insert(ctx.LastMTR, 1)
-- Root is a Selector that branch off into task1 selector or task2 sequence.
-- MTR tracks decomposition of compound tasks and priary tasks that are subtasks of selectors,
-- so our MTR is 2 layer deep.
domain = sb_htn.Domain:new(TestContext, "Test");
task1 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task1.Name = "Test1"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Sub-task1"
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context10) return context10.Done == true end));
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task4.Name = "Sub-task1"
task5 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task5.Name = "Sub-task2"
task5:AddCondition(sb_htn.Conditions.FuncCondition(TestContext, "TestCondition",
    function(context11) return context11.Done == true end))
domain:AddTask(domain.Root, task1);
domain:AddTask(domain.Root, task2);
domain:AddTask(task1, task3);
domain:AddTask(task2, task4);
domain:AddTask(task2, task5);
plan = Queue:new();
status = domain:FindPlan(ctx, plan);
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected);
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == ctx.LastMTR[1]);
assert(ctx.MethodTraversalRecord[2] == ctx.LastMTR[2]);

--[[
Verifies that FindPlan can find a better plan (with different MTR) when world state changes make it possible.
When the current MTR is equal to LastMTR, the plan is rejected. However, if world state changes cause a selector to make different choices,
the new MTR will differ and the new plan will be accepted if valid.
This test demonstrates the replanning mechanism: state changes can invalidate the last plan, requiring exploration of new decomposition paths.
]]
print("    > FindPlanIfSelectorFindBetterPrimaryTaskMTRChangeSuccessfully_ExpectedBehavior")
ctx = TestContext:new();
ctx:init();
table.insert(ctx.LastMTR, 1)
table.insert(ctx.LastMTR, 2)
-- Root is a Selector that branch off into two primary tasks.
-- We intend for task3 (Test Action B) to be selected in the first run,
-- but it will be a rejected plan because of LastMTR equality.
-- We then change the Done state to true before we do a replan,
-- and now we intend task 2 (Test Action A) to be selected, since its MTR beast LastMTR score.
domain = sb_htn.Domain(TestContext, "Test");
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test Select";
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Test Action A"
task2:AddCondition(sb_htn.Conditions.FuncCondition(TestContext, "Can choose A",
    function(context12) return context12.Done == true end));
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Test Action B"
task3:AddCondition(sb_htn.Conditions.FuncCondition(TestContext, "Can not choose A",
    function(context13) return context13.Done == false end));
domain:AddTask(domain.Root, task1);
domain:AddTask(task1, task2);
domain:AddTask(task1, task3);
-- We expect this to first get rejected, because LastMTR holds [0, 1] which is what we'll get back from the planner.
plan = Queue:new();
status = domain:FindPlan(ctx, plan);
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected);
assert(table.size(plan.list) == 0);
assert(table.size(ctx.MethodTraversalRecord) == 2);
assert(ctx.MethodTraversalRecord[1] == ctx.LastMTR[1]);
assert(ctx.MethodTraversalRecord[2] == ctx.LastMTR[2]);
-- When we change the condition to Done = true, we should now be able to find a better plan!
ctx.Done = true;
status = domain:FindPlan(ctx, plan);
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded);
assert(table.size(plan.list) > 0);
assert(table.size(ctx.MethodTraversalRecord) == 2);
assert(ctx.MethodTraversalRecord[1] == ctx.LastMTR[1]);
assert(ctx.MethodTraversalRecord[2] < ctx.LastMTR[2]);

--[[
Verifies that FindPlan returns Partial status when a PausePlanTask is encountered during decomposition.
PausePlanTask is a special task that pauses planning, returning control to allow task execution before continuing.
The context records the pause point with the task and subtask index, enabling continuation later.
This test demonstrates partial planning where the plan is returned in incremental chunks between pause points.
]]
print("    > PausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
local task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
local subtask1 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask1.Name = "Sub-task1"
local subtask2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask2.Name = "Sub-task2"
domain:AddTask(domain.Root, task)
domain:AddTask(task, subtask1)
domain:AddTask(task, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain:AddTask(task, subtask2)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(plan.list)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:peek().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 1)
assert(task == ctx.PartialPlanQueue:peek().Task)
assert(3 == ctx.PartialPlanQueue:peek().TaskIndex)

--[[
Verifies that calling FindPlan again after a pause resumes decomposition from the pause point.
The context's PartialPlanQueue tracks where decomposition paused, allowing FindPlan to resume and complete the remaining tasks.
This enables a two-phase execution model: execute some tasks, then plan the remaining tasks based on execution outcomes.
This test demonstrates continuation of partial plans and the completion of a paused decomposition.
]]
print("    > ContinuePausedPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
subtask1 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask1.Name = "Sub-task1"
subtask2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask2.Name = "Sub-task2"
domain:AddTask(domain.Root, task)
domain:AddTask(task, subtask1)
domain:AddTask(task, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain:AddTask(task, subtask2)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:pop().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 1)
assert(task == ctx.PartialPlanQueue:peek().Task)
assert(3 == ctx.PartialPlanQueue:peek().TaskIndex)
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)

--[[
Verifies that pauses work correctly with nested compound tasks, maintaining a queue of pause points at multiple nesting levels.
The PartialPlanQueue is a stack of pause points, each with the task and index where decomposition paused.
Nested decomposition can pause at multiple levels, and the queue tracks all pause points for proper resumption.
This test demonstrates partial planning with nested task hierarchies and multiple pause boundaries.
]]
print("    > NestedPausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task3.Name = "Test3"
subtask1 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask1.Name = "Sub-task1"
subtask2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask2.Name = "Sub-task2"
local subtask3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask3.Name = "Sub-task3"
local subtask4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask4.Name = "Sub-task4"
domain:AddTask(domain.Root, task)
domain:AddTask(task, task2)
domain:AddTask(task, subtask4)
domain:AddTask(task2, task3)
domain:AddTask(task2, subtask3)
domain:AddTask(task3, subtask1)
domain:AddTask(task3, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain:AddTask(task3, subtask1)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) > 0)
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
Verifies that resuming a nested paused plan correctly continues from all pause points in the queue.
When continuing, the pause queue is processed in order, resuming each paused task and collecting the remaining tasks.
This enables multi-level partial execution where different levels of the hierarchy can contribute tasks to the final plan.
This test demonstrates the full lifecycle of nested partial planning: pause, execute, resume, and completion.
]]
print("    > ContinueNestedPausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task3.Name = "Test3"
subtask1 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask1.Name = "Sub-task1"
subtask2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask2.Name = "Sub-task2"
subtask3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask3.Name = "Sub-task3"
subtask4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask4.Name = "Sub-task4"
domain:AddTask(domain.Root, task)
domain:AddTask(task, task2)
domain:AddTask(task, subtask4)
domain:AddTask(task2, task3)
domain:AddTask(task2, subtask3)
domain:AddTask(task3, subtask1)
domain:AddTask(task3, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain:AddTask(task3, subtask2)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:pop().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 2)
queueAsArray = ctx.PartialPlanQueue.list
assert(task3 == queueAsArray[1].Task)
assert(3 == queueAsArray[1].TaskIndex)
assert(task == queueAsArray[2].Task)
assert(2 == queueAsArray[2].TaskIndex)
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 2)
assert("Sub-task2" == plan:pop().Name)
assert("Sub-task4" == plan:pop().Name)

--[[
Verifies that multiple pause points at different nesting levels are correctly queued and resumed in the proper order.
Partial planning enables breaking decomposition into multiple planning phases via PausePlanTask, where paused decomposition points are stacked.
When multiple compound tasks have pause points at different nesting levels, the context maintains a stack of pending partial plans that must be resumed in the correct order (innermost depth first, then backing up to outer levels).
This test demonstrates that the planner correctly manages deep nesting scenarios with multiple pause points, resuming each paused decomposition from the correct task in the correct execution order, ultimately producing a complete plan when all pauses are resumed.
]]
print("    > ContinueMultipleNestedPausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task3.Name = "Test3"
task4 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task4.Name = "Test4"
subtask1 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask1.Name = "Sub-task1"
subtask2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask2.Name = "Sub-task2"
subtask3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask3.Name = "Sub-task3"
subtask4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask4.Name = "Sub-task4"
local subtask5 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask5.Name = "Sub-task5"
local subtask6 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask6.Name = "Sub-task6"
local subtask7 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask7.Name = "Sub-task7"
domain:AddTask(domain.Root, task)
domain:AddTask(task3, subtask1)
domain:AddTask(task3, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain:AddTask(task3, subtask2)
domain:AddTask(task2, task3)
domain:AddTask(task2, subtask3)
domain:AddTask(task4, subtask5)
domain:AddTask(task4, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain:AddTask(task4, subtask6)
domain:AddTask(task, task2)
domain:AddTask(task, subtask4)
domain:AddTask(task, task4)
domain:AddTask(task, subtask7)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:pop().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 2)
queueAsArray = ctx.PartialPlanQueue.list
assert(task3 == queueAsArray[1].Task)
assert(3 == queueAsArray[1].TaskIndex)
assert(task == queueAsArray[2].Task)
assert(2 == queueAsArray[2].TaskIndex)
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 3)
assert("Sub-task2" == plan:pop().Name)
assert("Sub-task4" == plan:pop().Name)
assert("Sub-task5" == plan:pop().Name)
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 2)
assert("Sub-task6" == plan:pop().Name)
assert("Sub-task7" == plan:pop().Name)
