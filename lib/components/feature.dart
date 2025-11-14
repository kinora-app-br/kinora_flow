part of '../kinora_flow.dart';

/// FlowFeature is a base class for creating features in the Flow architecture.
///
/// Features can contain components and logic, and they provide a way to organize
/// and manage different parts of the Flow architecture.
abstract class FlowFeature {
  FlowFeature();

  /// Set of components in this feature.
  @visibleForTesting
  final Set<FlowComponent> components = {};

  /// Set of initialize logic in this feature.
  @visibleForTesting
  final Set<FlowFeatureInitializationLogic> initializeLogics = {};

  /// Set of disposal logic in this feature.
  @visibleForTesting
  final Set<FlutterFeatureDisposalLogic> disposalLogics = {};

  /// Set of cleanup logic in this feature.
  @visibleForTesting
  final Set<FlowCleanUpLogic> cleanupLogics = {};

  /// Set of execute logic in this feature.
  @visibleForTesting
  final Set<FlowFrameExecutionLogic> executeLogics = {};

  /// Map of reactive logic by component type.
  @visibleForTesting
  final Map<Type, Set<FlowReactiveLogic>> reactiveLogics = {};

  /// The manager that this feature is associated with.
  @protected
  @visibleForTesting
  late FlowManager manager;

  /// Number of logic in this feature.
  @visibleForTesting
  int get logicCount {
    return initializeLogics.length +
        disposalLogics.length +
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
  /// This method is protected and should be used by subclasses to add logic.
  /// If the logic is already added, it will not be added again.
  @protected
  @visibleForTesting
  void addLogic(FlowLogic logic) {
    switch (logic) {
      case FlowFeatureInitializationLogic():
        initializeLogics.add(logic);
      case FlutterFeatureDisposalLogic():
        disposalLogics.add(logic);
      case FlowCleanUpLogic():
        cleanupLogics.add(logic);
      case FlowFrameExecutionLogic():
        executeLogics.add(logic);
      case FlowReactiveLogic():
        for (final component in logic.reactsTo) {
          reactiveLogics.putIfAbsent(component, () => {}).add(logic);
        }
    }

    logic._setFeature(this);
  }

  /// Adds logic to this feature.
  ///
  /// This method is protected and should be used by subclasses to add logic.
  /// If the logic is already added, it will not be added again.
  @protected
  @visibleForTesting
  void addLogics(Set<FlowLogic> logic) {
    for (final logic in logic) {
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
  void dispose() {
    for (final logic in disposalLogics) {
      logic.dispose();
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
    final logic = reactiveLogics[component.runtimeType];

    if (logic == null || logic.isEmpty) return;

    for (final logic in logic) {
      if (logic.reactsIf) {
        FlowLogger.log(
          _LogicReacted(
            time: .now(),
            level: .info,
            logic: logic,
            component: component,
            stack: .current,
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
