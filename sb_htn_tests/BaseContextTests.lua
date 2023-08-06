local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")
local TestDebugContext = require("sb_htn_tests.TestDebugContext")

print(">>> BaseContextTests")

print("> DefaultContextStateIsExecuting_ExpectedBehavior")
local ctx = TestContext:new()
assert(ctx.ContextState == sb_htn.Contexts.IContext.EContextState.Executing)

print("> InitInitializeCollections_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
assert(table.size(ctx.WorldStateChangeStack) > 0)
assert(table.size(TestContext.TestEnum) == table.size(ctx.WorldStateChangeStack))
assert(false == ctx.DebugMTR)
assert(false == ctx.LogDecomposition)
assert(ctx.MTRDebug == nil)
assert(ctx.LastMTRDebug == nil)

print("> InitInitializeDebugCollections_ExpectedBehavior")
ctx = TestDebugContext:new()
ctx:init()
assert(true == ctx.DebugMTR)
assert(true == ctx.LogDecomposition)
assert(ctx.MTRDebug ~= nil)
assert(ctx.LastMTRDebug ~= nil)

print("> HasState_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(false == ctx:HasState(TestContext.TestEnum.StateA))
assert(true == ctx:HasState(TestContext.TestEnum.StateB))

print("> SetStatePlanningContext_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(true == ctx:HasState(TestContext.TestEnum.StateB))
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 1)
assert(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB]:peek()[1] == sb_htn.Effects.EEffectType.Permanent)
assert(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB]:peek()[2] == 1)
assert(ctx.WorldState[TestContext.TestEnum.StateB] == 0)

print("> SetStateExecutingContext_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(true == ctx:HasState(TestContext.TestEnum.StateB))
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 0)
assert(ctx.WorldState[TestContext.TestEnum.StateB] == 1)

print("> GetStatePlanningContext_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(0 == ctx:GetState(TestContext.TestEnum.StateA))
assert(1 == ctx:GetState(TestContext.TestEnum.StateB))

print("> GetStateExecutingContext_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
assert(0 == ctx:GetState(TestContext.TestEnum.StateA))
assert(1 == ctx:GetState(TestContext.TestEnum.StateB))

print("> GetWorldStateChangeDepth_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
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

print("> TrimForExecution_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Planning
ctx:SetState(TestContext.TestEnum.StateA, true, sb_htn.Effects.EEffectType.PlanAndExecute)
ctx:SetState(TestContext.TestEnum.StateB, true, sb_htn.Effects.EEffectType.Permanent)
ctx:SetState(TestContext.TestEnum.StateC, true, sb_htn.Effects.EEffectType.PlanOnly)
ctx:TrimForExecution()
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateA].list) == 0)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateB].list) == 1)
assert(table.size(ctx.WorldStateChangeStack[TestContext.TestEnum.StateC].list) == 0)

print("> TrimForExecutionThrowsExceptionIfWrongContextState_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
if (pcall(function() ctx:TrimForExecution() end)) then
    print("Exception not caught.")
end

print("> TrimToStackDepth_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
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

print("> TrimToStackDepthThrowsExceptionIfWrongContextState_ExpectedBehavior")
ctx = TestContext:new()
ctx:init()
ctx.ContextState = sb_htn.Contexts.IContext.EContextState.Executing
stackDepth = ctx:GetWorldStateChangeDepth(ctx.Factory)
if (pcall(function() ctx:TrimToStackDepth(stackDepth) end)) then
    print("Exception not caught.")
end
