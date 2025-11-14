part of '../kinora_flow.dart';

final class FlowBuilder<TComponent extends FlowComponent> extends FlowWidget {
  const FlowBuilder({
    required this.builder,
    super.key,
  });

  final Widget Function(BuildContext context, FlowContext flow) builder;

  @override
  Widget build(BuildContext context, FlowContext flow) {
    return builder(context, flow);
  }
}
