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

  /// Logs a custom log entry.
  static void log(FlowLog log) {
    while (_entries.length >= maxEntries) {
      _entries.removeAt(0);
    }

    _entries.add(log);
  }

  /// Easy way to log debug messages.
  ///
  /// This method only logs messages in debug mode.
  static void debugPrint(String message) {
    if (kDebugMode == false) return;

    log(
      DebugMessage(
        time: DateTime.now(),
        level: FlowLogLevel.debug,
        message: message,
        stack: StackTrace.current,
      ),
    );
  }

  /// Clears all log entries.
  static void clear() {
    _entries.clear();
  }
}

/// Base class for Flow log entries.
abstract class FlowLog {
  const FlowLog({
    required this.time,
    required this.level,
    required this.stack,
  });

  /// The time when the log entry was created.
  final DateTime time;

  /// The log level of the entry.
  final FlowLogLevel level;

  /// The stack trace at the time of logging.
  final StackTrace stack;

  /// Human-readable description of the log entry.
  String get description;
}

/// Represents the log levels for Flow logging.
enum FlowLogLevel {
  /// Informational log level.
  info,

  /// Warning log level.
  warning,

  /// Error log level.
  error,

  /// Debug log level.
  debug,

  /// Verbose log level.
  verbose,

  /// Fatal log level.
  fatal,
}

/// Represents an component change event in the Flow logic.
final class _ComponentChanged<TComponent extends FlowComponent> extends FlowLog {
  const _ComponentChanged({
    required super.time,
    required super.level,
    required this.component,
    required super.stack,
  });

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
  const _LogicReacted({
    required super.time,
    required super.level,
    required this.logic,
    required this.component,
    required super.stack,
  });

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

final class DebugMessage extends FlowLog {
  const DebugMessage({
    required super.time,
    required super.level,
    required this.message,
    required super.stack,
  });

  /// The debug message.
  final String message;

  @override
  String get description => message;
}
