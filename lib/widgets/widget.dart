part of '../kinora_flow.dart';

abstract class FlowWidget extends StatefulWidget {
  const FlowWidget({super.key});

  @override
  @visibleForTesting
  State<FlowWidget> createState() {
    return _FlowWidgetState();
  }

  Widget build(BuildContext context, FlowContext flow);
}

final class _FlowWidgetState extends State<FlowWidget> {
  FlowContext? _flow;

  @protected
  FlowContext get flow {
    return _flow ??= FlowContext(
      FlowScope.of(context),
      () {
        if (mounted == false) return;
        setState(() {});
      },
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flow.initialize();
    });

    super.initState();
  }

  @override
  void dispose() {
    flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, flow);
  }
}

abstract class FlowStatefulWidget extends StatefulWidget {
  const FlowStatefulWidget({super.key});

  @override
  FlowStatefulWidgetState<FlowStatefulWidget> createState();
}

abstract class FlowStatefulWidgetState<TWidget extends FlowStatefulWidget>
    extends State<TWidget> {
  FlowContext? _flow;

  @protected
  FlowContext get flow {
    return _flow ??= FlowContext(
      FlowScope.of(context),
      () {
        if (mounted == false) return;
        setState(() {});
      },
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flow.initialize();
    });

    super.initState();
  }

  @override
  void dispose() {
    flow.dispose();
    super.dispose();
  }
}
