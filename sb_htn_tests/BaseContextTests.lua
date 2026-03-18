local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")
local TestDebugContext = require("sb_htn_tests.TestDebugContext")

print("  > BaseContextTests")

--[[
Verifies that a newly created context initializes with a ContextState of Executing by default.
The context state tracks whether the planner is in Planning mode (building a new plan) or Executing mode (running the current plan).
Executing is the default state because the planner typically starts in execution mode before transitioning to planning when needed.
This test ensures the context begins in the correct state without requiring explicit initialization for typical use cases.
]]
print("    > DefaultContextStateIsExecuting_ExpectedBehavior")
local ctx = TestContext:new()
assert(ctx.ContextState == sb_htn.Contexts.IContext.EContextState.Executing)

--[[
Verifies that Init properly initializes the context's world state tracking structures without enabling debug facilities.
Init must be called before planning/execution to set up the WorldStateChangeStack, a collection that tracks all state modifications made during planning.
The stack array has one entry per world state enum value, allowing the planner to rewind state changes when backtracking during decomposition.
This test confirms Init creates the necessary collections while leaving debug logging disabled (debugging must be explicitly enabled in derived contexts).
]]
print("    > InitInitializeCollections_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
assert(table.size(ctx.WorldStateChangeStack) > 0)
assert(table.size(TestContext.TestEnum) == table.size(ctx.WorldStateChangeStack))
assert(false == ctx.DebugMTR)
assert(false == ctx.LogDecomposition)
assert(ctx.MTRDebug == nil)
assert(ctx.LastMTRDebug == nil)

--[[
Verifies that Init initializes debug logging collections when the context has debug flags enabled.
Derived contexts can override DebugMTR and LogDecomposition flags to enable detailed decomposition tracing.
When debug is enabled, Init allocates MTRDebug (Method Traversal Record for selector choices), LastMTRDebug (previous MTR for comparison), and DecompositionLog (detailed decomposition trace).
This test confirms that debug contexts properly initialize all logging infrastructure to support detailed plan analysis during development.
]]
print("    > InitInitializeDebugCollections_ExpectedBehavior")
ctx = TestDebugContext:new()
ctx:Init()
assert(true == ctx.DebugMTR)
assert(true == ctx.LogDecomposition)
assert(ctx.MTRDebug)
assert(ctx.LastMTRDebug)

--[[
Verifies that HasState correctly checks if a world state value is currently true based on the context's world state representation.
HasState is a convenience method that checks the byte array representation of world state, treating non-zero values as true.
The context tracks world state using enum-indexed byte arrays for type safety and performance, where each state can be either 0 (false) or 1 (true).
This test demonstrates that HasState accurately reflects the current world state after modifications have been applied.
]]
print("    > HasState_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(false == ctx:HasState(TestContext.TestEnum.StateA))
assert(true == ctx:HasState(TestContext.TestEnum.StateB))

--[[
Verifies that SetState in Planning context mode tracks state changes on the WorldStateChangeStack without modifying the actual WorldState array.
During planning, effects are applied speculatively to explore decomposition paths; the change stack records these modifications so they can be rolled back.
SetState pushes the effect and value onto the state's stack but leaves the WorldState byte array unchanged, allowing the planner to rewind changes.
This test confirms the critical planning behavior: state changes are tracked for lookahead without modifying the actual state until execution.
]]
print("    > SetStatePlanningContext_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(true == ctx:HasState(TestContext.TestEnum.StateB))
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 1)
assert(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB]:peek()[1] == sb_htn.Effects.EEffectType.Permanent)
assert(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB]:peek()[2] == 1)
assert(ctx.WorldState[TestContext.TestEnum.StateB] == 0)

--[[
Verifies that SetState in Executing context mode immediately modifies the WorldState array without tracking changes on the stack.
During execution, effects are applied directly to the world state because there is no need to track them for rollback.
Executing context treats SetState as a direct state mutation, with changes immediately visible in the WorldState byte array.
This test confirms that execution properly applies effects to the actual world state for normal game/application logic.
]]
print("    > SetStateExecutingContext_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(true == ctx:HasState(TestContext.TestEnum.StateB))
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 0)
assert(ctx.WorldState[TestContext.TestEnum.StateB] == 1)

--[[
Verifies that GetState in Planning context returns the effect-modified value from the change stack, providing lookahead during decomposition.
GetState checks if there are pending changes in the change stack and returns the modified value if found, otherwise returns the base state.
This enables conditions to evaluate the speculative world state during planning, allowing the planner to make decisions based on what the world would be after planned effects.
This test confirms that GetState properly implements the lookahead mechanism for informed task selection during decomposition.
]]
print("    > GetStatePlanningContext_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(0 == ctx:GetState(TestContext.TestEnum.StateA))
assert(1 == ctx:GetState(TestContext.TestEnum.StateB))

--[[
Verifies that GetState in Executing context returns the actual world state from the WorldState byte array.
During execution, there is no change stack to consult—GetState simply returns the current world state values directly.
This ensures tasks executing see the real, current world state, not a speculative state for planning purposes.
This test confirms that GetState provides accurate state information during task execution for proper behavior control.
]]
print("    > GetStateExecutingContext_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(0 == ctx:GetState(TestContext.TestEnum.StateA))
assert(1 == ctx:GetState(TestContext.TestEnum.StateB))

--[[
Verifies that GetWorldStateChangeDepth correctly captures the current depth of the change stack for each world state.
GetWorldStateChangeDepth creates a snapshot of the stack depths that can be used to restore the state to this point later via TrimToStackDepth.
During executing, no changes are tracked so all depths remain zero; during planning, depths reflect the number of effects applied to each state.
This test demonstrates the snapshot mechanism that enables the planner to backtrack and explore alternative decomposition paths.
]]
print("    > GetWorldStateChangeDepth_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
local changeDepthExecuting = ctx:GetWorldStateChangeDepth(ctx.Factory)
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
local changeDepthPlanning = ctx:GetWorldStateChangeDepth(ctx.Factory)
assert(table.size(ctx.WorldStateChangeStack) == table.size(changeDepthExecuting))
assert(0 == changeDepthExecuting[TestContext.TestEnum.StateA])
assert(0 == changeDepthExecuting[TestContext.TestEnum.StateB])
assert(table.size(ctx.WorldStateChangeStack) == table.size(changeDepthPlanning))
assert(0 == changeDepthPlanning[TestContext.TestEnum.StateA])
assert(1 == changeDepthPlanning[TestContext.TestEnum.StateB])

--[[
Verifies that TrimForExecution removes PlanOnly effects and applies selected effects to the world state, preparing the context for execution.
TrimForExecution is called after a successful plan to clean up planning artifacts and apply the actual world state changes from the plan.
PlanOnly effects are removed (they were only for planning lookahead), Permanent effects stay in the stack, and PlanAndExecute effects transition from stack to world state.
This test demonstrates the critical transition from planning mode to execution mode, where speculative changes become actual world modifications.
]]
print("    > TrimForExecution_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.PlanAndExecute)
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
ctx:SetState(TestContext.TestEnum.StateC, true, sb_htn.Effects.EEffectType.PlanOnly)
ctx:TrimForExecution()
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateC].list) == 0)

--[[
Verifies that TrimForExecution throws an exception when called in Executing context state rather than Planning.
TrimForExecution is only meaningful during Planning mode when there is a change stack to process; calling it during Execution indicates a programming error.
The exception prevents accidental state corruption by rejecting transitions that only make sense in Planning mode.
This test ensures the context validates its state and fails fast rather than silently performing invalid operations.
]]
print("    > TrimForExecutionThrowsExceptionIfWrongContextState_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
if (pcall(function() ctx:TrimForExecution() end)) then
    print("Exception not caught.")
end

--[[
Verifies that TrimToStackDepth correctly restores the change stack to a previously captured depth, enabling backtracking during decomposition.
TrimToStackDepth is used by the planner when backtracking to explore alternative task decompositions after one path fails.
It pops changes from the stack until each state's stack matches the provided depth array, effectively undoing speculative changes made during exploration.
This test demonstrates the backtracking mechanism that enables the planner to explore multiple task decomposition paths in a single planning cycle.
]]
print("    > TrimToStackDepth_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.PlanAndExecute)
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
ctx:SetState(TestContext.TestEnum.StateC, true, sb_htn.Effects.EEffectType.PlanOnly)
local stackDepth = ctx:GetWorldStateChangeDepth(ctx.Factory)
ctx:SetState(TestContext.TestEnum.StateA, false, sb_htn.Effects.EEffectType.PlanAndExecute)
ctx:SetState(TestContext.TestEnum.StateB, false, sb_htn.Effects.EEffectType.Permanent)
ctx:SetState(TestContext.TestEnum.StateC, false, sb_htn.Effects.EEffectType.PlanOnly)
ctx:TrimToStackDepth(stackDepth)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateC].list) == 1)

--[[
Verifies that TrimToStackDepth throws an exception when called in Executing context state rather than Planning.
TrimToStackDepth is only meaningful during Planning mode when there is a change stack to manage; calling it during Execution is a programming error.
The exception prevents accidental state corruption by rejecting backtracking operations that only make sense during plan exploration.
This test ensures the context validates its state for all planning-specific operations and fails fast on invalid usage patterns.
]]
print("    > TrimToStackDepthThrowsExceptionIfWrongContextState_ExpectedBehavior")
ctx = TestContext:new()
ctx:Init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
stackDepth = ctx:GetWorldStateChangeDepth(ctx.Factory)
if (pcall(function() ctx:TrimToStackDepth(stackDepth) end)) then
    print("Exception not caught.")
end