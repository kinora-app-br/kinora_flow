part of '../kinora_flow.dart';

final class FlowLogger {
  FlowLogger._();

  static final List<FlowLog> _entries = [];

  /// Maximum number of log entries to keep.
  ///
  /// This can be adjusted based on the application"s needs.
  /// Default is set to 1000 entries.
  /// if the number of entries exceeds this limit, the oldest entries will be
  /// removed.
  static const maxEntries = 1000;

  /// Unmodifiable list of log entries.
  static List<FlowLog> get entries => List.unmodifiable(_entries);

  static final _logStreamController = StreamController<FlowLog>.broadcast();

  /// Stream for each [FlowLog] entry logged.
  static final Stream<FlowLog> onLog = _logStreamController.stream;

  /// Logs a custom log entry.
  static void log(FlowLog log) {
    while (_entries.length >= maxEntries) {
      _entries.removeAt(0);
    }

    _entries.add(log);
    _logStreamController.add(log);
  }

  /// Easy way to log debug messages.
  ///
  /// This method only logs messages in debug mode.
  static void debugPrint(String message, {String logName = "Debug"}) {
    if (kDebugMode == false) return;
    log(LogMessage(message, level: .debug, stack: .current, logName: logName));
  }

  /// Clears all log entries.
  static void clear() {
    _entries.clear();
  }
}

/// Base class for Flow log entries.
abstract class FlowLog {
  FlowLog({
    required this.logName,
    required this.level,
    this.stack,
  }) : time = .now();

  /// The name of the log entry.
  final String logName;

  /// The time the log entry was created.
  final DateTime time;

  /// The log level of the entry.
  final FlowLogLevel level;

  /// The stack trace at the time of logging.
  final StackTrace? stack;

  /// Human-readable description of the log entry.
  String get description;
}

/// Represents the log levels for Flow logging.
enum FlowLogLevel {
  /// Debug log level.
  debug,

  /// Verbose log level.
  verbose,

  /// Informational log level.
  info,

  /// Warning log level.
  warning,

  /// Error log level.
  error,

  /// Fatal log level.
  fatal,
}

/// Represents an component change event in the Flow logic.
final class _ComponentChanged<TComponent extends FlowComponent> extends FlowLog {
  _ComponentChanged({required super.level, required this.component})
    : super(logName: "ComponentChanged<$TComponent>");

  /// The component that changed.
  final TComponent component;

  @override
  String get description {
    final buffer = StringBuffer(
      "[${component._feature.runtimeType}.${component.runtimeType}] ",
    );

    final state = component as FlowState;
    final previous = state.buildDescriptor(state.previous);
    final current = state.buildDescriptor(state.value);

    buffer
      ..write("updated ")
      ..write("from $previous ")
      ..write("to $current");

    return buffer.toString();
  }
}

/// Represents a logic reacting to an component change.
final class _LogicReacted<
  TLogic extends FlowReactiveLogic,
  TEvent extends FlowComponent
>
    extends FlowLog {
  _LogicReacted({
    required super.level,
    required this.logic,
    required this.component,
  }) : super(logName: "LogicReacted<$TLogic, $TEvent>");

  /// The logic that reacted to the component change.
  final TLogic logic;

  /// The component that triggered the reaction.
  final TEvent component;

  @override
  String get description {
    final buffer = StringBuffer(
      "[${logic._feature.runtimeType}.${logic.runtimeType}] "
      "reacted to "
      "[${component._feature.runtimeType}.${component.runtimeType}] ",
    );

    final state = component as FlowState;
    final previous = state.buildDescriptor(state.previous);
    final current = state.buildDescriptor(state.value);

    buffer
      ..write("update ")
      ..write("from $previous ")
      ..write("to $current");

    return buffer.toString();
  }
}

final class LogMessage extends FlowLog {
  LogMessage(
    this.description, {
    required super.logName,
    required super.level,
    super.stack,
  });

  @override
  final String description;
}
