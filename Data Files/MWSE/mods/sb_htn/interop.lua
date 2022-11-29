return {
    Conditions = {
        ICondition = require("Conditions.ICondition"),
        FuncCondition = require("Conditions.FuncCondition")
    },

    Contexts = {
        IContext = require("Contexts.IContext"),
        BaseContext = require("Contexts.BaseContext"),
    },

    Effects = {
        IEffect = require("Effects.IEffect"),
        EEffectType = require("Effects.EEffectType"),
        ActionEffect = require("Effects.ActionEffect"),
    },

    Factory = {
        IFactory = require("Factory.IFactory"),
        DefaultFactory = require("Factory.DefaultFactory"),
    },

    Operators = {
        IOperator = require("Operators.IOperator"),
        FuncOperator = require("Operators.FuncOperator"),
    },

    Planners = {
        Planner = require("Planners.Planner"),
    },

    Tasks = {
        ITask = require("Tasks.ITask"),
        ETaskStatus = require("Tasks.ETaskStatus"),

        CompoundTasks = {
            ICompoundTask = require("Tasks.CompoundTasks.ICompoundTask"),
            IDecomposeAll = require("Tasks.CompoundTasks.IDecomposeAll"),
            EDecompositionStatus = require("Tasks.CompoundTasks.EDecompositionStatus"),
            CompoundTask = require("Tasks.CompoundTasks.CompoundTask"),
            PausePlanTask = require("Tasks.CompoundTasks.PausePlanTask"),
            Selector = require("Tasks.CompoundTasks.Selector"),
            Sequence = require("Tasks.CompoundTasks.Sequence"),
            TaskRoot = require("Tasks.CompoundTasks.TaskRoot"),
        },

        OtherTasks = {
            Slot = require("Tasks.OtherTasks.Slot"),
        },

        PrimitiveTasks = {
            IPrimitiveTask = require("Tasks.PrimitiveTasks.IPrimitiveTask"),
            PrimitiveTask = require("Tasks.PrimitiveTasks.PrimitiveTask")
        }
    },

    IDomain = require("IDomain"),
    BaseDomainBuilder = require("BaseDomainBuilder"),
    Domain = require("Domain"),
    DomainBuilder = require("DomainBuilder")
}
