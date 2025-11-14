part of '../kinora_flow.dart';

abstract class FlowView extends StatefulWidget {
  const FlowView({super.key});

  @override
  @visibleForTesting
  State<FlowView> createState() {
    return _FlowViewState();
  }

  Widget build(BuildContext context, FlowContext flow);
}

final class _FlowViewState extends State<FlowView> {
  FlowContext? _flow;

  @protected
  FlowContext get ecs {
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
      ecs.initialize();
    });

    super.initState();
  }

  @override
  void dispose() {
    ecs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, ecs);
  }
}

abstract class FlowStatefulView extends StatefulWidget {
  const FlowStatefulView({super.key});

  @override
  ECSState<FlowStatefulView> createState();
}

abstract class ECSState<TWidget extends FlowStatefulView> extends State<TWidget> {
  FlowContext? _ecs;

  @protected
  FlowContext get ecs {
    return _ecs ??= FlowContext(
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
      ecs.initialize();
    });

    super.initState();
  }

  @override
  void dispose() {
    ecs.dispose();
    super.dispose();
  }
}
