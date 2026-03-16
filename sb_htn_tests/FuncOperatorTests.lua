local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")

print("  > FuncOperatorTests")

--[[
Verifies that a FuncOperator gracefully handles Update being called with a null function pointer by treating it as a no-op.
Operators in HTN planning are execution mechanisms for primitive tasks that manage the task lifecycle (Start, Update, Stop, Abort).
Update is called repeatedly during execution to progress the task toward completion, returning a TaskStatus (Continue, Success, or Failure).
This test ensures that Update without a function pointer is valid behavior rather than throwing an exception, allowing for optional implementations.
]]
print("    > UpdateDoesNothingWithoutFunctionPtr_ExpectedBehavior")
local ctx = TestContext:new()
local e = sb_htn.Operators.FuncOperator:new(TestContext)
e:Update(ctx)

--[[
Verifies that a FuncOperator gracefully handles Start being called with a null function pointer by treating it as a no-op.
Start is the initialization phase of the operator lifecycle, called once when a primitive task begins execution.
Start allows operators to initialize state, allocate resources, or perform one-time setup before the task begins its execution loop.
This test ensures that Start with a null function is valid, supporting partial operator implementations where only certain lifecycle methods are needed.
]]
print("    > StartDoesNothingWithoutFunctionPtr_ExpectedBehavior")
ctx = TestContext:new();
e = sb_htn.Operators.FuncOperator:new(TestContext);
e:Start(ctx);

--[[
Verifies that a FuncOperator gracefully handles Stop being called with a null function pointer by treating it as a no-op.
Stop is the cleanup and finalization phase of the operator lifecycle, called when a task completes or is interrupted.
Stop allows operators to clean up resources, save final state, or perform teardown before the task ends.
This test ensures that Stop with a null function is valid, allowing operators to implement only the phases needed for their specific use case.
]]
print("    > StopDoesNothingWithoutFunctionPtr_ExpectedBehavior")
ctx = TestContext:new()
e = sb_htn.Operators.FuncOperator:new(TestContext)
e:Stop(ctx)

--[[
Verifies that a FuncOperator throws an exception when Update is called with a null context parameter.
The context object is essential for operators to access and modify the world state during task execution.
Update uses the context to check state conditions and apply state changes based on execution progress.
This test ensures operators validate their input and fail fast with clear exceptions when given invalid parameters rather than allowing silent failures.
]]
print("    > UpdateThrowsIfBadContext_ExpectedBehavior")
e = sb_htn.Operators.FuncOperator:new(TestContext)
if (pcall(function() e:Update(nil) end)) then
    print("Exception not caught.")
end

--[[
Verifies that a FuncOperator throws an exception when Start is called with a null context parameter.
Start is the initialization phase where operators set up the task execution environment using the context.
The context is critical for Start to initialize operator state and validate initial world state conditions.
This test ensures the operator validates input at the start of the lifecycle, catching invalid parameters before execution progresses.
]]
print("    > StartThrowsIfBadContext_ExpectedBehavior")
e = sb_htn.Operators.FuncOperator:new(TestContext);
if (pcall(function() e:Start(nil) end)) then
    print("Exception not caught.")
end

--[[
Verifies that a FuncOperator throws an exception when Stop is called with a null context parameter.
Stop is the cleanup phase where operators need the context to finalize state, save results, or perform final state modifications.
The context is essential for Stop to ensure all world state changes are properly recorded before the task completes.
This test ensures that context validation is consistent across all operator lifecycle phases, guaranteeing safe cleanup operations.
]]
print("    > StopThrowsIfBadContext_ExpectedBehavior")
e = sb_htn.Operators.FuncOperator:new(TestContext)
if (pcall(function() e:Stop(nil) end)) then
    print("Exception not caught.")
end

--[[
Verifies that a FuncOperator correctly invokes the lambda function provided for Update and returns its TaskStatus result.
The Update function is the core execution loop, called repeatedly by the planner until the operator signals completion or failure.
Update must return TaskStatus.Continue to signal the task is still executing, TaskStatus.Success to signal completion, or TaskStatus.Failure to signal an error.
This test confirms the lambda wrapping mechanism properly executes the Update function and correctly propagates the TaskStatus result to the planner.
]]
print("    > UpdateReturnsStatusInternalFunctionPtr_ExpectedBehavior")
ctx = TestContext:new()
e = sb_htn.Operators.FuncOperator:new(TestContext,
    function(context1) return sb_htn.Tasks.ETaskStatus.Success end)
local status = e:Update(ctx)
assert(sb_htn.Tasks.ETaskStatus.Success == status)

--[[
Verifies that a FuncOperator correctly invokes the lambda function provided for Start and returns its TaskStatus result.
The Start function is called once at the beginning of task execution to initialize the operator and optionally signal immediate success or failure.
Start can return TaskStatus.Success to skip Update and complete immediately, TaskStatus.Failure for immediate failure, or implicitly continue to Update.
This test confirms that Start functions can signal completion during the initialization phase and that the TaskStatus is properly returned to the planner.
]]
print("    > StartReturnsStatusInternalFunctionPtr_ExpectedBehavior")
ctx = TestContext:new();
e = sb_htn.Operators.FuncOperator:new(TestContext, nil,
    function(context2) return sb_htn.Tasks.ETaskStatus.Success end);
status = e:Start(ctx);
assert(sb_htn.Tasks.ETaskStatus.Success == status)

--[[
Verifies that a FuncOperator correctly invokes the lambda function provided for Stop and that world state changes made in the Stop function are reflected in the context.
The Stop function is called when a task completes or is interrupted, providing an opportunity to finalize state and perform cleanup.
Stop functions typically set final state flags, record completion status, or trigger side effects that should persist after the task ends.
This test confirms that Stop functions execute properly and that any world state modifications they make to the context are preserved for subsequent planning.
]]
print("    > StopCallsInternalFunctionPtr_ExpectedBehavior")
ctx = TestContext:new()
e = sb_htn.Operators.FuncOperator:new(TestContext, nil, nil,
    function(context3) context3.Done = true end)
e:Stop(ctx)
assert(true == ctx.Done)
