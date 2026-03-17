local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")

print("  > DomainBuilderTests")

--[[
Verifies that the DomainBuilder successfully constructs a domain even when the developer forgets to call End() before Build().
The fluent builder pattern uses a pointer-based navigation system to track the current position in the domain hierarchy.
When Build() is called, it should still return a valid domain with the root task properly initialized and named.
This test demonstrates that the builder is forgiving about missing End() calls, automatically resolving the pointer to the root when building.
]]
print("    > Build_ForgotEnd")
-- Arrange
local builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
local ptr = builder:Pointer()
local domain = builder:Build()
assert(domain.Root)
assert(ptr == domain.Root)
assert("Test" == domain.Root.Name)

--[[
Verifies that after Build() is called, the builder's pointer becomes invalid and throws a NullReferenceException if accessed.
This test ensures that the builder invalidates its internal state after successfully constructing a domain to prevent accidental misuse.
The pointer mechanism tracks the current position in the domain hierarchy during construction, and after Build(), this reference should be cleared.
This defensive behavior prevents developers from accidentally continuing to use the builder after the domain has been sealed and built.
]]
print("    > BuildInvalidatesPointer_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
domain = builder:Build()
if (pcall(function() assert(builder:Pointer() == domain.Root) end)) then
    print("Exception not caught.")
end

--[[
Verifies that the Select() builder method correctly creates a Selector compound task and properly restores the pointer to the parent after End() is called.
A Selector is a compound task that decomposes by selecting the first valid subtask among its children, which is fundamental to HTN planning's multi-strategy problem solving.
The builder uses a pointer stack to track nesting depth, allowing developers to fluently add nested structures and then return to the parent scope.
This test demonstrates that the pointer navigation correctly moves up the hierarchy when End() is called, returning to the TaskRoot.
]]
print("    > Selector_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Select("select test")
builder:End()
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

--[[
Verifies that when a Selector is added to the domain but End() is not called, the pointer remains pointing to the newly created Selector rather than the parent.
This test documents the builder's behavior when developers forget to properly close the nested structure.
The pointer stack tracks which task is currently being configured, and remaining at a Selector indicates the developer has not called End() to return to the parent scope.
Understanding this behavior helps developers recognize when they've made a structural mistake in their fluent builder code.
]]
print("    > Selector_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Select("select test")
-- Assert
assert(false == builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Selector))

--[[
Verifies that attempting to Build() a domain while the pointer is still inside a nested Selector (i.e., End() was not called) throws an exception.
This test validates that the builder enforces proper closing of nested structures before domain construction can complete.
The builder maintains invariants about the state of the pointer hierarchy to ensure valid domain structures are created.
This defensive check prevents silent bugs by requiring developers to properly close all nested scopes with End() calls before finalizing the domain.
]]
print("    > SelectorBuild_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Select("select test")
if (pcall(function() domain = builder:Build() end)) then
    print("Exception not caught.")
end

--[[
Verifies that the generic CompoundTask<T>() builder method correctly creates a Selector compound task when given the Selector type parameter.
This test demonstrates the generic builder pattern that allows creating any compound task type through a generic method rather than using a named method.
The CompoundTask<T>() method provides an extension point for creating custom compound task types while maintaining the fluent builder interface.
This approach increases flexibility by allowing users to define their own compound task subclasses and use them directly with the builder.
]]
print("    > Selector_CompoundTask")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Compound("select test", sb_htn.Tasks.CompoundTasks.Selector)
-- Assert
assert(false == builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Selector))

--[[
Verifies that the Sequence() builder method correctly creates a Sequence compound task and properly restores the pointer to the parent after End() is called.
A Sequence is a compound task that requires all its subtasks to decompose successfully in order, contrasting with Selectors which choose only the first valid option.
Sequences represent ordered, dependent task decompositions that are essential for expressing workflows where each step must complete before the next begins.
This test demonstrates that the fluent builder interface works correctly for Sequences, including proper pointer stack management through nesting.
]]
print("    > Sequence_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Sequence("sequence test")
builder:End()
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

--[[
Verifies that when a Sequence is added to the domain but End() is not called, the pointer remains pointing to the Sequence rather than the parent.
This test documents how the builder behaves when developers omit End() calls in their fluent chain, leaving the pointer at an intermediate level of the hierarchy.
The Sequence remains the active pointer, allowing the developer to continue adding subtasks to it, which may or may not be the intended behavior.
This behavior highlights why proper End() calls are necessary to navigate back up the pointer stack to parent contexts.
]]
print("    > Sequence_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Sequence("sequence test")
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Sequence))

--[[
Verifies that the generic CompoundTask<Sequence>() builder method correctly creates a Sequence compound task.
This test demonstrates the alternative generic approach to creating compound tasks, providing consistency with other task creation methods.
The generic CompoundTask<T>() method allows type-safe instantiation of any compound task type that has a parameterless constructor.
This pattern supports extensibility by allowing custom compound task implementations to integrate seamlessly into the fluent builder interface.
]]
print("    > Sequence_CompoundTask")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Compound("sequence test", sb_htn.Tasks.CompoundTasks.Sequence)
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Sequence))

--[[
Verifies that the Action() builder method correctly creates a PrimitiveTask and properly restores the pointer to the parent after End() is called.
An Action is a primitive task that represents an atomic, executable unit of work in the hierarchical task network.
Primitive tasks are the leaf nodes of the domain hierarchy where actual execution occurs through their associated operators.
This test demonstrates that primitive task creation integrates correctly with the fluent builder pattern, despite primitive tasks not having subtasks.
]]
print("    > Action_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Action("sequence test")
builder:End()
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

--[[
Verifies that when a primitive task (Action) is added to the domain but End() is not called, the pointer remains pointing to the primitive task.
This test documents the builder's behavior when developers forget to call End() after creating a primitive task.
Unlike compound tasks that have subtasks, primitive tasks are leaves in the hierarchy where the pointer naturally rests after creation.
The pointer can still be used to add conditions, operators, and effects to the primitive task before calling End() to return to the parent scope.
]]
print("    > Action_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Action("sequence test")
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

--[[
Verifies that the generic PrimitiveTask<T>() builder method correctly creates a primitive task using the generic pattern.
This test demonstrates the alternative generic approach to creating primitive tasks, providing consistency with the generic CompoundTask<T>() pattern.
The generic PrimitiveTask<T>() method allows instantiation of custom primitive task implementations while maintaining type safety.
This approach supports extensibility by allowing users to define custom primitive task subclasses and integrate them into the builder interface.
]]
print("    > Action_PrimitiveTask")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:PrimitiveTask("sequence test", sb_htn.Tasks.PrimitiveTasks.PrimitiveTask)
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

--[[
Verifies that calling PausePlan() when the current pointer is not pointing to a compound task that implements IDecomposeAll throws an exception.
PausePlan() is used to insert a pause point in a Sequence, allowing the planner to split the plan into multiple execution cycles.
This builder method only makes semantic sense within sequences, not at the domain root or within other task types.
This test ensures the builder validates that PausePlan() is only called in valid contexts, preventing logical errors in domain definitions.
]]
print("    > PausePlanThrowsWhenPointerIsNotDecomposeAll")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
if (pcall(function() builder:PausePlan() end)) then
    print("Exception not caught.")
end

--[[
Verifies that PausePlan() correctly creates a pause point within a Sequence and properly restores the pointer to the parent after End() is called.
PausePlan() adds a special PausePlanTask to the sequence, allowing the planner to interrupt execution and resume later in multiple planning cycles.
This feature is essential for implementing long-running planning tasks that need to decompose incrementally rather than all at once.
This test demonstrates that the pointer correctly navigates back to the TaskRoot after closing the sequence containing the pause point.
]]
print("    > PausePlan_ExpectedBehaviour")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Sequence("sequence test")
builder:PausePlan()
builder:End()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

--[[
Verifies that when PausePlan() is called in a Sequence but End() is not called, the pointer remains at the Sequence level.
This test documents the expected behavior when developers forget to close the Sequence after inserting a pause point.
The pointer stack correctly maintains position at the Sequence, allowing further builder operations to be applied to the containing sequence.
This behavior is consistent with how other builder methods handle missing End() calls.
]]
print("    > PausePlan_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Sequence("sequence test")
builder:PausePlan()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Sequence))

--[[
Verifies that the Condition() builder method correctly adds a planning condition to the current task and maintains the pointer at the parent level.
Conditions are lambda-based validators that determine whether a task can be decomposed during planning, controlling the validity of branches in the task hierarchy.
Conditions are essential to HTN planning because they allow encoding preconditions that must be satisfied before task decomposition can proceed.
This test demonstrates that adding a condition to a task using the fluent builder does not change the pointer's position.
]]
print("    > Condition_ExpectedBehaviour")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Condition("test", function(ctx) return true end)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

--[[
Verifies that calling ExecutingCondition() on a non-primitive task pointer throws an exception.
Executing conditions are runtime validators that are checked immediately before a primitive task executes, not during planning.
This builder method only makes semantic sense when the pointer is a primitive task, since only primitive tasks execute at runtime.
This test ensures the builder validates ExecutingCondition() is only applied to appropriate task types, preventing logical configuration errors.
]]
print("    > ExecutingCondition_ThrowsIfNotPrimitiveTaskPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
if (pcall(function() builder:ExecutingCondition("test", function(ctx) return true end) end)) then
    print("Exception not caught.")
end

--[[
Verifies that ExecutingCondition() correctly adds a runtime condition to a primitive task and properly restores the pointer to the parent after End() is called.
Executing conditions are checked every tick before the primitive task's operator runs, allowing dynamic validation of preconditions during plan execution.
Unlike planning conditions which are evaluated once during domain decomposition, executing conditions provide continuous, tick-based validation.
This test demonstrates that executing conditions integrate properly with the fluent builder pattern for primitive tasks.
]]
print("    > ExecutingCondition_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Action("test")
builder:ExecutingCondition("test", function(ctx) return true end)
builder:End()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

--[[
Verifies that when ExecutingCondition() is called on a primitive task but End() is not called, the pointer remains at the primitive task.
This test documents the expected pointer behavior when developers forget to call End() after adding an executing condition.
The pointer correctly remains at the primitive task, allowing additional builder operations like Do() or Effect() to be chained.
This behavior is consistent with how other primitive task configuration methods work.
]]
print("    > ExecutingCondition_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Action("test")
builder:ExecutingCondition("test", function(ctx) return true end)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

--[[
Verifies that calling Do() on a non-primitive task pointer throws an exception.
Do() attaches the operator (execution logic) to a primitive task, so it only makes semantic sense when the pointer is a primitive task.
Compound tasks do not have operators because they decompose into subtasks rather than executing directly.
This test ensures the builder validates Do() is only applied to primitive tasks, catching configuration errors early.
]]
print("    > Do_ThrowsIfNotPrimitiveTaskPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
if (pcall(function() builder:Do(function(ctx) return sb_htn.Tasks.ETaskStatus.Success end) end)) then
    print("Exception not caught.")
end

--[[
Verifies that Do() correctly attaches an operator to a primitive task and properly restores the pointer to the parent after End() is called.
Do() wraps a lambda function in a FuncOperator and assigns it to the primitive task, enabling the task to execute custom logic during plan execution.
The operator receives the task status during each tick and returns Continue, Success, or Failure to control plan progression.
This test demonstrates that operator attachment integrates properly with the fluent builder pattern for primitive tasks.
]]
print("    > Do_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Action("test")
builder:Do(function(ctx) return sb_htn.Tasks.ETaskStatus.Success end)
builder:End()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

--[[
Verifies that when Do() is called on a primitive task but End() is not called, the pointer remains at the primitive task.
This test documents the expected pointer behavior when developers forget to call End() after attaching an operator.
The pointer correctly remains at the primitive task, allowing additional builder operations like Effect() to be chained.
This behavior supports a natural fluent interface where multiple primitive task properties can be configured before returning to the parent.
]]
print("    > Do_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Action("test")
builder:Do(function(ctx) return sb_htn.Tasks.ETaskStatus.Success end)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

--[[
Verifies that calling Effect() on a non-primitive task pointer throws an exception.
Effect() adds world state modifications that occur when a task completes, which only applies to primitive tasks that execute and return a completion status.
Compound tasks decompose but do not directly execute, so attaching effects to them is semantically invalid.
This test ensures the builder validates Effect() is only applied to primitive tasks, preventing logical configuration errors.
]]
print("    > Effect_ThrowsIfNotPrimitiveTaskPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
if (pcall(function() builder:Effect("test", sb_htn.Effects.EEffectType.Permanent, function(ctx, effectType) return end) end)) then
    print("Exception not caught.")
end

--[[
Verifies that Effect() correctly adds a world state effect to a primitive task and properly restores the pointer to the parent after End() is called.
Effect() wraps a lambda function in an ActionEffect and assigns it to the task, enabling automatic world state modifications when the task completes.
Effects are essential to HTN planning because they allow the planner to maintain an accurate model of world state during decomposition and lookahead.
This test demonstrates that effect attachment integrates properly with the fluent builder pattern for primitive tasks.
]]
print("    > Effect_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Action("test")
builder:Effect("test", sb_htn.Effects.EEffectType.Permanent, function(ctx, effectType) return end)
builder:End()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

--[[
Verifies that when Effect() is called on a primitive task but End() is not called, the pointer remains at the primitive task.
This test documents the expected pointer behavior when developers forget to call End() after adding an effect.
The pointer correctly remains at the primitive task, allowing additional builder operations to be chained before returning to the parent.
This behavior enables a fluent interface where multiple task properties (conditions, operators, effects) can be configured sequentially.
]]
print("    > Effect_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Action("test")
builder:Effect("test", sb_htn.Effects.EEffectType.Permanent, function(ctx, effectType) return end)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

--[[
Verifies that calling Splice() on a non-compound task pointer throws an exception.
Splice() merges a sub-domain's root task into the current compound task, which only makes sense when the pointer is a compound task.
Primitive tasks cannot have subtasks spliced into them since they are leaf nodes that execute directly.
This test ensures the builder validates Splice() is only applied to compound tasks, preventing logical configuration errors.
]]
print("    > Splice_ThrowsIfNotCompoundPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
domain = sb_htn.DomainBuilder:new(TestContext, "sub-domain"):Build()
builder:Action("test")
if (pcall(function() builder:Splice(domain) end)) then
    print("Exception not caught.")
end

--[[
Verifies that Splice() correctly merges a sub-domain's root task into the current compound task and properly restores the pointer to the parent.
Splice() is a domain composition mechanism that allows breaking large hierarchies into smaller, reusable sub-domains that can be combined at runtime.
Unlike slots which provide insertion points for multiple sub-domains, splice performs a one-time merge of all subtasks from a sub-domain's root.
This test demonstrates that splicing integrates correctly with the fluent builder pattern, maintaining proper pointer navigation.
]]
print("    > Splice_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
domain = sb_htn.DomainBuilder:new(TestContext, "sub-domain"):Build()
builder:Splice(domain)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

--[[
Verifies that when Splice() is called on a compound task but End() is not called, the pointer remains at the compound task.
This test documents the expected pointer behavior when developers forget to call End() after splicing a sub-domain.
The pointer correctly remains at the compound task, allowing additional builder operations to be applied to the containing compound task.
This behavior is consistent with how other compound task operations work in the fluent builder interface.
]]
print("    > Splice_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
domain = sb_htn.DomainBuilder:new(TestContext, "sub-domain"):Build()
builder:Select("test")
builder:Splice(domain)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Selector))

--[[
Verifies that calling Slot() on a non-compound task pointer throws an exception.
Slot() creates an insertion point for runtime domain splicing, which only makes sense when added to a compound task.
Slots are special ICompoundTask implementations that hold references to sub-domains and enable dynamic behavior composition at runtime.
This test ensures the builder validates Slot() is only applied to compound tasks, preventing configuration errors.
]]
print("    > Slot_ThrowsIfNotCompoundPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Action("test")
if (pcall(function() builder:Slot(1) end)) then
    print("Exception not caught.")
end

--[[
Verifies that attempting to define a slot with an ID that has already been used throws an exception.
Slot IDs must be unique within a domain to serve as identifiable insertion points for runtime domain binding.
This test ensures the builder prevents accidental slot ID duplication, which would create ambiguity about which slot receives a sub-domain binding.
This validation catches errors early in the domain building process rather than causing runtime failures.
]]
print("    > Slot_ThrowsIfSlotIdAlreadyDefined")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Slot(1)
if (pcall(function() builder:Slot(1) end)) then
    print("Exception not caught.")
end

--[[
Verifies that Slot() correctly creates an insertion point for runtime domain splicing and demonstrates the complete slot lifecycle.
This comprehensive test shows how slots enable runtime domain composition: defining a slot in the domain, building the domain, creating a sub-domain,
attempting invalid operations (rebinding without clearing, binding to undefined slots), and finally clearing and rebinding slots dynamically.
Slots are essential for smart object systems and other dynamic AI architectures that need to adapt behavior without recompiling domains.
This test validates that the entire slot mechanism integrates correctly with the builder pattern and domain runtime operations.
]]
print("    > Slot_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Slot(1)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))
domain = builder:Build()
local subDomain = sb_htn.DomainBuilder:new(TestContext, "sub-domain"):Build()
assert(domain:TrySetSlotDomain(1, subDomain))           -- Its valid to add a sub-domain to a slot we have defined in our domain definition, and that is not currently occupied.
assert(domain:TrySetSlotDomain(1, subDomain) == false)  -- Need to clear slot before we can attach sub-domain to a currently occupied slot.
assert(domain:TrySetSlotDomain(99, subDomain) == false) -- Need to define slotId in domain definition before we can attach sub-domain to that slot.
assert(table.size(domain.Root.Subtasks) == 1)
assert(domain.Root.Subtasks[1]:isInstanceOf(sb_htn.Tasks.OtherTasks.Slot))
local slot = domain.Root.Subtasks[1]
assert(slot.Subtask)
assert(slot.Subtask:isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))
assert(slot.Subtask.Name == "sub-domain")
domain:ClearSlot(1)
assert(slot.Subtask == nil)

--[[
Verifies that when Slot() is called on a compound task but End() is not called, the pointer remains at the compound task.
This test documents the expected pointer behavior when developers forget to call End() after defining a slot.
The pointer correctly remains at the containing compound task, allowing additional builder operations to be applied.
This behavior is consistent with how other compound task operations work in the fluent builder interface.
]]
print("    > Slot_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new(TestContext, "Test")
-- Act
builder:Select("test")
builder:Slot(1)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Selector))