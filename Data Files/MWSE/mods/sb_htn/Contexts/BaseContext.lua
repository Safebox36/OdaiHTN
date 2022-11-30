local IContext = require("Contexts.IContext")
local EEffectType = require("Effects.EEffectType")
local Stack = require("Utils.Stack")

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

    function BaseContext:Init()
        self.IsInitialized = true
    end

    function BaseContext:HasState(state, value)
        return self:GetState(state) == value
    end

    function BaseContext:GetState(state)
        if (self.ContextState == IContext.EContextState.Executing) then return self.WorldState[state] end

        if (#self.WorldStateChangeStack[state] == 0) then return self.WorldState[state] end

        return self.WorldStateChangeStack[state][2]
    end

    function BaseContext:SetState(state, value, setAsDirty, e)
        if (self.ContextState == IContext.EContextState.Executing) then
            -- Prevent setting the world state dirty if we're not changing anything.
            if (self.WorldState[state] == value) then
                return
            end

            self.WorldState[state] = value
            if (setAsDirty) then
                self.IsDirty = true -- When a state change during execution, we need to mark the context dirty for replanning!
            end
        else
            Stack.push(self.WorldStateChangeStack[state], {e, value})
        end
    end

    function BaseContext:GetWorldStateChangeDepth(factory)
        local stackDepth = factory.CreateArray(#self.WorldStateChangeStack)
        for i = 0, #self.WorldStateChangeStack, 1 do stackDepth[i] = #self.WorldStateChangeStack[i] or 0 end

        return stackDepth
    end

    function BaseContext:TrimForExecution()
        assert(self.ContextState == IContext.EContextState.Executing, "Can not trim a context when in execution mode")

        for _, stack in ipairs(self.WorldStateChangeStack) do
            while (#stack ~= 0 and stack[1] ~= EEffectType.Permanent) do
                Stack.pop(stack)
            end
        end
    end

    function BaseContext:TrimToStackDepth(stackDepth)
        assert(self.ContextState == self.EContextState.Executing, "Can not trim a context when in execution mode")

        for i = 0, #stackDepth, 1 do
            local stack = self.WorldStateChangeStack[i]
            while (#stack > stackDepth[i]) do Stack.pop(stack) end
        end
    end

    function BaseContext:Reset()
        self.MethodTraversalRecord = {}
        self.LastMTR = {}

        if (self.DebugMTR) then
            self.MTRDebug = {}
            self.LastMTRDebug = {}
        end

        self.IsInitialized = false
    end

return BaseContext
