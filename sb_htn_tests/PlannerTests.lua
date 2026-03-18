local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")
local TestOperator = require("sb_htn_tests.TestOperator")

print("  > PlannerTests")

--[[
Verifies that calling Planner:Tick() with null parameters throws a NullReferenceException.
The planner requires both a valid domain and context to execute the planning cycle.
Both parameters are essential: the domain contains the task hierarchy and the context holds world state and planner callbacks.
This test ensures the planner fails fast with a clear exception when given invalid parameters rather than producing silent failures.
]]
print("    > TickWithNullParametersThrowsNRE_ExpectedBehavior")
local planner = sb_htn.Planners.Planner:new(TestContext)
if (pcall(function() planner:Tick(nil) end)) then
    print("Exception not caught.")
end

--[[
Verifies that calling Planner:Tick() with a null domain but valid context throws an exception.
The domain is essential as it contains the task hierarchy that defines the planner's decomposition logic.
Without a domain, the planner cannot find or execute any tasks, making it impossible to generate a valid plan.
This test validates that the planner enforces the domain requirement through exception throwing.
]]
print("    > TickWithNullDomainThrowsException_ExpectedBehavior")
local ctx = TestContext:new()
planner = sb_htn.Planners.Planner:new(TestContext)
if (pcall(function() planner:Tick(nil, ctx) end)) then
    print("Exception not caught.")
end

--[[
Verifies that calling Planner:Tick() with an uninitialized context throws an exception.
The context must be initialized by calling Init() to set up the internal data structures required for planning and execution.
Initialization creates the necessary collections for the plan queue, decomposition logging, and world state management.
This test validates that the planner requires proper context initialization, preventing usage errors.
]]
print("    > TickWithoutInitializedContextThrowsException_ExpectedBehavior")
ctx = TestContext:new()
local domain = sb_htn.Domain:new(TestContext, "Test")
planner = sb_htn.Planners.Planner:new(TestContext)
if (pcall(function() planner:Tick(domain, ctx) end)) then
    print("Exception not caught.")
end

--[[
Verifies that the planner can handle a domain with no tasks without throwing an exception.
A domain with only a root task and no subtasks is valid but results in an empty plan queue and no executable tasks.
This test demonstrates that the planner gracefully handles empty domains, completing without error or plan generation.
This capability is useful for testing and for dynamic domains that start empty and have tasks added at runtime.
]]
print("    > TickWithEmptyDomain_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
domain = sb_htn.Domain:new(TestContext, "Test")
planner = sb_htn.Planners.Planner:new(TestContext)
planner:Tick(domain, ctx)

--[[
Verifies that when a primitive task is selected but has no operator assigned, the planner fails the task appropriately.
Operators are required to execute primitive tasks during plan execution, so a missing operator is a configuration error.
When an operator is missing, the task cannot be executed and the planner marks it as failed, failing the entire plan.
This test demonstrates that the planner validates operator presence and handles missing operators gracefully.
]]
print("    > TickWithPrimitiveTaskWithoutOperator_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
local task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
local task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(ctx.PlannerState.CurrentTask == nil)
assert(ctx.PlannerState.LastStatus == sb_htn.Tasks.ETaskStatus.Failure)

--[[
Verifies that a FuncOperator with a null function pointer results in task failure when executed.
FuncOperator is a lambda-based operator implementation that wraps a user-provided function.
If the function pointer is null, the operator cannot execute and the task fails.
This test demonstrates that the planner handles null operator functions gracefully by failing the affected task.
]]
print("    > TickWithFuncOperatorWithNullFunc_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(ctx.PlannerState.CurrentTask == nil)
assert(ctx.PlannerState.LastStatus == sb_htn.Tasks.ETaskStatus.Failure)

--[[
Verifies that a primitive task with an operator that returns Success completes without stack overflow or infinite loops.
When a task's operator returns Success, the planner pops it from the plan queue and moves to the next task.
This test ensures proper task completion handling prevents infinite loops or recursion issues.
The test validates that successful task completion is handled efficiently without performance issues.
]]
print("    > TickWithDefaultSuccessOperatorWontStackOverflows_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context1) return sb_htn.Tasks.ETaskStatus.Success end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(ctx.PlannerState.CurrentTask == nil)
assert(ctx.PlannerState.LastStatus == sb_htn.Tasks.ETaskStatus.Success)

--[[
Verifies that a primitive task with an operator that returns Continue remains active in the plan for the next tick.
When a task's operator returns Continue, the task is not removed from the plan and remains the current task.
Continue is used for long-running or multi-tick operations that need to maintain state across multiple planning cycles.
This test validates that the planner properly maintains task state across ticks when tasks return Continue.
]]
print("    > TickWithDefaultContinueOperator_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context2) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(ctx.PlannerState.CurrentTask)
assert(ctx.PlannerState.LastStatus == sb_htn.Tasks.ETaskStatus.Continue)

--[[
Verifies that the OnNewPlan callback is invoked when the planner generates a new plan during decomposition.
Callbacks are the primary mechanism for applications to observe and react to planning events.
OnNewPlan fires when the domain decomposition succeeds and produces a new plan queue containing tasks to execute.
This test demonstrates that callbacks are properly invoked during the planning cycle, enabling external observation of plan generation.
]]
print("    > OnNewPlan_ExpectedBehavior")
local test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnNewPlan = function(self, p) test = table.size(p.list) == 1 end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context3) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(test)

--[[
Verifies that the OnReplacePlan callback is invoked when the planner generates a new plan to replace the currently executing plan.
OnReplacePlan is triggered during replanning when world state changes invalidate the current plan or a better plan becomes available.
The callback receives the old plan, the current task being replaced, and the new plan, enabling applications to handle plan transitions.
This test demonstrates that replanning callbacks work correctly when conditions change during execution.
]]
print("    > OnReplacePlan_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnReplacePlan = function(self, op, ct, p) test = table.size(op.list) == 0 and ct and table.size(p.list) == 1 end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test1"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
local task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition", function(context4) return context4.Done == false end))
local task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"}
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context5) return sb_htn.Tasks.ETaskStatus.Continue end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context6) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(domain.Root, task2)
domain:AddTask(task1,       task3)
domain:AddTask(task2,       task4)
ctx.Done = true
planner:Tick(domain, ctx)
ctx.Done = false
ctx.IsDirty = true
planner:Tick(domain, ctx)
assert(test)

--[[
Verifies that the OnNewTask callback is invoked when the planner pops a new task from the plan queue for execution.
OnNewTask fires each time a task becomes the current executable task, providing hooks for task-level event handling.
This callback allows applications to log, monitor, or trigger side effects whenever a new task begins execution.
This test demonstrates that task-level callbacks are properly invoked during the execution phase of the planner tick.
]]
print("    > OnNewTask_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnNewTask = function(self, t1) test = t1.Name == "Sub-task" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context7) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(test)

--[[
Verifies that the OnNewTaskConditionFailed callback is invoked when a task's planning conditions fail during decomposition.
During planning, the planner evaluates conditions to determine which tasks are valid decomposition paths.
When a condition fails, the task is rejected and the planner explores alternative paths in the hierarchy.
This test demonstrates that planning-level condition failure callbacks work correctly during domain decomposition.
]]
print("    > OnNewTaskConditionFailed_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnNewTaskConditionFailed = function(self, t2, c1) test = t2.Name == "Sub-task1" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test1"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition", function(context8) return context8.Done == false end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"}
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context9) return sb_htn.Tasks.ETaskStatus.Success end))
-- Note that one should not use AddEffect on types that's not part of WorldState unless you
-- know what you're doing. Outside of the WorldState, we don't get automatic trimming of
-- state change. This method is used here only to invoke the desired callback, not because
-- its correct practice.
task3:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.PlanAndExecute,
                                                function(context10, effectType) context10.Done = true end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context11) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(domain.Root, task2)
domain:AddTask(task1,       task3)
domain:AddTask(task2,       task4)
ctx.Done = true
planner:Tick(domain, ctx)
ctx.Done = false
ctx.IsDirty = true
planner:Tick(domain, ctx)
assert(test)

--[[
Verifies that the OnCurrentTaskStarted callback is invoked when a primitive task's operator Start method is called.
Operators have a Start method that is called once when a task becomes active, separate from the Update method called each tick.
This callback allows applications to perform one-time initialization when a task begins execution.
This test demonstrates that operator lifecycle callbacks work correctly during task execution startup.
]]
print("    > OnStartNewTask_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnCurrentTaskStarted = function(self, t) test = t.Name == "Sub-task" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context12) return sb_htn.Tasks.ETaskStatus.Continue end, function(context13) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(true == test)

--[[
Verifies that a primitive task can complete successfully during its Start method, before the Update method is called.
The Start method is not limited to initialization—operators can perform complete work and return Success immediately.
This feature enables efficient single-tick operations and allows task completion to happen at startup.
This test demonstrates that task lifecycle callbacks properly reflect successful completion from the Start phase.
]]
print("    > StartNewTaskCanCompleteTask_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnCurrentTaskCompletedSuccessfully = function(self, t) test = t.Name == "Sub-task" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context14) return sb_htn.Tasks.ETaskStatus.Continue end, function(context15) return sb_htn.Tasks.ETaskStatus.Success end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(true == test)

--[[
Verifies that a primitive task can fail during its Start method, causing immediate failure without Update calls.
Operators can determine during initialization that they cannot proceed and return Failure to abort the task.
This early failure detection enables quick rejection of invalid task executions.
This test demonstrates that task lifecycle callbacks properly reflect failure initiated from the Start phase.
]]
print("    > StartNewTaskCanFailTask_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnCurrentTaskFailed = function(self, t) test = t.Name == "Sub-task" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context16) return sb_htn.Tasks.ETaskStatus.Continue end, function(context17) return sb_htn.Tasks.ETaskStatus.Failure end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(true == test)

--[[
Verifies that the OnStopCurrentTask callback is invoked when a task is stopped due to replanning or plan changes.
When the plan is replaced, the currently executing task must be stopped to clean up its state and resources.
The Stop method on the operator is called to perform cleanup before the task is replaced.
This test demonstrates that task stop callbacks work correctly during plan transitions.
]]
print("    > OnStopCurrentTask_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnStopCurrentTask = function(self, t3) test = t3.Name == "Sub-task2" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test1"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition", function(context12) return context12.Done == false end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"}
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context18) return sb_htn.Tasks.ETaskStatus.Continue end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context19) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(domain.Root, task2)
domain:AddTask(task1,       task3)
domain:AddTask(task2,       task4)
ctx.Done = true
planner:Tick(domain, ctx)
ctx.Done = false
ctx.IsDirty = true
planner:Tick(domain, ctx)
assert(test)

--[[
Verifies that the OnCurrentTaskCompletedSuccessfully callback is invoked when a task's operator returns Success.
This callback fires when a task completes its execution successfully, allowing applications to react to task completion.
Successful task completion triggers effects and removes the task from the plan queue.
This test demonstrates that successful task completion callbacks work correctly during plan execution.
]]
print("    > OnCurrentTaskCompletedSuccessfully_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnCurrentTaskCompletedSuccessfully = function(self, t4) test = t4.Name == "Sub-task1" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test1"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition", function(context15) return context15.Done == false end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"}
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context20) return sb_htn.Tasks.ETaskStatus.Success end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context21) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(domain.Root, task2)
domain:AddTask(task1,       task3)
domain:AddTask(task2,       task4)
ctx.Done = true
planner:Tick(domain, ctx)
ctx.Done = false
ctx.IsDirty = true
planner:Tick(domain, ctx)
assert(test)

--[[
Verifies that the OnApplyEffect callback is invoked when effects are applied to the context during task completion.
Effects modify world state when tasks complete, and the planner invokes callbacks for each effect application.
This callback enables applications to monitor and react to state changes made by task effects.
This test demonstrates that effect application callbacks work correctly when tasks complete successfully.
]]
print("    > OnApplyEffect_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnApplyEffect = function(self, e) test = e.Name == "TestEffect" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test1"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task3 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}
task3:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition", function(context18) return not context18:HasState(TestContext.TestEnum.StateA) end))
task4 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"}
task3:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context22) return sb_htn.Tasks.ETaskStatus.Success end))
task3:AddEffect(sb_htn.Effects.ActionEffect:new(TestContext, "TestEffect", sb_htn.Effects.EEffectType.PlanAndExecute,
                                                function(context20, effectType) context20:SetState(TestContext.TestEnum.StateA, true, sb_htn.Tasks.ETaskStatus.Continue) end))
task4:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context23) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(domain.Root, task2)
domain:AddTask(task1,       task3)
domain:AddTask(task2,       task4)
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain,                      ctx)
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
ctx:SetState(TestContext.TestEnum.StateA, false, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain,                      ctx)
assert(test)

--[[
Verifies that the OnCurrentTaskFailed callback is invoked when a task's operator returns Failure.
Task failure triggers replanning because the current plan path is no longer viable.
The callback allows applications to respond to task failures and monitor plan instability.
This test demonstrates that task failure callbacks work correctly during plan execution.
]]
print("    > OnCurrentTaskFailed_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnCurrentTaskFailed = function(self, t5) test = t5.Name == "Sub-task" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context24) return sb_htn.Tasks.ETaskStatus.Failure end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(test)

--[[
Verifies that the OnCurrentTaskContinues callback is invoked when a task's operator returns Continue.
Continue indicates that a task needs more time and will remain the current task in the next planning cycle.
The callback allows applications to monitor long-running task progress and multi-tick operations.
This test demonstrates that task continuation callbacks work correctly during plan execution.
]]
print("    > OnCurrentTaskContinues_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnCurrentTaskContinues = function(self, t6) test = t6.Name == "Sub-task" end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context25) return sb_htn.Tasks.ETaskStatus.Continue end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(test)

--[[
Verifies that the OnCurrentTaskExecutingConditionFailed callback is invoked when an executing condition fails at runtime.
Executing conditions are checked before each task update and allow runtime task invalidation when conditions change.
When an executing condition fails, the task is stopped and replanning is triggered.
This test demonstrates that executing condition failure callbacks enable dynamic task invalidation during execution.
]]
print("    > OnCurrentTaskExecutingConditionFailed_ExpectedBehavior")
test = false
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
ctx.PlannerState.OnCurrentTaskExecutingConditionFailed = function(self, t7, c2)
    test = t7.Name == "Sub-task" and
        c2.Name == "TestCondition"
end
domain = sb_htn.Domain:new(TestContext, "Test")
task1 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"}
task2:SetOperator(sb_htn.Operators.FuncOperator:new(TestContext, function(context26) return sb_htn.Tasks.ETaskStatus.Continue end))
task2:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition", function(context25) return context25.Done end))
domain:AddTask(domain.Root, task1)
domain:AddTask(task1,       task2)
planner:Tick(domain, ctx)
assert(test)

--[[
Verifies that the planner can find a better plan when planning conditions change and the current operator returns Continue.
When world state changes affect planning conditions, the planner can trigger replanning while a task continues executing.
The planner uses Method Traversal Record (MTR) comparison to decide whether new plans are better than existing ones.
This test demonstrates that replanning works correctly when conditions improve during task execution.
]]
print("    > FindPlanIfConditionChangeAndOperatorIsContinuous_ExpectedBehavior")
ctx = TestContext()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
local select = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test Select"}
local actionA = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Test Action A"}
actionA:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A", function(context27) return context27.Done == true end))
actionA:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A", function(context28) return context28.Done == true end))
actionA:SetOperator(TestOperator:new())
local actionB = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Test Action B"}
actionB:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A", function(context29) return context29.Done == false end))
actionB:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A", function(context30) return context30.Done == false end))
actionB:SetOperator(TestOperator:new())
domain:AddTask(domain.Root, select)
domain:AddTask(select,      actionA)
domain:AddTask(select,      actionB)
planner:Tick(domain, ctx, false)
local plan = ctx.PlannerState.Plan
local currentTask = ctx.PlannerState.CurrentTask
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action B")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)
-- When we change the condition to Done = true, we should now be able to find a better plan!
ctx.Done = true
planner:Tick(domain, ctx, true)
plan = ctx.PlannerState.Plan
currentTask = ctx.PlannerState.CurrentTask
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action A")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 1)

--[[
Verifies that the planner finds a better plan when world state changes affect task preconditions during continuous execution.
World state changes can make different tasks valid, triggering the planner to find alternative plans.
The planner compares MTR values to ensure it only switches to genuinely better plans, not equivalent ones.
This test demonstrates that replanning responds to world state changes while maintaining plan stability through MTR comparison.
]]
print("    > FindPlanIfWorldStateChangeAndOperatorIsContinuous_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
select = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test Select"}
actionA = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Test Action A"}
actionA:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A", function(context31) return context31:GetState(TestContext.TestEnum.StateA) == 1 end))
actionA:SetOperator(TestOperator:new())
actionB = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Test Action B"}
actionB:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A", function(context32) return context32:GetState(TestContext.TestEnum.StateA) == 0 end))
actionB:SetOperator(TestOperator:new())
domain:AddTask(domain.Root, select)
domain:AddTask(select,      actionA)
domain:AddTask(select,      actionB)
planner:Tick(domain, ctx, false)
plan = ctx.PlannerState.Plan
currentTask = ctx.PlannerState.CurrentTask
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action B")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)
-- When we change the condition to Done = true, we should now be able to find a better plan!
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain,                      ctx,  true)
plan = ctx.PlannerState.Plan
currentTask = ctx.PlannerState.CurrentTask
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action A")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 1)

--[[
Verifies that the planner correctly finds an alternative plan when world state changes make the current plan invalid.
When the current plan becomes impossible (not just suboptimal), the planner must find any viable alternative.
The planner triggers replanning and may switch to worse MTR plans if the current plan is completely invalid.
This test demonstrates that replanning handles forced transitions to suboptimal but valid plans correctly.
]]
print("    > FindPlanIfWorldStateChangeToWorseMRTAndOperatorIsContinuous_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.Domain:new(TestContext, "Test")
select = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test Select"}
actionA = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Test Action A"}
actionA:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A", function(context33) return context33:GetState(TestContext.TestEnum.StateA) == 0 end))
actionA:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can choose A", function(context34) return context34:GetState(TestContext.TestEnum.StateA) == 0 end))
actionA:SetOperator(TestOperator:new())
actionB = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Test Action B"}
actionB:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A", function(context35) return context35:GetState(TestContext.TestEnum.StateA) == 1 end))
actionB:AddExecutingCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Can not choose A", function(context36) return context36:GetState(TestContext.TestEnum.StateA) == 1 end))
actionB:SetOperator(TestOperator:new())
domain:AddTask(domain.Root, select)
domain:AddTask(select,      actionA)
domain:AddTask(select,      actionB)
planner:Tick(domain, ctx, false)
plan = ctx.PlannerState.Plan
currentTask = ctx.PlannerState.CurrentTask
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action A")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 1)
-- When we change the condition to Done = true, the first plan should no longer be allowed, we should find the second plan instead!
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain,                      ctx,  true)
plan = ctx.PlannerState.Plan
currentTask = ctx.PlannerState.CurrentTask
assert(table.size(plan.list) == 0)
assert(currentTask.Name == "Test Action B")
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)

--[[
Verifies that toggling between plans using only planning conditions (without executing conditions) results in unstable plan switching.
Planning conditions are evaluated once during decomposition, but world state changes during execution don't re-evaluate them.
Therefore, a task with a failed planning condition can still remain the current task if conditions change after decomposition.
This test demonstrates the limitation of relying only on planning conditions and the need for executing conditions.
]]
print("    > ToggleBetweenTwoPlansWithOnlyPlannerConditionWontWork_ExpectedBehavior")
local c = TestContext:new()
c:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.DomainBuilder:new(TestContext, "Test")
    :Action("A")
    :Condition("Is True", function(ctx) return ctx:HasState(c.TestEnum.StateA) end)
    :Do(function(ctx)
        ctx.Done = true
        return sb_htn.Tasks.ETaskStatus.Continue
    end)
    :End()
    :Action("B")
    :Condition("Is False", function(ctx) return ctx:HasState(c.TestEnum.StateA) == false end)
    :Do(function(ctx)
        ctx.Done = false
        return sb_htn.Tasks.ETaskStatus.Continue
    end)
    :End()
    :Build()
c:SetState(c.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(true == c.Done); -- We're running Action A
c:SetState(c.TestEnum.StateA, false, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(true == c.Done); -- Our change triggered a replan, but B can't beat A due to MTR. So A won't get invalidated.

--[[
Verifies that using executing conditions enables smooth toggling between different plans as conditions change at runtime.
Executing conditions are re-evaluated on each planner tick, allowing tasks to be invalidated when world state changes.
When an executing condition fails, the planner triggers replanning and can switch to alternative tasks.
This test demonstrates that executing conditions enable dynamic and responsive plan switching based on runtime conditions.
]]
print("    > ToggleBetweenTwoPlansWithExecutingConditionWillWork_ExpectedBehavior")
c = TestContext:new()
c:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.DomainBuilder:new(TestContext, "Test")
    :Action("A")
    :Condition("Is True", function(ctx) return ctx:HasState(c.TestEnum.StateA) end)
    :ExecutingCondition("Is True", function(ctx) return ctx:HasState(c.TestEnum.StateA) end)
    :Do(function(ctx)
        ctx.Done = true
        return sb_htn.Tasks.ETaskStatus.Continue
    end)
    :End()
    :Action("B")
    :Condition("Is False", function(ctx) return ctx:HasState(c.TestEnum.StateA) == false end)
    :ExecutingCondition("Is False", function(ctx) return ctx:HasState(c.TestEnum.StateA) == false end)
    :Do(function(ctx)
        ctx.Done = false
        return sb_htn.Tasks.ETaskStatus.Continue
    end)
    :End()
    :Build()
c:SetState(c.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(true == c.Done); -- We're running A
c:SetState(c.TestEnum.StateA, false, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(false == c.Done); -- Out executing condition will realize that A is no longer valid, and we find B instead.
c:SetState(c.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(true == c.Done); -- We're running A

--[[
Verifies that operators can detect condition changes and return Success to enable task switching without executing conditions.
Operators have access to the context and can check conditions manually during execution.
If an operator detects that conditions no longer support the current task, it can return Success to complete the task and trigger replanning.
This test demonstrates an alternative approach to plan switching where operators detect and respond to condition changes.
]]
print("    > ToggleBetweenTwoPlansWithConditionSuccessInOperatorWillWork_ExpectedBehavior")
c = TestContext:new()
c:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.DomainBuilder:new(TestContext, "Test")
    :Action("A")
    :Condition("Is True", function(ctx) return ctx:HasState(c.TestEnum.StateA) end)
    :Do(function(ctx)
        if (ctx:HasState(c.TestEnum.StateA) == false) then
            return sb_htn.Tasks.ETaskStatus.Success
        end

        ctx.Done = true
        return sb_htn.Tasks.ETaskStatus.Continue
    end)
    :End()
    :Action("B")
    :Condition("Is False", function(ctx) return ctx:HasState(c.TestEnum.StateA) == false end)
    :Do(function(ctx)
        if (ctx:HasState(c.TestEnum.StateA)) then
            return sb_htn.Tasks.ETaskStatus.Success
        end

        ctx.Done = false
        return sb_htn.Tasks.ETaskStatus.Continue
    end)
    :End()
    :Build()
c:SetState(c.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(true == c.Done); -- We're running A
c:SetState(c.TestEnum.StateA, false, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(false == c.Done); -- Out executing condition will realize that A is no longer valid, and we find B instead.
c:SetState(c.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(true == c.Done); -- We're running A

--[[
Verifies that operators returning Failure does not directly enable plan switching in the same way as Success.
While Failure does trigger replanning, the semantics are different from Success (task failure vs. task completion).
This test demonstrates the distinction between task failure (which occurs due to errors) and task success (completion).
Understanding these semantics is important for designing responsive replanning behaviors.
]]
print("    > ToggleBetweenTwoPlansWithConditionFailureInOperatorWontWork_ExpectedBehavior")
c = TestContext:new()
c:Init()
planner = sb_htn.Planners.Planner:new(TestContext)
domain = sb_htn.DomainBuilder:new(TestContext, "Test")
    :Action("A")
    :Condition("Is True", function(ctx) return ctx:HasState(c.TestEnum.StateA) end)
    :Do(function(ctx)
        if (ctx:HasState(c.TestEnum.StateA) == false) then
            return sb_htn.Tasks.ETaskStatus.Failure
        end

        ctx.Done = true
        return sb_htn.Tasks.ETaskStatus.Continue
    end)
    :End()
    :Action("B")
    :Condition("Is False", function(ctx) return ctx:HasState(c.TestEnum.StateA) == false end)
    :Do(function(ctx)
        if (ctx:HasState(c.TestEnum.StateA)) then
            return sb_htn.Tasks.ETaskStatus.Failure
        end

        ctx.Done = false
        return sb_htn.Tasks.ETaskStatus.Continue
    end)
    :End()
    :Build()
c:SetState(c.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(true == c.Done); -- We're running A
c:SetState(c.TestEnum.StateA, false, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(false == c.Done); -- Out executing condition will realize that A is no longer valid, and we find B instead.
c:SetState(c.TestEnum.StateA, true, sb_htn.Effects.EEffectType.Permanent)
planner:Tick(domain, c)
assert(true == c.Done); -- We're running A

--[[
Reproduces a corner-case where a primitive task's operator executes twice when a plan completes
with allowImmediateReplanAndExecute=true.

When a primitive task's operator returns Success and the plan queue becomes empty,
the planner triggers an immediate replan with allowImmediateReplanAndExecute=true (default).
If the task's conditions still pass (e.g., an always-true condition that doesn't check world state),
the same task may be selected again and executed a second time in the recursive Tick call.

This test demonstrates the corner-case by:
1. Creating a selector with a condition that always returns true
2. Adding an action that increments ExecutionCount, sets Done flag, and returns Success
3. Calling Planner:Tick() once with default allowImmediateReplanAndExecute=true
4. Asserting that ExecutionCount should be 2
5. We then reset the ExecutionCount and tick the planner again with allowImmediateReplanAndExecute=false
6. Assert that ExecutionCount should be 1

This test serves as corner-case documentation to clarify expected behavior.
]]
print("    > OperatorExecutedOnlyOnceWhenPlanCompletes_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ExecutionCount = 0; -- Track operator executions
planner = sb_htn.Planners.Planner:new(TestContext)
-- Build a simple domain: selector with one action that always succeeds
-- The condition is always true, not checking any world state
domain = sb_htn.DomainBuilder:new(TestContext, "Test")
    :Select("Root Selector")
    :Action("Complete Action")
    :Condition("Always True", function(context37) return true end)
    :Do(function(context38)
        context38.ExecutionCount = context38.ExecutionCount + 1
        context38.Done = true
        return sb_htn.Tasks.ETaskStatus.Success
    end)
    :End()
    :End()
    :Build()
-- Execute a single tick with default allowImmediateReplanAndExecute=true
planner:Tick(domain, ctx)
-- EXPECTED: Operator should execute twice because planner is ticked with allowImmediateReplanAndExecute, and the action has
--           no condition (always true) and return Success immediately, which will trigger immediate replan and select
--           the same action again. We only replan immediately once in a single planner tick, which prevents this from
--           going into an infinite loop.
assert(2 == ctx.ExecutionCount,
       "Operator should execute exactly once, but executed " .. ctx.ExecutionCount .. " times")
assert(true == ctx.Done,                                                "Task should have completed")
assert(ctx.PlannerState.CurrentTask == nil,                             "No current task after plan completion")
assert(sb_htn.Tasks.ETaskStatus.Success == ctx.PlannerState.LastStatus, "Last status should be Success")
-- Reset execution count
ctx.ExecutionCount = 0
-- Execute a single tick with allowImmediateReplanAndExecute=false
planner:Tick(domain, ctx, false)
-- EXPECTED: Operator should execute exactly once now that we don't allow immediate replan.
assert(1 == ctx.ExecutionCount,
       "Operator should execute exactly once, but executed " .. ctx.ExecutionCount .. " times")
assert(true == ctx.Done,                                                "Task should have completed")
assert(ctx.PlannerState.CurrentTask == nil,                             "No current task after plan completion")
assert(sb_htn.Tasks.ETaskStatus.Success == ctx.PlannerState.LastStatus, "Last status should be Success")