## ﻿Features

* [Total-order forward decomposition planner](http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter12_Exploring_HTN_Planners_through_Example.pdf).
* Pre-existing Domain Builder to simplify the design of code-oriented HTN domains.
* Partial planning.
* Domain splicing.
* Domain slots for run-time splicing.
* Replan only when plans complete/fail or when world state change.
* Early rejection of replanning that can't succeed.
* Easy to extend.
* Uses a Factory interface internally to create and free tables/queues/stacks/objects, allowing for pooling, or other memory management schemes.
* Decomposition logging, for debugging.
* Minimal MWSE dependency, allowing for easy porting to OpenMW (official port to come).

## Concepts

### Compound Tasks
High level tasks that have multiple ways of being accomplished. There are primarily two types of compound tasks:

* Selectors must be able to decompose a single sub-task.
* Sequencers must be able to decompose all its sub-tasks successfully for itself to have decomposed successfully.
These tasks are decomposed until left with only Primitive Tasks, which represent a final plan. Compound tasks are comprised of a set of subtasks and a set of conditions.

### Primitive Tasks
Represent a single step that can be performed. A set of Primitive Tasks is the plan that are ultimately getting out of OdaiHTN. Primitive Tasks are comprised:

* Operators
* Effects
* Conditions
* Executing Conditions.

### Conditions
Boolean validators that can be used to validate the decomposition of a Compound Task, or the validity of a Primitive Task. Primitive Tasks also have Executing Conditions, which we validate before every update to the primary task's Operator during execution of a plan.

### Executing Conditions
Special conditions that are evaluated every planner tick; useful for cases where you need to re-evaluate the validity of your conditions after planning and after setting a new task as current task during execution. In the case where the operator returns continue and the condition becomes "invalid", the planner will not automatically know. Using Executing Conditions is one way to ensure that the planner realizes that the task is now invalid. Another way is to put this logic inside the Operator and have it return Failure, which should yield the same result in practice thus triggering a replan.

### Operators
Logic operation that a Primitive Task should perform during plan execution. Every time an Operator updates, it returns a status whether it Succeeded, Failed or needs to Continue next tick.

## Tutorial

First we need to set up a WorldState enum and a Context. This is a canvas used by the planner to access states during its planning procedure.

```lua
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
```

For convenience, the context can be extended with state manipulation methods like so.

```lua
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
```
Next we have what we need to define a new domain.

```lua
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
```

Now that we have a domain, we can start to generate a plan. First, we need to instantiate our planner and the context.

```lua
---@class MyContext
local ctx = MyContext:new()
---@class Planner
local planner = sb_htn.Planners.Planner:new()
ctx:Init()
```

Next, let's tick the planner until the Done flag in our context is set to true.

```lua
while (not ctx.Done) do
    planner:Tick(domain, ctx)
end
```

Now if we run this example, we should see the following in the console.

```
Get A
Get B
Get C
Done
```

## Extensions

OdaiHTN can be extended further, much like its C# inspiration FluidHTN. For details on how this might be done, please see that repository.

## Credit

* Pål Trefall for his [original C# framework](https://github.com/ptrefall/fluid-hierarchical-task-network).
* Enrique García Cota for [Middleclass.lua](https://github.com/kikito/middleclass).

## See Also

* [Working LÖVE prototype](https://github.com/Safebox36/Last-Party---Plus-One/tree/main/src/ai).