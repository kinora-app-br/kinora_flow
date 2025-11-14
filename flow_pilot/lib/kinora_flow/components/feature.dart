part of '../kinora_flow.dart';

/// FlowFeature is a base class for creating features in the Flow architecture.
///
/// Features can contain components and logics, and they provide a way to organize
/// and manage different parts of the Flow architecture.
abstract class FlowFeature {
  FlowFeature();

  /// Set of components in this feature.
  @visibleForTesting
  final Set<FlowComponent> components = {};

  /// Set of initialize logics in this feature.
  @visibleForTesting
  final Set<FlowInitializeLogic> initializeLogics = {};

  /// Set of teardown logics in this feature.
  @visibleForTesting
  final Set<FlowTeardownLogic> teardownLogics = {};

  /// Set of cleanup logics in this feature.
  @visibleForTesting
  final Set<FlowCleanupLogic> cleanupLogics = {};

  /// Set of execute logics in this feature.
  @visibleForTesting
  final Set<FlowExecuteLogic> executeLogics = {};

  /// Map of reactive logics by component type.
  @visibleForTesting
  final Map<Type, Set<FlowReactiveLogic>> reactiveLogics = {};

  /// The manager that this feature is associated with.
  @protected
  @visibleForTesting
  late FlowManager manager;

  /// Number of logics in this feature.
  @visibleForTesting
  int get logicsCount {
    return initializeLogics.length +
        teardownLogics.length +
        reactiveLogics.length +
        cleanupLogics.length +
        executeLogics.length;
  }

  /// Sets the manager for this feature.
  void _setManager(FlowManager manager) {
    this.manager = manager;
  }

  /// Add an component to this feature.
  ///
  /// This method is protected and should be used by subclasses to add components.
  /// If the component is already added, it will not be added again.
  @protected
  @visibleForTesting
  void addComponent(FlowComponent component) {
    component._setFeature(this);
    components.add(component);
  }

  /// Add components to this feature.
  ///
  /// This method is protected and should be used by subclasses to add components.
  /// If the component is already added, it will not be added again.
  @protected
  @visibleForTesting
  void addComponents(Set<FlowComponent> components) {
    for (final component in components) {
      addComponent(component);
    }
  }

  /// Adds a logic to this feature.
  ///
  /// This method is protected and should be used by subclasses to add logics.
  /// If the logic is already added, it will not be added again.
  @protected
  @visibleForTesting
  void addLogic(FlowLogic logic) {
    switch (logic) {
      case FlowInitializeLogic():
        initializeLogics.add(logic);
      case FlowTeardownLogic():
        teardownLogics.add(logic);
      case FlowCleanupLogic():
        cleanupLogics.add(logic);
      case FlowExecuteLogic():
        executeLogics.add(logic);
      case FlowReactiveLogic():
        for (final component in logic.reactsTo) {
          reactiveLogics.putIfAbsent(component, () => {}).add(logic);
        }
    }

    logic._setFeature(this);
  }

  /// Adds logics to this feature.
  ///
  /// This method is protected and should be used by subclasses to add logics.
  /// If the logic is already added, it will not be added again.
  @protected
  @visibleForTesting
  void addLogics(Set<FlowLogic> logics) {
    for (final logic in logics) {
      addLogic(logic);
    }
  }

  /// Initializes the features.
  @visibleForTesting
  void initialize() {
    for (final logic in initializeLogics) {
      logic.initialize();
    }
  }

  /// Tears down the features.
  @visibleForTesting
  void teardown() {
    for (final logic in teardownLogics) {
      logic.teardown();
    }
  }

  /// Cleans up the features.
  @visibleForTesting
  void cleanup() {
    for (final logic in cleanupLogics) {
      logic.cleanup();
    }
  }

  /// Executes the features.
  @visibleForTesting
  void execute(Duration elapsed) {
    for (final logic in executeLogics) {
      if (logic.executesIf) {
        logic.execute(elapsed);
      }
    }
  }

  /// Reacts to an component change.
  @visibleForTesting
  void react(FlowComponent component) {
    final logics = reactiveLogics[component.runtimeType];

    if (logics == null || logics.isEmpty) return;

    for (final logic in logics) {
      if (logic.reactsIf) {
        FlowLogger.log(
          _LogicReacted(
            time: DateTime.now(),
            level: FlowLogLevel.info,
            logic: logic,
            component: component,
            stack: StackTrace.current,
          ),
        );

        logic.react();
      }
    }
  }

  /// Gets an component of type [TComponent] from this feature if it exists.
  TComponent getComponent<TComponent extends FlowComponent>() {
    for (final component in components) {
      if (component is TComponent) {
        return component;
      }
    }

    throw StateError("Component of type $TComponent not found");
  }
}
