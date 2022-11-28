---@class IContext
local IContext = {}

function IContext.new()
    return setmetatable({}, IContext)
end

--- The state our context can be in. This is essentially planning or execution state.
---@enum EContextState
IContext.EContextState =
{
    Planning = 0,
    Executing = 1
}

---@class PartialPlanEntry
IContext.PartialPlanEntry =
{
    ---@type ICompoundTask
    Task = {},
    ---@type integer
    TaskIndex = 0
}

---@type boolean
IContext.IsInitialized = false
---@type boolean
IContext.IsDirty = false
---@type EContextState
IContext.ContextState = 0
---@type integer
IContext.CurrentDecompositionDepth = 0

---@type IFactory
IContext.Factory = {}

--- The Method Traversal Record is used while decomposing a domain and
--- records the valid decomposition indices as we go through our
--- decomposition process.
--- It "should" be enough to only record decomposition traversal in Selectors.
--- This can be used to compare LastMTR with the MTR, and reject
--- a new plan early if it is of lower priority than the last plan.
--- It is the user's responsibility to set the instance of the MTR, so that
--- the user is free to use pooled instances, or whatever optimization they
--- see fit.
---@type table<integer>
IContext.MethodTraversalRecord = {}

---@type table<string>
IContext.MTRDebug = {}

--- The Method Traversal Record that was recorded for the currently
--- running plan.
--- If a plan completes successfully, this should be cleared.
--- It is the user's responsibility to set the instance of the MTR, so that
--- the user is free to use pooled instances, or whatever optimization they
--- see fit.
---@type table<integer>
IContext.LastMTR = {}

---@type table<string>
IContext.LastMTRDebug = {}

--- Whether the planning system should collect debug information about our Method Traversal Record.
---@type boolean
IContext.DebugMTR = false

--- Whether our planning system should log our decomposition. Specially condition success vs failure.
---@type boolean
IContext.LogDecomposition = false

---@type Queue<PartialPlanEntry>
IContext.PartialPlanQueue = {}

---@type boolean
IContext.HasPausedPartialPlan = false

---@type number[]
IContext.WorldState = {}

--- A stack of changes applied to each world state entry during planning.
--- This is necessary if one wants to support planner-only and plan&execute effects.
---@type Stack<table<EEffectType, number>>[]
IContext.WorldStateChangeStack = {}

--- Reset the context state to default values.
function IContext.Reset() end

function IContext.TrimForExecution() end

---@param stackDepth integer[]
function IContext.TrimToStackDepth(stackDepth) end

---@param state integer
---@param value number
---@return boolean
function IContext.HasState(state, value) return false end

---@param state integer
---@return number
function IContext.GetState(state) return 0 end

---@param state integer
---@param value number
---@param setAsDirty boolean
---@param e EEffectType
function IContext.SetState(state, value, setAsDirty, e) end

---@param factory IFactory
---@return integer[]
function IContext.GetWorldStateChangeDepth(factory) return {} end

return IContext
