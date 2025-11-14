part of '../kinora_flow.dart';

final class FlowScope extends StatefulWidget {
  const FlowScope({
    required this.features,
    required this.child,
    super.key,
    this.useTicker = false,
  });

  final Set<FlowFeature> features;
  final Widget child;
  final bool useTicker;

  @override
  @protected
  State<FlowScope> createState() => _FlowScopeState();

  static FlowManager of(BuildContext context) {
    final scope = context.findAncestorStateOfType<_FlowScopeState>();

    if (scope == null) {
      throw FlutterError("FlowScope not found in context");
    }

    return scope.manager;
  }
}

final class _FlowScopeState extends State<FlowScope>
    with SingleTickerProviderStateMixin {
  late final FlowManager manager;

  Ticker? ticker;
  Duration duration = .zero;

  @override
  void initState() {
    super.initState();

    final parentManager = context
        .findAncestorStateOfType<_FlowScopeState>()
        ?.manager;

    manager = FlowManager(parentManager: parentManager);

    for (final feature in widget.features) {
      manager.addFeature(feature);
    }

    if (widget.useTicker) {
      buildTicker();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.initialize();
      unawaited(ticker?.start());
    });
  }

  void buildTicker() {
    ticker?.stop();

    ticker = createTicker((duration) {
      final elapsed = duration - this.duration;

      this.duration = duration;

      manager
        ..execute(elapsed)
        ..cleanup();
    });
  }

  @override
  void didUpdateWidget(covariant FlowScope oldWidget) {
    if (oldWidget.useTicker != widget.useTicker) {
      if (widget.useTicker) {
        buildTicker();
      } else {
        ticker?.stop();
        ticker = null;
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    ticker?.dispose();
    manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
