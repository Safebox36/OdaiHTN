local IContext = require("Contexts.IContext")
local EEffectType = require("Effects.EEffectType")

---@class BaseContext : IContext
local BaseContext = {}

function BaseContext.new()
    return IContext.new()
end

---@type boolean
BaseContext.IsInitialized = false
---@type boolean
BaseContext.IsDirty = false
---@type EContextState    
BaseContext.ContextState = IContext.EContextState.Executing
---@type integer
BaseContext.CurrentDecompositionDepth = 0
    ---@type IFactory
    BaseContext.Factory = {}
    ---@type table<integer>
    BaseContext.MethodTraversalRecord = {}
    ---@type table<integer>
    BaseContext.LastMTR = {}
    ---@type table<integer>
    BaseContext.MTRDebug = {}
    ---@type table<integer>
    BaseContext.LastMTRDebug = {}
---@type boolean
BaseContext.DebugMTR = false
---@type Queue<PartialPlanEntry>
BaseContext.PartialPlanQueue = {}
---@type boolean
BaseContext.HasPausedPartialPlan = false

---@type number[]
BaseContext.WorldState = { }

    ---@type Stack<table<EEffectType, number>>[]
    BaseContext.WorldStateChangeStack = {}

    function BaseContext.Init()
        BaseContext.IsInitialized = true
    end

    function BaseContext.HasState(state, value)
        return BaseContext.GetState(state) == value
    end

    function BaseContext.GetState(state)
        if (BaseContext.ContextState == IContext.EContextState.Executing) then return BaseContext.WorldState[state] end

        if (#BaseContext.WorldStateChangeStack[state] == 0) then return BaseContext.WorldState[state] end

        return BaseContext.WorldStateChangeStack[state][2]
    end

    function BaseContext.SetState(state, value, setAsDirty, e)
        if (BaseContext.ContextState == IContext.EContextState.Executing) then
            -- Prevent setting the world state dirty if we're not changing anything.
            if (BaseContext.WorldState[state] == value) then
                return
            end

            BaseContext.WorldState[state] = value
            if (setAsDirty) then
                BaseContext.IsDirty = true -- When a state change during execution, we need to mark the context dirty for replanning!
            end
        else
            BaseContext.WorldStateChangeStack[state]:push({e, value})
        end
    end

    function BaseContext.GetWorldStateChangeDepth(factory)
        local stackDepth = factory.CreateArray(#BaseContext.WorldStateChangeStack)
        for i = 0, #BaseContext.WorldStateChangeStack, 1 do stackDepth[i] = #BaseContext.WorldStateChangeStack[i] or 0 end

        return stackDepth
    end

    function BaseContext.TrimForExecution()
        assert(BaseContext.ContextState == IContext.EContextState.Executing, "Can not trim a context when in execution mode")

        for _, stack in ipairs(BaseContext.WorldStateChangeStack) do
            while (#stack ~= 0 and stack[1] ~= EEffectType.Permanent) do
                stack:pop()
            end
        end
    end

    function BaseContext.TrimToStackDepth(stackDepth)
        assert(BaseContext.ContextState == BaseContext.EContextState.Executing, "Can not trim a context when in execution mode")

        for i = 0, #stackDepth, 1 do
            local stack = BaseContext.WorldStateChangeStack[i]
            while (#stack > stackDepth[i]) do stack:pop() end
        end
    end

    function BaseContext.Reset()
        BaseContext.MethodTraversalRecord = {}
        BaseContext.LastMTR = {}

        if (BaseContext.DebugMTR) then
            BaseContext.MTRDebug = {}
            BaseContext.LastMTRDebug = {}
        end

        BaseContext.IsInitialized = false
    end

return BaseContext
