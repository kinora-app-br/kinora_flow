part of '../kinora_flow.dart';

/// FlowFeature is a base class for creating features in the Flow architecture.
final class FlowManager implements IFlowComponentListener {
  FlowManager({FlowManager? parentManager}) : _parentManager = parentManager;

  final FlowManager? _parentManager; // Reference to the parent manager

  /// Set of features in the Flow manager.
  @visibleForTesting
  final Set<FlowFeature> features = {};

  /// Map of event logics by event type.
  final Map<Type, Set<FlowEventLogic<dynamic>>> _eventLogics = {};

  /// Unmodifiable set of all components across all features.
  Set<FlowComponent> get components {
    final expanded = features.expand((feature) => feature.components);

    return Set.unmodifiable(expanded);
  }

  /// Add a feature to the Flow manager.
  @visibleForTesting
  void addFeature(FlowFeature feature) {
    feature._setManager(this);
    features.add(feature);

    for (final component in feature.components) {
      component.addListener(this);
    }
  }

  /// Add features to the Flow manager.
  @visibleForTesting
  void addFeatures(Set<FlowFeature> features) {
    for (final feature in features) {
      addFeature(feature);
    }
  }

  /// Dispatch an event to all registered event logics.
  ///
  /// The event will be delivered to all [FlowEventLogic] instances
  /// that are registered to handle events of this type.
  void dispatch<T>(T event) {
    final logics = _eventLogics[event.runtimeType];

    if (logics == null || logics.isEmpty) return;

    for (final logic in logics) {
      if (logic.reactsIf(event)) {
        logic.react(event);
      }
    }
  }

  /// Initialize all features in the Flow manager.
  @visibleForTesting
  void initialize() {
    for (final feature in features) {
      feature.initialize();
    }
  }

  /// Dispose all features in the Flow manager.
  @visibleForTesting
  void dispose() {
    for (final feature in features) {
      feature.dispose();
    }
  }

  /// Execute all features in the Flow manager.
  @visibleForTesting
  void execute(Duration duration) {
    for (final feature in features) {
      feature.execute(duration);
    }
  }

  /// Cleanup all features in the Flow manager.
  @visibleForTesting
  void cleanup() {
    for (final feature in features) {
      feature.cleanup();
    }
  }

  @override
  @protected
  @visibleForTesting
  void onComponentChanged(FlowComponent component) {
    FlowLogger.log(
      _ComponentChanged(
        level: .verbose,
        component: component,
        logName: "ComponentChanged<${component.runtimeType}>",
      ),
    );

    for (final feature in features) {
      feature.react(component);
    }
  }

  /// Gets an component of type [TComponent] from all features.
  ///
  /// Returns null if the component is not found.
  TComponent? getComponentOrNull<TComponent extends FlowComponent>() {
    for (final feature in features) {
      final component = feature.getComponentOrNull<TComponent>();

      if (component != null) return component;
    }

    if (_parentManager != null) {
      final parentComponent = _parentManager.getComponentOrNull<TComponent>();

      if (parentComponent != null) return parentComponent;
    }

    return null;
  }

  /// Gets an component of type [TComponent] from all features.
  ///
  /// Throws a [StateError] if the component is not found.
  TComponent getComponent<TComponent extends FlowComponent>() {
    final component = getComponentOrNull<TComponent>();

    if (component != null) return component;
    throw StateError("Component of type $TComponent not found");
  }
}
