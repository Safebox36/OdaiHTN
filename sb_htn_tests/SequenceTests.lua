local sb_htn = require("sb_htn.interop")
local Queue = require("sb_htn.Utils.Queue")
local TestContext = require("sb_htn_tests.TestContext")

print(">>> SequenceTests")

print("> AddCondition_ExpectedBehavior")
local task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
local t = task:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context1) return context1.Done == false end))
assert(t == task)
assert(table.size(task.Conditions) == 1)

print("> AddSubtask_ExpectedBehavior")
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
t = task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task"
    return p
end)())
assert(t == task)
assert(table.size(task.Subtasks) == 1)

print("> IsValidFailsWithoutSubtasks_ExpectedBehavior")
local ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
assert(task:IsValid(ctx) == false)

print("> IsValid_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task"
    return p
end)())
assert(task:IsValid(ctx))

print("> DecomposeRequiresContextInitFails_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
local plan = Queue:new()
if (pcall(function() task:Decompose(ctx, 1, plan) end)) then
    print("Exception not caught.")
end

print("> DecomposeWithNoSubtasks_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
plan = Queue:new()
local status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)

print("> DecomposeWithSubtasks_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) == 2)
assert("Sub-task1" == plan:peek().Name)

print("> DecomposeNestedSubtasks_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
local task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
local task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task3.Name = "Test3"
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) == 2)
assert("Sub-task2" == plan:pop().Name)
assert("Sub-task4" == plan:pop().Name)

print("> DecomposeWithSubtasksOneFail_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)

print("> DecomposeWithSubtasksCompoundSubtaskFails_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function() local s = sb_htn.Tasks.CompoundTasks.Selector:new()
    s.Name = "Sub-task1"
    return s
end)())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)

print("> DecomposeFailureReturnToPreviousWorldState_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.PlanAndExecute)
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
ctx:SetState(TestContext.TestEnum.StateC, true, sb_htn.Effects.EEffectType.PlanOnly)
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
        function(context2, effectType) context2:SetState(TestContext.TestEnum.StateA, false,
                sb_htn.Effects.EEffectType.PlanOnly)
        end))
    return p
end)())
task:AddSubtask((function() local s = sb_htn.Tasks.CompoundTasks.Selector:new()
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

print("> DecomposeNestedCompoundSubtaskLoseToMTR_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task3.Name = "Test3"
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
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

print("> DecomposeNestedCompoundSubtaskLoseToMTR2_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task3.Name = "Test3"
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task2:AddSubtask(task3)
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
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

print("> DecomposeNestedCompoundSubtaskEqualToMTR_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task3.Name = "Test3"
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task2:AddSubtask(task3)
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
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

print("> DecomposeNestedCompoundSubtaskLoseToMTRReturnToPreviousWorldState_ExpectedBehavior")
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
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
        function(context3, effectType) context3:SetState(TestContext.TestEnum.StateA, false,
                sb_htn.Effects.EEffectType.PlanOnly)
        end))
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
        function(context4, effectType) context4:SetState(TestContext.TestEnum.StateB, false,
                sb_htn.Effects.EEffectType.PlanOnly)
        end))
    return p
end)())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
        function(context5, effectType) context5:SetState(TestContext.TestEnum.StateA, false,
                sb_htn.Effects.EEffectType.PlanOnly)
        end))
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task5"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
        function(context6, effectType) context6:SetState(TestContext.TestEnum.StateC, false,
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

print("> DecomposeNestedCompoundSubtaskFailReturnToPreviousWorldState_ExpectedBehavior")
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
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    p:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context) return context.Done == true end))
    return p
end)())
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
        function(context7, effectType) context7:SetState(TestContext.TestEnum.StateA, false,
                sb_htn.Effects.EEffectType.PlanOnly)
        end))
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
        function(context8, effectType) context8:SetState(TestContext.TestEnum.StateB, false,
                sb_htn.Effects.EEffectType.PlanOnly)
        end))
    return p
end)())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
        function(context9, effectType) context9:SetState(TestContext.TestEnum.StateA, false,
                sb_htn.Effects.EEffectType.PlanOnly)
        end))
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task5"
    p:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.Permanent,
        function(context10, effectType) context10:SetState(TestContext.TestEnum.StateC, false,
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

print("> PausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
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

print("> ContinuePausedPlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
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
    if (
        s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded or
            s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial) then
        while (table.size(p.list) > 0) do
            plan:push(p:pop())
        end
    end
end
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)

print("> NestedPausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task3.Name = "Test3"
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task3:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
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

print("> ContinueNestedPausePlan_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Sequence:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Sequence:new()
task3.Name = "Test3"
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task3:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
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
    if (
        s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded or
            s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial) then
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

print("> ContinueMultipleNestedPausePlan_ExpectedBehavior")
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
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)())
task3:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task2:AddSubtask(task3)
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
task4:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task5"
    return p
end)())
task4:AddSubtask(sb_htn.Tasks.CompoundTasks.PausePlanTask:new())
task4:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task6"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
task:AddSubtask(task4)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
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
    if (
        s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded or
            s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial) then
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
    if (
        s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded or
            s == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Partial) then
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
