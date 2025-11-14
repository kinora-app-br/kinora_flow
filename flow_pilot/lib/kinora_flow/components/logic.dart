part of '../kinora_flow.dart';

/// Base class for Flow logic.
sealed class FlowLogic {
  FlowLogic();

  /// Set of types that this logic interacts with.
  ///
  /// This set should be overridden in subclasses to specify the types of
  /// components that this logic can interact with.
  ///
  /// This is used to optimize the logic's execution by filtering components
  /// that are relevant to the logic and avoid unnecessary processing.
  ///
  /// This is also used for debugging purposes to understand which components
  /// are being processed by the logic.
  Set<Type> get interactsWith => const {};

  /// The parent feature of this logic.
  @protected
  late FlowFeature _feature;

  /// Sets the parent feature of this logic.
  ///
  /// Throws a [StateError] if the logic is already assigned to a feature.
  void _setFeature(FlowFeature feature) {
    _feature = feature;
  }

  /// The manager that this logic is associated with.
  @protected
  FlowManager get manager => _feature.manager;
}

/// Base class for feature initializion logic.
///
/// Initialize logic are used to perform setup tasks.
///
/// The [initialize] method should be overridden in subclasses to perform
/// the actual initialization logic.
///
/// The [initialize] method is called once after the first frame is rendered and
/// before any other logic are executed.
abstract class FlowFeatureInitializationLogic extends FlowLogic {
  FlowFeatureInitializationLogic();

  /// Initialize logic for the logic.
  @visibleForTesting
  void initialize();
}

/// Base class for cleanup logic.
///
/// Cleanup logic are used to perform cleanup tasks.
///
/// The [cleanup] method should be overridden in subclasses to perform the
/// actual cleanup logic.
///
/// The [cleanup] method is called after all [FlowFrameExecutionLogic]s have been executed
/// and before the next frame is rendered.
abstract class FlowCleanUpLogic extends FlowLogic {
  FlowCleanUpLogic();

  /// Cleanup logic for the logic.
  @protected
  void cleanup();
}

/// Base class for feature disposal logic.
///
/// Teardown logic are used to perform teardown tasks.
///
/// The [teardown] method should be overridden in subclasses to perform the
/// actual teardown logic.
///
/// The [teardown] method is called once after the last frame is rendered and
/// before the application is disposed.
abstract class FlutterFeatureDisposalLogic extends FlowLogic {
  FlutterFeatureDisposalLogic();

  /// Teardown logic for the logic.
  @protected
  void teardown();
}

/// Base class for execute logic.
///
/// Execute logic are used to perform tasks that need to be executed
/// periodically, such as updating the state of components or processing events.
///
/// The [execute] method should be overridden in subclasses to perform the
/// actual execution logic.
///
/// The [execute] method is called every frame.
abstract class FlowFrameExecutionLogic extends FlowLogic {
  FlowFrameExecutionLogic();

  /// Whether the logic should be executed or not.
  ///
  /// This is used to determine whether the logic should be executed on every
  /// frame.
  ///
  /// If this is set to `false`, the logic will not be executed on each frame.
  bool get executesIf => true;

  /// Execute logic for the logic.
  @protected
  void execute(Duration elapsed);
}

/// Base class for reactive logic.
///
/// Reactive logic are used to react to changes in components.
///
/// The [react] method should be overridden in subclasses to perform the
/// actual reaction logic.
abstract class FlowReactiveLogic extends FlowLogic {
  FlowReactiveLogic();

  /// The set of component types that this logic reacts to.
  ///
  /// This set should be overridden in subclasses to specify the types of
  /// components that this logic reacts to.
  ///
  /// This is used to optimize the logic's reaction by filtering components
  /// that are relevant to the logic and avoid unnecessary processing.
  ///
  /// This is also used for debugging purposes to understand which components
  /// are being processed by the logic.
  Set<Type> get reactsTo;

  /// Whether the logic reacts to changes in components.
  ///
  /// This is used to determine whether the logic should be executed
  /// when an component changes.
  ///
  /// If this is set to `false`, the logic will not be executed
  /// when an component changes, even if it is being watched.
  bool get reactsIf => true;

  @protected
  void react();
}
