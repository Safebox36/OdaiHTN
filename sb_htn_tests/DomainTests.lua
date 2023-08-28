local sb_htn = require("sb_htn.interop")
local Queue = require("sb_htn.Utils.Queue")
local TestContext = require("sb_htn_tests.TestContext")

print(">>> DomainTests")

print("> DomainHasRootWithDomainName_ExpectedBehavior")
local domain = sb_htn.Domain:new(TestContext, "Test")
assert(table.size(domain.Root) > 0)
assert(domain.Root.Name == "Test")

print("> AddSubtaskToParent_ExpectedBehavior")
domain = sb_htn.Domain:new(TestContext, "Test")
local task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
local task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Test"
domain.AddTask(task1, task2)
assert(function()
    for _, value in ipairs(task1.Subtasks) do if (value == task2) then return true end end
    return false
end)
assert(task2.Parent == task1)

print("> FindPlanNoCtxThrowsNRE_ExpectedBehavior")
domain = sb_htn.Domain:new(TestContext, "Test")
local plan = Queue:new()
if (pcall(function() domain:FindPlan(nil, plan) end)) then
    print("Exception not caught.")
end

print("> FindPlanUninitializedContextThrowsException_ExpectedBehavior")
local ctx = TestContext:new()
domain = sb_htn.Domain:new(TestContext, "Test")
plan = Queue:new()
local status = false
if (pcall(function() status = domain:FindPlan(ctx, plan) end)) then
    assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
    assert(table.size(plan.list) > 0)
    assert(table.size(plan.list) == 0)
end

print("> FindPlanNoTasksThenNullPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)

print("> MTRNullThrowsException_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.MethodTraversalRecord = {}
domain = sb_htn.Domain:new(TestContext, "Test")
plan = Queue:new()
status = domain:FindPlan(ctx, plan)

print("> AfterFindPlanContextStateIsExecuting_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(ctx.ContextState == sb_htn.Contexts.IContext.EContextState.Executing)

print("> FindPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert(plan:peek().Name == "Sub-task")

print("> FindPlanTrimsNonPermanentStateChange_ExpectedBehavior")
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
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
domain.AddTask(task1, task3)
domain.AddTask(task1, task4)
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

print("> FindPlanClearsStateChangeWhenPlanIsNull_ExpectedBehavior")
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
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
domain.AddTask(task1, task3)
domain.AddTask(task1, task4)
domain.AddTask(task1, task5)
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

print("> FindPlanIfMTRsAreEqualThenReturnNullPlan_ExpectedBehavior")
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
local task6 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task6.Name = "Sub-task3"
domain.AddTask(domain.Root, task1)
domain.AddTask(domain.Root, task2)
domain.AddTask(task1, task3)
domain.AddTask(task2, task4)
domain.AddTask(task2, task5)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == ctx.LastMTR[1])
assert(ctx.MethodTraversalRecord[2] == ctx.LastMTR[2])

print("> PausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
local task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
local subtask1 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask1.Name = "Sub-task1"
local subtask2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask2.Name = "Sub-task2"
domain.AddTask(domain.Root, task)
domain.AddTask(task, subtask1)
domain.AddTask(task, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain.AddTask(task, subtask2)
plan = Queue:new()
status = domain:FindPlan(ctx, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:peek().Name)
assert(ctx.HasPausedPartialPlan)
assert(table.size(ctx.PartialPlanQueue.list) == 1)
assert(task == ctx.PartialPlanQueue:peek().Task)
assert(3 == ctx.PartialPlanQueue:peek().TaskIndex)

print("> ContinuePausedPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
subtask1 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask1.Name = "Sub-task1"
subtask2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
subtask2.Name = "Sub-task2"
domain.AddTask(domain.Root, task)
domain.AddTask(task, subtask1)
domain.AddTask(task, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain.AddTask(task, subtask2)
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

print("> NestedPausePlan_ExpectedBehavior")
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
domain.AddTask(domain.Root, task)
domain.AddTask(task, task2)
domain.AddTask(task, subtask4)
domain.AddTask(task2, task3)
domain.AddTask(task2, subtask3)
domain.AddTask(task3, subtask1)
domain.AddTask(task3, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain.AddTask(task3, subtask1)
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

print("> ContinueNestedPausePlan_ExpectedBehavior")
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
domain.AddTask(domain.Root, task)
domain.AddTask(task, task2)
domain.AddTask(task, subtask4)
domain.AddTask(task2, task3)
domain.AddTask(task2, subtask3)
domain.AddTask(task3, subtask1)
domain.AddTask(task3, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain.AddTask(task3, subtask2)
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

print("> ContinueMultipleNestedPausePlan_ExpectedBehavior")
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
domain.AddTask(domain.Root, task)
domain.AddTask(task3, subtask1)
domain.AddTask(task3, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain.AddTask(task3, subtask2)
domain.AddTask(task2, task3)
domain.AddTask(task2, subtask3)
domain.AddTask(task4, subtask5)
domain.AddTask(task4, sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
domain.AddTask(task4, subtask6)
domain.AddTask(task, task2)
domain.AddTask(task, subtask4)
domain.AddTask(task, task4)
domain.AddTask(task, subtask7)
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
