local sb_htn = require("sb_htn.interop")
local mc = require("sb_htn.Utils.middleclass")

---@enum EMyWorldState
local EMyWorldState =
{
    HasA = 1,
    HasB = 2,
    HasC = 3
}

---@class MyContext : BaseContext
local MyContext = mc.class("MyContext", sb_htn.Contexts.BaseContext)

function MyContext:initialize()
    sb_htn.Contexts.BaseContext.initialize(self)

    self.WorldState       = {}
    self.MTRDebug         = nil
    self.LastMTRDebug     = nil
    self.DebugMTR         = false
    self.LogDecomposition = false

    self.Factory          = sb_htn.Factory.DefaultFactory:new()

    for _, v in pairs(EMyWorldState) do
        self.WorldState[v] = 0
    end

    self.Done = false
end

function MyContext:Init()
    sb_htn.Contexts.BaseContext.init(self)
end

---@param state EMyWorldState
---@param value boolean | nil
function MyContext:HasState(state, value)
    if (value ~= nil) then
        return sb_htn.Contexts.BaseContext.HasState(self, state, (value and 1 or 0))
    else
        return sb_htn.Contexts.BaseContext.HasState(self, state, 1)
    end
end

---@param state EMyWorldState
---@param value boolean
---@param type EEffectType
function MyContext:SetState(state, value, type)
    sb_htn.Contexts.BaseContext.SetState(self, state, (value and 1 or 0), true, type)
end

---------

local domain = sb_htn.DomainBuilder:new(MyContext, "MyDomain")
    :Select("C")
        :Condition("Has A and B", function(ctx)
            return ctx:HasState(EMyWorldState.HasA) and ctx:HasState(EMyWorldState.HasB)
        end)
        :Condition("Has NOT C", function(ctx)
            return not ctx:HasState(EMyWorldState.HasC)
        end)
        :Action("Get C")
            :Do(function(ctx)
                print("Get C")
                return sb_htn.Tasks.ETaskStatus.Success
            end)
            :Effect("Has C", sb_htn.Effects.EEffectType.PlanAndExecute, function(ctx, effectType)
                ctx:SetState(EMyWorldState.HasC, true)
            end)
        :End()
    :End()
    :Sequence("A and B")
        :Condition("Has NOT A nor B", function(ctx)
            return not (ctx:HasState(EMyWorldState.HasA) and ctx:HasState(EMyWorldState.HasB))
        end)
        :Action("Get A")
            :Do(function(ctx)
                print("Get A")
                return sb_htn.Tasks.ETaskStatus.Success
            end)
            :Effect("Has A", sb_htn.Effects.EEffectType.PlanAndExecute, function(ctx, effectType)
                ctx:SetState(EMyWorldState.HasA, true)
            end)
        :End()
        :Action("Get B")
            :Condition("Has A", function(ctx)
                return ctx:HasState(EMyWorldState.HasA)
            end)
            :Do(function(ctx)
                print("Get B")
                return sb_htn.Tasks.ETaskStatus.Success
            end)
            :Effect("Has B", sb_htn.Effects.EEffectType.PlanAndExecute, function(ctx, effectType)
                ctx:SetState(EMyWorldState.HasB, true)
            end)
        :End()
    :End()
    :Select("Done")
        :Action("Done")
            :Do(function(ctx)
                print("Done")
                ctx.Done = true
                return sb_htn.Tasks.ETaskStatus.Continue
            end)
        :End()
    :End()
    :Build()

---------

---@class MyContext
local ctx = MyContext:new()
---@class Planner
local planner = sb_htn.Planners.Planner:new()
ctx:Init()

while (not ctx.Done) do
    planner:Tick(domain, ctx)
end
