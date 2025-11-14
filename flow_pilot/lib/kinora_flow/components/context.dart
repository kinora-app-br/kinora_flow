part of '../kinora_flow.dart';

/// Context for accessing logic from widgets.
final class FlowContext implements IFlowComponentListener {
  @visibleForTesting
  FlowContext(this.manager, void Function() callback) : _callback = callback;

  /// The manager instance.
  @visibleForTesting
  final FlowManager manager;

  /// Callback for notifying changes in the context.
  final void Function() _callback;

  /// Map of component listeners.
  final Map<FlowComponent, void Function()> _listeners = {};

  /// Set of components being watched.
  @visibleForTesting
  final Set<FlowComponent> watchers = {};

  /// Optional listeners for enter event.
  @visibleForTesting
  void Function()? onEnterListener;

  /// Optional listeners for exit event.
  @visibleForTesting
  void Function()? onExitListener;

  var _disposed = false;

  /// Indicates if the context has been disposed.
  bool get disposed => _disposed;

  var _locked = false;

  /// Indicates if the context is currently locked for rebuilding.
  bool get locked => _locked;

  @visibleForTesting
  set locked(bool value) => _locked = value;

  /// Set of commonly accessed components by the Flow context.
  final Set<FlowComponent> _components = {};

  /// Retrieves an component of type [TComponent] from the Flow context.
  ///
  /// This function will search the components set first.
  /// If the component is not found, it will be fetched from the Flow manager and added
  /// to the components set. Otherwise, it will return the existing component from the set.
  TComponent _getComponent<TComponent extends FlowComponent>() {
    for (final component in _components) {
      if (component is TComponent) return component;
    }

    final component = manager.getComponent<TComponent>();

    _components.add(component);

    return component;
  }

  /// Gets an component of type [TComponent] from the Flow manager.
  TComponent get<TComponent extends FlowComponent>() {
    return _getComponent<TComponent>();
  }

  /// Watches an component of type [TComponent] for changes.
  TComponent watch<TComponent extends FlowComponent>() {
    final component = _getComponent<TComponent>();

    if (watchers.add(component)) component.addListener(this);

    return component;
  }

  /// Listens to changes in an component of type [TComponent].
  ///
  /// The listener will be called whenever the component changes.
  /// If the component is already being watched, it will be overridden.
  /// Callbacks are executed asynchronously and safe to use in the widget tree.
  void listen<TComponent extends FlowComponent>(
    void Function(TComponent component) listener,
  ) {
    final component = _getComponent<TComponent>();

    if (_listeners.containsKey(component) == false) component.addListener(this);

    _listeners[component] = () => listener(component);
  }

  /// Initializes the Flow context.
  @visibleForTesting
  void initialize() {
    unawaited(
      Future.microtask(() {
        onEnterListener?.call();
        onEnterListener = null;
      }),
    );
  }

  /// Disposes the Flow context.
  @visibleForTesting
  void dispose() {
    _disposed = true;
    _components.clear();

    for (final component in watchers) {
      component.removeListener(this);
    }

    watchers.clear();

    for (final component in _listeners.keys) {
      component.removeListener(this);
    }

    _listeners.clear();

    unawaited(
      Future.microtask(() {
        onExitListener?.call();
        onExitListener = null;
      }),
    );
  }

  /// Rebuilds the Flow context.
  ///
  /// This method is used to trigger a rebuild of the context.
  /// If the context is locked, it will not rebuild until the lock is released.
  void _rebuild() {
    if (_locked) return;
    _locked = true;
    _callback();
    unawaited(Future.microtask(() => _locked = false));
  }

  /// Callback for when entring the Flow context.
  void onEnter(void Function() function) {
    if (onEnterListener != null) return;
    onEnterListener = function;
  }

  /// Callback for when exiting the Flow context.
  void onExit(void Function() function) {
    if (onExitListener != null) return;
    onExitListener = function;
  }

  @override
  @visibleForTesting
  void onComponentChanged(FlowComponent component) {
    if (watchers.contains(component)) _rebuild();

    final listener = _listeners[component];

    if (listener != null) unawaited(Future.microtask(listener));
  }
}
