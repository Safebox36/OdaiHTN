local sb_htn = require("sb_htn.interop")
local TestContext = require("sb_htn_tests.TestContext")

print(">>> DomainBuilderTests")

print("> Build_ForgotEnd")
-- Arrange
local builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
local ptr = builder:Pointer()
local domain = builder:Build()
assert(domain.Root ~= nil)
assert(ptr == domain.Root)
assert("Test" == domain.Root.Name)

print("> BuildInvalidatesPointer_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
domain = builder:Build()
if (pcall(function() assert(builder:Pointer() == domain.Root) end)) then
    print("Exception not caught.")
end

print("> Selector_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Select("select test")
builder:End()
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

print("> Selector_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Select("select test")
-- Assert
assert(false == builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Selector))

print("> SelectorBuild_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Select("select test")
if (pcall(function() domain = builder:Build() end)) then
    print("Exception not caught.")
end

print("> Selector_CompoundTask")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Compound("select test", sb_htn.Tasks.CompoundTasks.Selector)
-- Assert
assert(false == builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Selector))

print("> Sequence_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Sequence("sequence test")
builder:End()
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

print("> Sequence_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Sequence("sequence test")
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Sequence))

print("> Sequence_CompoundTask")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Compound("sequence test", sb_htn.Tasks.CompoundTasks.Sequence)
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Sequence))

print("> Action_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Action("sequence test")
builder:End()
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

print("> Action_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Action("sequence test")
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

print("> Action_PrimitiveTask")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:PrimitiveTask("sequence test", sb_htn.Tasks.PrimitiveTasks.PrimitiveTask)
-- Assert
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

print("> PausePlanThrowsWhenPointerIsNotDecomposeAll")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
if (pcall(function() builder:PausePlan() end)) then
    print("Exception not caught.")
end

print("> PausePlan_ExpectedBehaviour")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Sequence("sequence test")
builder:PausePlan()
builder:End()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

print("> PausePlan_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Sequence("sequence test")
builder:PausePlan()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Sequence))

print("> Condition_ExpectedBehaviour")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Condition("test", function(ctx) return true end)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

print("> ExecutingCondition_ThrowsIfNotPrimitiveTaskPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
if (pcall(function() builder:ExecutingCondition("test", function(ctx) return true end) end)) then
    print("Exception not caught.")
end

print("> ExecutingCondition_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Action("test")
builder:ExecutingCondition("test", function(ctx) return true end)
builder:End()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

print("> ExecutingCondition_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Action("test")
builder:ExecutingCondition("test", function(ctx) return true end)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

print("> Do_ThrowsIfNotPrimitiveTaskPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
if (pcall(function() builder:Do(function(ctx) return sb_htn.Tasks.ETaskStatus.Success end) end)) then
    print("Exception not caught.")
end

print("> Do_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Action("test")
builder:Do(function(ctx) return sb_htn.Tasks.ETaskStatus.Success end)
builder:End()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

print("> Do_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Action("test")
builder:Do(function(ctx) return sb_htn.Tasks.ETaskStatus.Success end)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

print("> Effect_ThrowsIfNotPrimitiveTaskPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
if (pcall(function() builder:Effect("test", sb_htn.Effects.EEffectType.Permanent, function(ctx, t) return end) end)) then
    print("Exception not caught.")
end

print("> Effect_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Action("test")
builder:Effect("test", sb_htn.Effects.EEffectType.Permanent, function(ctx, t) return end)
builder:End()
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

print("> Effect_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Action("test")
builder:Effect("test", sb_htn.Effects.EEffectType.Permanent, function(ctx, t) return end)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask))

print("> Splice_ThrowsIfNotCompoundPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
domain = sb_htn.DomainBuilder:new("sub-domain", nil, TestContext):Build()
builder:Action("test")
if (pcall(function() builder:Splice(domain) end)) then
    print("Exception not caught.")
end

print("> Splice_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
domain = sb_htn.DomainBuilder:new("sub-domain", nil, TestContext):Build()
builder:Splice(domain)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))

print("> Splice_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
domain = sb_htn.DomainBuilder:new("sub-domain", nil, TestContext):Build()
builder:Select("test")
builder:Splice(domain)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Selector))

print("> Slot_ThrowsIfNotCompoundPointer")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Action("test")
if (pcall(function() builder:Slot(1) end)) then
    print("Exception not caught.")
end

print("> Slot_ThrowsIfSlotIdAlreadyDefined")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Slot(1)
if (pcall(function() builder:Slot(1) end)) then
    print("Exception not caught.")
end

print("> Slot_ExpectedBehavior")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Slot(1)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))
domain = builder:Build()
local subDomain = sb_htn.DomainBuilder:new("sub-domain", nil, TestContext):Build()
assert(domain:TrySetSlotDomain(1, subDomain)) -- Its valid to add a sub-domain to a slot we have defined in our domain definition, and that is not currently occupied.
assert(domain:TrySetSlotDomain(1, subDomain) == false) -- Need to clear slot before we can attach sub-domain to a currently occupied slot.
assert(domain:TrySetSlotDomain(99, subDomain) == false) -- Need to define slotId in domain definition before we can attach sub-domain to that slot.
assert(table.size(domain.Root.Subtasks) == 1)
assert(domain.Root.Subtasks[1]:isInstanceOf(sb_htn.Tasks.OtherTasks.Slot))
local slot = domain.Root.Subtasks[1]
assert(slot.Subtask ~= nil)
assert(slot.Subtask:isInstanceOf(sb_htn.Tasks.CompoundTasks.TaskRoot))
assert(slot.Subtask.Name == "sub-domain")
domain:ClearSlot(1)
assert(slot.Subtask == nil)

print("> Slot_ForgotEnd")
-- Arrange
builder = sb_htn.DomainBuilder:new("Test", nil, TestContext)
-- Act
builder:Select("test")
builder:Slot(1)
assert(builder:Pointer():isInstanceOf(sb_htn.Tasks.CompoundTasks.Selector))
