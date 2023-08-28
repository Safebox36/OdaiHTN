local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")
local TestOperator = require("sb_htn_tests.TestOperator")

print(">>> PlannerTests")

print("> GetPlanReturnsClearInstanceAtStart_ExpectedBehavior")
local planner = sb_htn.Planners.Planner:new(TestContext)
local plan = planner:GetPlan()
assert(table.size(plan.list) == 0)

print("> GetCurrentTaskReturnsNullAtStart_ExpectedBehavior")
planner = sb_htn.Planners.Planner:new(TestContext)
local task = planner:GetCurrentTask()
assert(task == nil)

print("> TickWithNullParametersThrowsNRE_ExpectedBehavior")
planner = sb_htn.Planners.Planner:new(TestContext)
if (pcall(function() planner:Tick(nil) end)) then
    print("Exception not caught.")
end

print("> TickWithNullDomainThrowsException_ExpectedBehavior")
local ctx = TestContext:new()
planner = sb_htn.Planners.Planner:new(TestContext)
if (pcall(function() planner:Tick(nil, ctx) end)) then
    print("Exception not caught.")
end

print("> TickWithoutInitializedContextThrowsException_ExpectedBehavior")
ctx = TestContext:new()
local domain = sb_htn.Domain:new(TestContext, "Test")
planner = sb_htn.Planners.Planner:new(TestContext)
if (pcall(function() planner:Tick(domain, ctx) end)) then
    print("Exception not caught.")
end

print("> TickWithEmptyDomain_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
domain = sb_htn.Domain:new(TestContext, "Test")
planner = sb_htn.Planners.Planner:new(TestContext)
planner:Tick(domain, ctx)

print("> TickWithPrimitiveTaskWithoutOperator_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
local task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
local task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
planner:Tick(domain, ctx)
local currentTask = planner:GetCurrentTask()
assert(currentTask == nil)
assert(planner.LastStatus == sb_htn.Tasks.ETaskStatus.Failure)

print("> TickWithFuncOperatorWithNullFunc_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext))
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
planner:Tick(domain, ctx)
currentTask = planner:GetCurrentTask()
assert(currentTask == nil)
assert(planner.LastStatus == sb_htn.Tasks.ETaskStatus.Failure)

print("> TickWithDefaultSuccessOperatorWontStackOverflows_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context1) return sb_htn.Tasks.ETaskStatus.Success end, nil,
    TestContext))
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
planner:Tick(domain, ctx)
currentTask = planner:GetCurrentTask()
assert(currentTask == nil)
assert(planner.LastStatus == sb_htn.Tasks.ETaskStatus.Success)

print("> TickWithDefaultContinueOperator_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context2) return sb_htn.Tasks.ETaskStatus.Continue end))
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
planner:Tick(domain, ctx)
currentTask = planner:GetCurrentTask()
assert(currentTask ~= nil)
assert(planner.LastStatus == sb_htn.Tasks.ETaskStatus.Continue)

print("> OnNewPlan_ExpectedBehavior")
local test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnNewPlan = function(p) test = table.size(p.list) == 1 end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context3) return sb_htn.Tasks.ETaskStatus.Continue end))
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
planner:Tick(domain, ctx)
assert(test)

print("> OnReplacePlan_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnReplacePlan = function(op, ct, p) test = table.size(op.list) == 0 and ct ~= nil and table.size(p.list) == 1 end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test1"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
local task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Sub-task1"
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context18) return context18.Done == false end))
local task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task4.Name = "Sub-task2"
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context4) return sb_htn.Tasks.ETaskStatus.Continue end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context5) return sb_htn.Tasks.ETaskStatus.Continue end))
domain.AddTask(domain.Root, task1)
domain.AddTask(domain.Root, task2)
domain.AddTask(task1, task3)
domain.AddTask(task2, task4)
ctx.Done = true
planner:Tick(domain, ctx)
ctx.Done = false
ctx.IsDirty = true
planner:Tick(domain, ctx)
assert(test)

print("> OnNewTask_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnNewTask = function(t1) test = t1.Name == "Sub-task" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context6) return sb_htn.Tasks.ETaskStatus.Continue end))
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
planner:Tick(domain, ctx)
assert(test)

print("> OnNewTaskConditionFailed_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnNewTaskConditionFailed = function(t2, c1) test = t2.Name == "Sub-task1" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test1"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Sub-task1"
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context19) return context19.Done == false end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task4.Name = "Sub-task2"
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context7) return sb_htn.Tasks.ETaskStatus.Success end, nil,
    TestContext))
-- Note that one should not use AddEffect on types that's not part of WorldState unless you
-- know what you're doing. Outside of the WorldState, we don't get automatic trimming of
-- state change. This method is used here only to invoke the desired callback, not because
-- its correct practice.
task3:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.PlanAndExecute,
    function(context23, effectType) context23.Done = true end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context8) return sb_htn.Tasks.ETaskStatus.Continue end))
domain.AddTask(domain.Root, task1)
domain.AddTask(domain.Root, task2)
domain.AddTask(task1, task3)
domain.AddTask(task2, task4)
ctx.Done = true
planner:Tick(domain, ctx)
ctx.Done = false
ctx.IsDirty = true
planner:Tick(domain, ctx)
assert(test)

print("> OnStopCurrentTask_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnStopCurrentTask = function(t3) test = t3.Name == "Sub-task2" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test1"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Sub-task1"
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context20) return context20.Done == false end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task4.Name = "Sub-task2"
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context9) return sb_htn.Tasks.ETaskStatus.Continue end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context10) return sb_htn.Tasks.ETaskStatus.Continue end))
domain.AddTask(domain.Root, task1)
domain.AddTask(domain.Root, task2)
domain.AddTask(task1, task3)
domain.AddTask(task2, task4)
ctx.Done = true
planner:Tick(domain, ctx)
ctx.Done = false
ctx.IsDirty = true
planner:Tick(domain, ctx)
assert(test)

print("> OnCurrentTaskCompletedSuccessfully_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnCurrentTaskCompletedSuccessfully = function(t4) test = t4.Name == "Sub-task1" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test1"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Sub-task1"
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context21) return context21.Done == false end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task4.Name = "Sub-task2"
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context11) return sb_htn.Tasks.ETaskStatus.Success end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context12) return sb_htn.Tasks.ETaskStatus.Continue end))
domain.AddTask(domain.Root, task1)
domain.AddTask(domain.Root, task2)
domain.AddTask(task1, task3)
domain.AddTask(task2, task4)
ctx.Done = true
planner:Tick(domain, ctx)
ctx.Done = false
ctx.IsDirty = true
planner:Tick(domain, ctx)
assert(test)

print("> OnApplyEffect_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnApplyEffect = function(e) test = e.Name == "TestEffect" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test1"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task2.Name = "Test2"
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task3.Name = "Sub-task1"
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context22) return not context22:HasState(TestContext.TestEnum.StateA) end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task4.Name = "Sub-task2"
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context13) return sb_htn.Tasks.ETaskStatus.Success end))
task3:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.PlanAndExecute,
    function(context24, effectType) context24:SetState(TestContext.TestEnum.StateA, true, effectType) end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context14) return sb_htn.Tasks.ETaskStatus.Continue end))
domain.AddTask(domain.Root, task1)
domain.AddTask(domain.Root, task2)
domain.AddTask(task1, task3)
domain.AddTask(task2, task4)
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, ctx)
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
ctx:SetState(TestContext.TestEnum.StateA, false, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, ctx)
assert(test)

print("> OnCurrentTaskFailed_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnCurrentTaskFailed = function(t5) test = t5.Name == "Sub-task" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context15) return sb_htn.Tasks.ETaskStatus.Failure end))
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
planner:Tick(domain, ctx)
assert(test)

print("> OnCurrentTaskContinues_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnCurrentTaskContinues = function(t6) test = t6.Name == "Sub-task" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context16) return sb_htn.Tasks.ETaskStatus.Continue end))
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
planner:Tick(domain, ctx)
assert(test)

print("> OnCurrentTaskExecutingConditionFailed_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
planner.OnCurrentTaskExecutingConditionFailed = function(t7, c2) test = t7.Name == "Sub-task" and
        c2.Name == "TestCondition"
end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new()
task1.Name = "Test"
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
task2.Name = "Sub-task"
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context17) return sb_htn.Tasks.ETaskStatus.Continue end))
task2:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context25) return context25.Done end))
domain.AddTask(domain.Root, task1)
domain.AddTask(task1, task2)
planner:Tick(domain, ctx)
assert(test)

print("> FindPlanIfConditionChangeAndOperatorIsContinuous_ExpectedBehavior")
ctx = TestContext()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
local select = sb_htn.Tasks.CompoundTasks.Selector:new()
select.Name = "Test Select"
local actionA = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
actionA.Name = "Test Action A"
actionA:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A",
    function(context26) return context26.Done == true end))
actionA:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A",
    function(context27) return context27.Done == true end))
actionA:SetOperator(TestOperator:new())
local actionB = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
actionB.Name = "Test Action B"
actionB:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A",
    function(context28) return context28.Done == false end))
actionB:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A",
    function(context29) return context29.Done == false end))
actionB:SetOperator(TestOperator:new())
domain.AddTask(domain.Root, select)
domain.AddTask(select, actionA)
domain.AddTask(select, actionB)
planner:Tick(domain, ctx, false)
plan = planner:GetPlan()
currentTask = planner:GetCurrentTask()
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action B")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)
-- When we change the condition to Done = true, we should now be able to find a better plan!
ctx.Done = true
planner:Tick(domain, ctx, true)
plan = planner:GetPlan()
currentTask = planner:GetCurrentTask()
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action A")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 1)

print("> FindPlanIfWorldStateChangeAndOperatorIsContinuous_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
select = sb_htn.Tasks.CompoundTasks.Selector:new()
select.Name = "Test Select"
actionA = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
actionA.Name = "Test Action A"
actionA:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A",
    function(context30) return context30:GetState(TestContext.TestEnum.StateA) == 1 end))
actionA:SetOperator(TestOperator:new())
actionB = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
actionB.Name = "Test Action B"
actionB:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A",
    function(context31) return context31:GetState(TestContext.TestEnum.StateA) == 0 end))
actionB:SetOperator(TestOperator:new())
domain.AddTask(domain.Root, select)
domain.AddTask(select, actionA)
domain.AddTask(select, actionB)
planner:Tick(domain, ctx, false)
plan = planner:GetPlan()
currentTask = planner:GetCurrentTask()
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action B")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)
-- When we change the condition to Done = true, we should now be able to find a better plan!
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, ctx, true)
plan = planner:GetPlan()
currentTask = planner:GetCurrentTask()
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action A")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 1)

print("> FindPlanIfWorldStateChangeToWorseMRTAndOperatorIsContinuous_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
select = sb_htn.Tasks.CompoundTasks.Selector:new()
select.Name = "Test Select"
actionA = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
actionA.Name = "Test Action A"
actionA:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A",
    function(context32) return context32:GetState(TestContext.TestEnum.StateA) == 0 end))
actionA:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A",
    function(context33) return context33:GetState(TestContext.TestEnum.StateA) == 0 end))
actionA:SetOperator(TestOperator:new())
actionB = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
actionB.Name = "Test Action B"
actionB:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A",
    function(context34) return context34:GetState(TestContext.TestEnum.StateA) == 1 end))
actionB:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A",
    function(context35) return context35:GetState(TestContext.TestEnum.StateA) == 1 end))
actionB:SetOperator(TestOperator:new())
domain.AddTask(domain.Root, select)
domain.AddTask(select, actionA)
domain.AddTask(select, actionB)
planner:Tick(domain, ctx, false)
plan = planner:GetPlan()
currentTask = planner:GetCurrentTask()
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action A")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 1)
-- When we change the condition to Done = true, the first plan should no longer be allowed, we should find the second plan instead!
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, ctx, true)
plan = planner:GetPlan()
currentTask = planner:GetCurrentTask()
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action B")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)
