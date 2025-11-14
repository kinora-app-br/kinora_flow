import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:kinora_flow_pilot/kinora_flow/kinora_flow.dart';

class CounterState extends FlowState<int> {
  CounterState([super.value = 0]);
}

class MessageState extends FlowState<String> {
  MessageState([super.value = "initial"]);
}

class TestFeature extends FlowFeature {
  TestFeature();
}

class WatchingTestWidget extends FlowView {
  const WatchingTestWidget({super.key});

  @override
  Widget build(BuildContext context, FlowContext flowContext) {
    final counter = flowContext.watch<CounterState>();

    return Text("Counter: ${counter.value}");
  }
}

class ListeningTestWidget extends FlowView {
  const ListeningTestWidget({
    required this.onCounterChanged,
    super.key,
  });

  final void Function(CounterState) onCounterChanged;

  @override
  Widget build(BuildContext context, FlowContext flowContext) {
    flowContext.listen<CounterState>(onCounterChanged);

    return const Text("Listening Widget");
  }
}

class BuildCounterWidget extends FlowView {
  const BuildCounterWidget({
    required this.onBuild,
    super.key,
  });

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context, FlowContext flowContext) {
    onBuild();

    final counter = flowContext.watch<CounterState>();

    return Text("Counter: ${counter.value}");
  }
}

class LifecycleTestWidget extends FlowView {
  const LifecycleTestWidget({
    super.key,
    this.onEnter,
    this.onExit,
  });

  final VoidCallback? onEnter;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context, FlowContext flowContext) {
    if (onEnter != null) {
      flowContext.onEnter(onEnter!);
    }

    if (onExit != null) {
      flowContext.onExit(onExit!);
    }

    return const Text("Lifecycle Widget");
  }
}

class MultipleComponentsTestWidget extends FlowView {
  const MultipleComponentsTestWidget({super.key});

  @override
  Widget build(BuildContext context, FlowContext flowContext) {
    final counter = flowContext.watch<CounterState>();
    final message = flowContext.watch<MessageState>();

    return Column(
      children: [
        Text("Counter: ${counter.value}"),
        Text("Message: ${message.value}"),
      ],
    );
  }
}

void main() {
  group("FlowView", () {
    testWidgets("should watch component changes and rebuild", (tester) async {
      final component = CounterState();
      final feature = TestFeature()..addComponent(component);

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: const WatchingTestWidget(),
          ),
        ),
      );

      expect(find.text("Counter: 0"), findsOneWidget);

      component.update(5);
      await tester.pump();

      expect(find.text("Counter: 5"), findsOneWidget);
      expect(find.text("Counter: 0"), findsNothing);
    });

    testWidgets("should handle multiple component watches", (tester) async {
      final counterComponent = CounterState();
      final messageComponent = MessageState();

      final feature = TestFeature()
        ..addComponents({counterComponent, messageComponent});

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: const MultipleComponentsTestWidget(),
          ),
        ),
      );

      // Initial state
      expect(find.text("Counter: 0"), findsOneWidget);
      expect(find.text("Message: initial"), findsOneWidget);

      // Change counter
      counterComponent.update(10);
      await tester.pump();

      expect(find.text("Counter: 10"), findsOneWidget);
      expect(find.text("Message: initial"), findsOneWidget);

      // Change message (should not trigger rebuild since it"s not watched)
      messageComponent.update("updated");
      await tester.pump();

      expect(find.text("Counter: 10"), findsOneWidget);
      expect(find.text("Message: updated"), findsOneWidget);
    });

    testWidgets("should call component listeners", (tester) async {
      final counterComponent = CounterState();
      final feature = TestFeature()..addComponent(counterComponent);

      CounterState? listenerCallbackComponent;

      var listenerCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: ListeningTestWidget(
              onCounterChanged: (component) {
                listenerCallbackComponent = component;
                listenerCallCount++;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Change the counter value
      counterComponent.update(7);
      await tester.pump();

      // Wait for microtask to complete
      await tester.pump(Duration.zero);

      expect(listenerCallCount, equals(1));
      expect(listenerCallbackComponent, equals(counterComponent));
    });

    testWidgets("should call onEnter lifecycle callback", (tester) async {
      var onEnterCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {TestFeature()},
            child: LifecycleTestWidget(
              onEnter: () => onEnterCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Wait for postFrameCallback to execute
      await tester.pump(Duration.zero);

      expect(onEnterCalled, isTrue);
    });

    testWidgets("should call onExit lifecycle callback when disposed", (
      tester,
    ) async {
      var onExitCalled = false;
      var showWidget = true;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {TestFeature()},
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showWidget)
                      LifecycleTestWidget(
                        onExit: () => onExitCalled = true,
                      ),
                    ElevatedButton(
                      onPressed: () => setState(() => showWidget = false),
                      child: const Text("Remove Widget"),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Remove the widget
      await tester.tap(find.text("Remove Widget"));
      await tester.pump();

      // Wait for microtask to complete
      await tester.pump(Duration.zero);

      expect(onExitCalled, isTrue);
    });

    testWidgets("should not call onEnter multiple times", (tester) async {
      var onEnterCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {TestFeature()},
            child: LifecycleTestWidget(
              onEnter: () => onEnterCallCount++,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Trigger a rebuild
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(onEnterCallCount, equals(1));
    });

    testWidgets("should not call onExit multiple times", (tester) async {
      var onExitCallCount = 0;
      var showWidget = true;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {TestFeature()},
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showWidget)
                      LifecycleTestWidget(
                        onExit: () => onExitCallCount++,
                      ),
                    ElevatedButton(
                      onPressed: () => setState(() => showWidget = false),
                      child: const Text("Remove Widget"),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Remove the widget
      await tester.tap(find.text("Remove Widget"));
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(onExitCallCount, equals(1));
    });

    testWidgets("should handle rapid component changes without excessive rebuilds", (
      tester,
    ) async {
      final counterComponent = CounterState();
      final feature = TestFeature()..addComponent(counterComponent);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: BuildCounterWidget(
              onBuild: () => buildCount++,
            ),
          ),
        ),
      );

      await tester.pump();
      final initialBuildCount = buildCount;

      // Make rapid changes
      counterComponent
        ..update(1)
        ..update(2)
        ..update(3);

      await tester.pump();

      // Should only rebuild once due to locking mechanism
      expect(buildCount, equals(initialBuildCount + 1));
    });

    testWidgets("should properly clean up watchers and listeners on dispose", (
      tester,
    ) async {
      final counterComponent = CounterState();
      final feature = TestFeature()..addComponent(counterComponent);
      var showWidget = true;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showWidget) const WatchingTestWidget(),
                    ElevatedButton(
                      onPressed: () => setState(() => showWidget = false),
                      child: const Text("Remove Widget"),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify widget is watching
      expect(find.text("Counter: 0"), findsOneWidget);

      // Remove the widget
      await tester.tap(find.text("Remove Widget"));
      await tester.pump();

      // Change component after widget disposal - should not cause any issues
      counterComponent.update(99);
      await tester.pump();

      // Widget should be gone and no errors should occur
      expect(find.text("Counter: 0"), findsNothing);
      expect(find.text("Counter: 99"), findsNothing);
    });

    testWidgets("should maintain reference across rebuilds", (tester) async {
      final counterComponent = CounterState();
      final feature = TestFeature()..addComponent(counterComponent);
      var triggerRebuild = false;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    const WatchingTestWidget(),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => triggerRebuild = !triggerRebuild),
                      child: Text("Rebuild $triggerRebuild"),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Initial state
      expect(find.text("Counter: 0"), findsOneWidget);

      // Change counter
      counterComponent.update(5);
      await tester.pump();
      expect(find.text("Counter: 5"), findsOneWidget);

      // Trigger parent rebuild
      await tester.tap(find.text("Rebuild false"));
      await tester.pump();

      // Should still show correct value
      expect(find.text("Counter: 5"), findsOneWidget);

      // Change counter again after rebuild
      counterComponent.update(10);
      await tester.pump();
      expect(find.text("Counter: 10"), findsOneWidget);
    });
  });
}
