local sb_htn = require("sb_htn.interop")
local Queue = require("sb_htn.Utils.Queue")
local TestContext = require("sb_htn_tests.TestContext")
local TestDebugContext = require("sb_htn_tests.TestDebugContext")

print("  > SelectorTests")

--[[
Verifies that a Selector correctly adds a condition to its conditions collection and returns itself for method chaining.
A Selector is a compound task that decomposes by attempting its subtasks in order until one succeeds, implementing a choice point in the task hierarchy.
Conditions are evaluated before decomposition to determine whether a selector is applicable in the current world state.
This test ensures the fluent builder pattern works correctly for selectors by confirming conditions are stored and the method returns the task instance for continued chaining.
]]
print("    > AddCondition_ExpectedBehavior")
local task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
local t = task:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "TestCondition", function(context1) return context1.Done == false end))
assert(t == task)
assert(table.size(task.Conditions) == 1)

--[[
Verifies that a Selector correctly adds a subtask to its subtasks collection and returns itself for method chaining.
Selectors maintain an ordered list of subtasks that represent alternative decomposition paths.
The selector tries each subtask in order during decomposition until one successfully decomposes, implementing first-match semantics.
This test confirms the fluent builder pattern allows chaining subtask additions and that each subtask is properly stored in the collection.
]]
print("    > AddSubtask_ExpectedBehavior")
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
t = task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"})
assert(t == task)
assert(table.size(task.Subtasks) == 1)

--[[
Verifies that a Selector with no subtasks is considered invalid and cannot be decomposed.
A selector requires at least one subtask option to be a valid decomposition point; an empty selector has nothing to choose from.
During decomposition validation, the planner checks if a selector is valid before attempting decomposition, rejecting invalid selectors early.
This test ensures selectors properly validate their structure and reject empty selectors that would cause decomposition failures.
]]
print("    > IsValidFailsWithoutSubtasks_ExpectedBehavior")
local ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
assert(task:IsValid(ctx) == false)

--[[
Verifies that a Selector with subtasks is considered valid and can proceed to decomposition.
A selector is valid when it has at least one subtask to attempt during decomposition.
The planner uses IsValid as a gating check before attempting decomposition, enabling early rejection of unsuitable tasks.
This test confirms that selectors with subtasks properly report validity, allowing decomposition to proceed.
]]
print("    > IsValid_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task"})
assert(task:IsValid(ctx))

--[[
Verifies that attempting to decompose a Selector with no subtasks returns Failed status and an empty plan.
Decomposition is the process of breaking down a compound task into executable primitive tasks based on the current world state.
When a selector has no subtasks, there are no alternatives to try, so decomposition fails with an empty plan queue.
This test confirms the selector properly handles the edge case of an empty subtask list by returning Failed without crashing.
]]
print("    > DecomposeWithNoSubtasks_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
local plan = Queue:new()
local status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Failed)
assert(table.size(plan.list) == 0)

--[[
Verifies that a Selector with valid subtasks successfully decomposes by selecting the first subtask.
Selectors implement first-match semantics, attempting subtasks in order until one succeeds and produces a non-empty plan.
Since primitive tasks always decompose successfully, the first subtask in the selector's list gets selected and added to the plan.
This test demonstrates the basic selector decomposition behavior and confirms the first valid subtask becomes the next task to execute.
]]
print("    > DecomposeWithSubtasks_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"})
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task1" == plan:peek().Name)

--[[
Verifies that a Selector skips invalid subtasks and uses the next valid one for decomposition.
When the first subtask (a selector with no children) is invalid, the selector tries the next alternative.
This demonstrates the selector's backtracking behavior: it iterates through subtasks until finding one that is both valid and decomposes successfully.
This test shows that selectors properly skip alternatives that cannot be decomposed, implementing robust fallback behavior.
]]
print("    > DecomposeWithSubtasks2_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task:AddSubtask((function()
    local s = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Sub-task1"}
end)())
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)

--[[
Verifies that a Selector properly evaluates conditions on subtasks and skips those that fail condition checks.
Conditions gate whether a task can be selected during decomposition based on the current world state.
The first subtask has a condition (Done == true) that fails since Done is false, so the selector moves to the next alternative.
This test demonstrates how conditions implement data-driven task selection, allowing the planner to choose task alternatives based on environmental state.
]]
print("    > DecomposeWithSubtasks3_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context2) return context2.Done == true end)))
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)

--[[
Verifies that a Selector rejects decomposition when the Method Traversal Record (MTR) indicates an alternative that fails.
The MTR is a sequence of indices tracking which subtask was selected at each selector in the previous plan, used to prevent infinite replanning loops.
When the LastMTR indicates the first subtask (index 1) should be chosen, but that subtask has a failing condition, the selector records -1 and rejects the entire decomposition.
This test demonstrates how the MTR mechanism prevents the planner from repeatedly trying the same failing task alternatives, enforcing progress toward different solutions.
]]
print("    > DecomposeMTRFails_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context3) return context3.Done == true end)))
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(0 == ctx.MethodTraversalRecord[1])

--[[
Verifies that MTR failure rejection is properly logged in debug contexts for troubleshooting.
Debug contexts record detailed decomposition traces in MTRDebug logs, providing visibility into planner decision-making for analysis and debugging.
When MTR-based rejection occurs, the debug log captures "REPLAN FAIL" messages that identify which alternative was attempted and why the plan was rejected.
This test demonstrates how debug logging helps developers understand replanning behavior and diagnose issues where the planner cannot find valid task decompositions.
]]
print("    > DecomposeDebugMTRFails_ExpectedBehavior")
ctx = TestDebugContext:new()
ctx:Init()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context4) return context4.Done == true end, TestDebugContext)))
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MTRDebug) == 1)
assert(ctx.MTRDebug[1]:find("REPLAN FAIL", 1, true))
assert(ctx.MTRDebug[1]:find("Sub-task2", 1, true))

--[[
Verifies that a Selector succeeds when the MTR-indicated subtask successfully decomposes.
The MTR provides hints about which subtask was previously chosen; when that subtask still decomposes successfully, the selector can continue with the same decomposition.
If the MTR indicates subtask index 2 (Sub-task2), and that task is valid and decomposes successfully, the decomposition proceeds without rejection.
This test demonstrates how the MTR mechanism enables the planner to reuse previous decomposition decisions when they remain valid, improving efficiency by avoiding redundant searches.
]]
print("    > DecomposeMTRSucceedsWhenEqual_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context5) return context5.Done == true end)))
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
table.insert(ctx.LastMTR, 2)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(table.size(plan.list) == 1)
assert(ctx.MethodTraversalRecord[1] == ctx.LastMTR[1])

--[[
Verifies that a Selector can decompose nested compound tasks (selectors within selectors) and correctly records MTR choices at each level.
Compound tasks can contain other compound tasks, creating hierarchical decomposition: the outer selector tries its first subtask (an inner selector), which then decomposes.
The MTR records the decomposition path: [1, 2] means the outer selector tried option 1 (inner selector), which tried option 2 (Sub-task2).
This test demonstrates multi-level decomposition and MTR tracking, showing how the planner navigates complex task hierarchies and records the complete choice path.
]]
print("    > DecomposeCompoundSubtaskSucceeds_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
local task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context6) return context6.Done == true end)))
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
task:AddSubtask(task2)
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task3"})
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task2" == plan:peek().Name)
assert(table.size(ctx.MethodTraversalRecord) == 2)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)

--[[
Verifies that when a nested selector fails to decompose, the outer selector backtracks and tries its next subtask.
The nested selector task2 has all its subtasks failing conditions, so it cannot provide a valid decomposition.
When nested decomposition fails, the outer selector moves to its next alternative (Sub-task3), which succeeds.
This test demonstrates backtracking behavior across nesting levels: the planner explores the first alternative fully, and when it fails entirely, moves to the next option.
]]
print("    > DecomposeCompoundSubtaskFails_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context7) return context7.Done == true end)))
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context8) return context8.Done == true end)))
task:AddSubtask(task2)
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task3"})
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task3" == plan:peek().Name)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(ctx.MethodTraversalRecord[1] == 2)

--[[
Verifies that backtracking works correctly through multiple nesting levels when deeply nested selectors fail.
The hierarchy has task (selector) -> task2 (selector) -> task3 (selector) -> all failing conditions.
When the entire nested chain task2/task3 fails to produce a valid decomposition, the outer selector abandons the entire branch and tries its next alternative.
This test demonstrates deep backtracking: failures at any nesting level trigger complete backtracking to the outer selector, which then tries its next option.
]]
print("    > DecomposeNestedCompoundSubtaskFails_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
local task3 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test3"}
task3:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context9) return context9.Done == true end)))
task3:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context10) return context10.Done == true end)))
task2:AddSubtask(task3)
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task3"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context11) return context11.Done == true end)))
task:AddSubtask(task2)
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task4"})
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)
assert(table.size(plan.list) > 0)
assert(table.size(plan.list) == 1)
assert("Sub-task4" == plan:peek().Name)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(ctx.MethodTraversalRecord[1] == 2)

--[[
Verifies that a better (earlier) decomposition path can override the last MTR hint, allowing the planner to find improvements.
The LastMTR indicates [1] (outer selector's second option), but the planner discovers [1, 2] (outer option 1 -> inner option 2) as a valid decomposition.
MTR comparison uses lexicographic ordering: [1, 2] is considered "better" (more preferred) than [1] because index 1 comes before index 2.
This test demonstrates MTR-based replanning: the planner can find superior alternatives by exploring earlier decomposition indices, enabling progressive improvement.
]]
print("    > DecomposeCompoundSubtaskBeatsLastMTR_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context12) return context12.Done == true end)))
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
task:AddSubtask(task2)
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task3"})
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

--[[
Verifies that when the new decomposition path equals the LastMTR, the planner accepts the identical solution.
The LastMTR is [1] (try outer option 1), and the planner generates [1, 2] (outer option 1 -> inner option 2).
Since the new path is not identical but shares the same first index, it's considered acceptable and not rejected.
This test demonstrates MTR equality handling when decomposition paths extend or match the previous solution, ensuring consistent planning behavior.
]]
print("    > DecomposeCompoundSubtaskEqualToLastMTR_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context13) return context13.Done == true end)))
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
task:AddSubtask(task2)
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task3"})
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

--[[
Verifies that the planner rejects decomposition when the new path is lexicographically worse (larger indices) than the LastMTR.
The LastMTR indicates [1] (first option), but the planner would need to use [2] (second option, nested selector).
Since [1] is lexicographically greater than [1], this represents a degradation in choice quality, and the decomposition is rejected to prevent backtracking to worse solutions.
This test demonstrates the MTR mechanism's role in enforcing progress: the planner rejects decompositions that would constitute a backwards step compared to previous attempts.
]]
print("    > DecomposeCompoundSubtaskLoseToLastMTR_ExpectedBehavior")
ctx = TestContext:new()
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context14) return context14.Done == true end)))
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2"})
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context15) return context15.Done == true end)))
task:AddSubtask(task2)
table.insert(ctx.LastMTR, 1)
plan = Queue:new()
status = task:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 1)
assert(ctx.MethodTraversalRecord[1] == 0)

--[[
Verifies that the planner accepts a superior (lexicographically earlier) decomposition path even when longer and more complex.
The LastMTR is [1, 2, 1] from a previous plan, but the planner discovers [1, 1, 2] as the new decomposition.
Although [1, 1, 2] is one element longer, it beats [1, 2, 1] at the second level: 1 is lexicographically smaller than 2.
This test demonstrates sophisticated MTR comparison logic: the planner compares paths element by element and accepts longer paths if they achieve earlier choices at any position.
]]
print("    > DecomposeCompoundSubtaskWinOverLastMTR_ExpectedBehavior")
ctx = TestContext:new()
local rootTask = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Root"}
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test1"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task3 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test3"}
task3:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task3-1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context16) return context16.Done == true end)))
task3:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task3-2"})
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2-1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context17) return context17.Done == true end)))
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2-2"})
task:AddSubtask(task2)
task:AddSubtask(task3)
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1-1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == false", function(context18) return context18.Done == false end)))
rootTask:AddSubtask(task)
table.insert(ctx.LastMTR, 1)
table.insert(ctx.LastMTR, 2)
table.insert(ctx.LastMTR, 1)
-- In this test, we prove that [1, 1, 2] beats [1, 2, 1]
plan = Queue:new()
status = rootTask:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Succeeded)

--[[
Verifies that the planner rejects a decomposition path that is lexicographically worse at any comparison point.
The LastMTR is [1, 2, 1], and the planner would generate [1, 2, 2] by choosing option 2 at the last level instead of 1.
Since at the third position, 2 > 1, the new path [1, 2, 2] is lexicographically worse and is rejected.
This test demonstrates the strictness of MTR ordering: even partial agreement with the first elements doesn't help if a later element is worse.
]]
print("    > DecomposeCompoundSubtaskLoseToLastMTR2_ExpectedBehavior")
ctx = TestContext:new()
rootTask = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Root"}
task = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test1"}
task2 = sb_htn.Tasks.CompoundTasks.Selector:new{Name = "Test2"}
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2-1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context19) return context19.Done == true end)))
task2:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task2-1"})
task:AddSubtask(sb_htn.Tasks.PrimitiveTasks.PrimitiveTask:new{Name = "Sub-task1-1"}:AddCondition(sb_htn.Conditions.FuncCondition:new(TestContext, "Done == true", function(context20) return context20.Done == true end)))
task:AddSubtask(task2)
rootTask:AddSubtask(task)
table.insert(ctx.LastMTR, 1)
table.insert(ctx.LastMTR, 2)
table.insert(ctx.LastMTR, 1)
-- We expect this test to be rejected, because [1, 2, 2] shouldn't beat [1, 2, 1]
plan = Queue:new()
status = rootTask:Decompose(ctx, 1, plan)
assert(status == sb_htn.Tasks.CompoundTasks.EDecompositionStatus.Rejected)
assert(table.size(plan.list) == 0)
assert(table.size(ctx.MethodTraversalRecord) == 3)
assert(ctx.MethodTraversalRecord[1] == 1)
assert(ctx.MethodTraversalRecord[2] == 2)
assert(ctx.MethodTraversalRecord[3] == 0)