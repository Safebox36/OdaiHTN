local sb_htn = require("sb_htn.interop")
local Queue = require("sb_htn.Utils.Queue")
local TestContext = require("sb_htn_tests.TestContext")
local TestDebugContext = require("sb_htn_tests.TestDebugContext")

print(">>> SelectorTests")

print("> AddCondition_ExpectedBehavior")
local task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
local t = task:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition",
    function(context1) return context1.Done == false end))
assert(t == task)
assert(table.size(task.Conditions) == 1)

print("> AddSubtask_ExpectedBehavior")
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
t = task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task"
    return p
end)())
assert(t == task)
assert(table.size(task.Subtasks) == 1)

print("> IsValidFailsWithoutSubtasks_ExpectedBehavior")
local ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
assert(task:IsValid(ctx) == false)

print("> IsValid_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task"
    return p
end)())
assert(task:IsValid(ctx))

print("> DecomposeWithNoSubtasks_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
local plan = Queue:new()
local status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)

print("> DecomposeWithSubtasks_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
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
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:peek().Name)

print("> DecomposeWithSubtasks2_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task:AddSubtask((function() local s = sb_htn.Tasks.CompoundTasks.Selector:new()
    s.Name = "Sub-task1"
end)())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)

print("> DecomposeWithSubtasks3_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context2) return context2.Done == true end)))
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)

print("> DecomposeMTRFails_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context3) return context3.Done == true end)))
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(0 == ctx.MethodTraversalRecord[1])

print("> DecomposeDebugMTRFails_ExpectedBehavior")
ctx = TestDebugContext:new()
ctx:init()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context4) return context4.Done == true end
    , TestDebugContext)))
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MTRDebug) == 1)
assert(ctx.MTRDebug[1]:find("REPLAN FAIL", 1, true))
assert(ctx.MTRDebug[1]:find("Sub-task2", 1, true))

print("> DecomposeMTRSucceedsWhenEqual_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context5) return context5.Done == true end)))
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
table.insert(ctx.LastMTR, 2)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(table.size(plan.list) == 1)
assert(ctx.MethodTraversalRecord[1] == ctx.LastMTR[1])

print("> DecomposeCompoundSubtaskSucceeds_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
local task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test2"
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context6) return context6.Done == true end)))
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)

print("> DecomposeCompoundSubtaskFails_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test2"
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context7) return context7.Done == true end)))
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context8) return context8.Done == true end)))
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task3" == plan:peek().Name)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(ctx.MethodTraversalRecord[1] == 2)

print("> DecomposeNestedCompoundSubtaskFails_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test2"
local task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test3"
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context9) return context9.Done == true end)))
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context10) return context10.Done == true end)))
task2:AddSubtask(task3)
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context11) return context11.Done == true end)))
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task4"
    return p
end)())
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task4" == plan:peek().Name)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(ctx.MethodTraversalRecord[1] == 2)

print("> DecomposeCompoundSubtaskBeatsLastMTR_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test2"
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context12) return context12.Done == true end)))
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
table.insert(ctx.LastMTR, 2)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)

print("> DecomposeCompoundSubtaskEqualToLastMTR_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test2"
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context13) return context13.Done == true end)))
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3"
    return p
end)())
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)

print("> DecomposeCompoundSubtaskLoseToLastMTR_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test2"
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context14) return context14.Done == true end)))
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2"
    return p
end)())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context15) return context15.Done == true end)))
task:AddSubtask(task2)
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(ctx.MethodTraversalRecord[1] == 0)

print("> DecomposeCompoundSubtaskWinOverLastMTR_ExpectedBehavior")
ctx = TestContext:new()
local rootTask = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Root"
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test1"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test2"
task3 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test3"
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3-1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context16) return context16.Done == true end)))
task3:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task3-2"
    return p
end)())
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2-1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context17) return context17.Done == true end)))
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2-2"
    return p
end)())
task:AddSubtask(task2)
task:AddSubtask(task3)
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1-1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == false",
    function(context18) return context18.Done == false end)))
rootTask:AddSubtask(task)
table.insert(ctx.LastMTR, 1)
table.insert(ctx.LastMTR, 2)
table.insert(ctx.LastMTR, 1)
-- In this test, we prove that [0, 0, 1] beats [0, 1, 0]
plan = Queue:new()
status = rootTask:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)

print("> DecomposeCompoundSubtaskLoseToLastMTR2_ExpectedBehavior")
ctx = TestContext:new()
rootTask = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Root"
task = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test1"
task2 = sb_htn.Tasks.CompoundTasks.Selector:new()
task.Name = "Test2"
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2-1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context19) return context19.Done == true end)))
task2:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task2-1"
    return p
end)())
task:AddSubtask((function() local p = sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new()
    p.Name = "Sub-task1-1"
    return p
end)():AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true",
    function(context20) return context20.Done == true end)))
task:AddSubtask(task2)
rootTask:AddSubtask(task)
table.insert(ctx.LastMTR, 1)
table.insert(ctx.LastMTR, 2)
table.insert(ctx.LastMTR, 1)
-- We expect this test to be rejected, because [0,1,1] shouldn't beat [0,1,0]
plan = Queue:new()
status = rootTask:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 3)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)
assert(ctx.MethodTraversalRecord[3] == 0)
