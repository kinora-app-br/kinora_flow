part of '../kinora_flow.dart';

/// Interface for listening to changes in components.
abstract interface class IFlowComponentListener {
  /// Called when a component changes.
  @protected
  void onComponentChanged(FlowComponent component) {}
}

/// Represents a base component in the Flow architecture.
sealed class FlowComponent {
  FlowComponent();

  /// Set of listeners for this component.
  @visibleForTesting
  final Set<IFlowComponentListener> listeners = {};

  /// The parent feature of this component.
  late FlowFeature _feature;

  /// Sets the parent feature of this component.
  ///
  /// Throws a [StateError] if the parent is already set.
  void _setFeature(FlowFeature feature) {
    _feature = feature;
  }

  /// Adds a listener to this component.
  @visibleForTesting
  void addListener(IFlowComponentListener listener) {
    listeners.add(listener);
  }

  /// Removes a listener from this component.
  @visibleForTesting
  void removeListener(IFlowComponentListener listener) {
    listeners.remove(listener);
  }

  @protected
  void notifyListeners() {
    for (final listener in listeners) {
      listener.onComponentChanged(this);
    }
  }
}

/// Represents an event in the Flow architecture.
///
/// Events are specialized components that can be triggered to notify listeners.
abstract class FlowEvent extends FlowComponent {
  FlowEvent();

  /// Triggers the event, notifying all listeners.
  void trigger() {
    notifyListeners();
  }

  /// Builds a widget that represents this component in the [FlowInspector].
  ///
  /// [context] is the build context in which the widget is built.
  Widget buildInspector(BuildContext context) {
    return ElevatedButton(
      onPressed: trigger,
      child: const Text("Trigger Event"),
    );
  }
}

/// Represents a state in the Flow architecture.
///
/// States are specialized components that hold data and can be updated  and
/// will notify listeners when their value changes.
abstract class FlowState<TValue> extends FlowComponent {
  FlowState(TValue value) : _value = value;

  /// The current value of the component.
  TValue _value;

  /// The previous value of the component.
  TValue? _previous;

  /// The current value of the component.
  TValue get value => _value;

  /// The previous value of the component, or null if never set.
  TValue? get previous => _previous;

  /// Updates the component's value.
  ///
  /// If [notify] is `true`, listeners will be notified of the change. Default
  /// is `true`.
  ///
  /// If the [value] is equal to the current value, no change will be made
  /// unless [force] is `true`, then update will be applied anyways. Defaults is
  /// `false`.
  void update(TValue value, {bool notify = true, bool force = false}) {
    if (force == false) {
      if (_value == value) {
        return;
      }
    }

    _previous = _value;
    _value = value;

    if (notify) {
      notifyListeners();
    }
  }

  /// Fast setter for updating the component's value.
  ///
  /// This is equivalent to calling [update] with default parameters.
  set value(TValue value) {
    update(value);
  }

  /// Builds a string descriptor for the component's value in [FlowInspector].
  ///
  /// If the [value] is null, "null" will be returned.
  String buildDescriptor(TValue? value) {
    return value.toString();
  }

  /// Builds a widget that represents this component in the [FlowInspector].
  ///
  /// [context] is the build context in which the widget is built.
  Widget buildInspector(BuildContext context, TValue? value) {
    return Text(buildDescriptor(value));
  }
}
