import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:kinora_flow_pilot/kinora_flow/kinora_flow.dart';

// Test components
class TestCounterState extends FlowState<int> {
  TestCounterState([super.value = 0]);
}

class TestStringState extends FlowState<String> {
  TestStringState([super.value = "initial"]);
}

class TestToggleEvent extends FlowEvent {
  TestToggleEvent();
}

class TestIncrementEvent extends FlowEvent {
  TestIncrementEvent();
}

// Test feature
class TestFeature extends FlowFeature {
  TestFeature() {
    addComponents({
      TestCounterState(),
      TestStringState(),
      TestToggleEvent(),
      TestIncrementEvent(),
    });
  }
}

// Test widget that uses FlowReference
class TestView extends FlowView {
  const TestView({
    super.key,
    this.onBuild,
    this.customBuilder,
  });
  final void Function(FlowContext flowContext)? onBuild;
  final Widget Function(BuildContext, FlowContext)? customBuilder;

  @override
  Widget build(BuildContext context, FlowContext flow) {
    onBuild?.call(flow);

    if (customBuilder != null) {
      return customBuilder!(context, flow);
    }

    final counter = flow.watch<TestCounterState>();
    final stringComponent = flow.get<TestStringState>();

    return Column(
      children: [
        Text("Counter: ${counter.value}"),
        Text("String: ${stringComponent.value}"),
      ],
    );
  }
}

void main() {
  group("FlowReference Tests", () {
    late FlowManager manager;
    late TestFeature feature;
    late FlowContext reference;
    var rebuildCount = 0;

    setUp(() {
      rebuildCount = 0;
      manager = FlowManager();
      feature = TestFeature();
      manager.addFeature(feature);

      reference = FlowContext(manager, () {
        rebuildCount++;
      });
    });

    tearDown(() {
      reference.dispose();
    });

    test("should get components from manager", () {
      final counter = reference.get<TestCounterState>();
      final stringComponent = reference.get<TestStringState>();

      expect(counter, isA<TestCounterState>());
      expect(counter.value, equals(0));
      expect(stringComponent, isA<TestStringState>());
      expect(stringComponent.value, equals("initial"));
    });

    test("should watch components and trigger rebuilds on change", () async {
      final counter = reference.watch<TestCounterState>();

      expect(rebuildCount, equals(0));

      // Change the watched component
      counter.update(5);

      // Wait for microtask to complete
      await Future.microtask(() {});

      expect(rebuildCount, equals(1));
    });

    test("should not trigger rebuild when locked", () async {
      final counter = reference.watch<TestCounterState>();

      // Simulate locked state
      reference.locked = true;

      counter.update(10);
      await Future.microtask(() {});

      expect(rebuildCount, equals(0));
    });

    test("should handle multiple watchers correctly", () async {
      final counter = reference.watch<TestCounterState>();
      final stringComponent = reference.watch<TestStringState>();

      expect(rebuildCount, equals(0));

      // Change first watched component
      counter.update(3);
      await Future.microtask(() {});
      expect(rebuildCount, equals(1));

      // Change second watched component
      stringComponent.update("changed");
      await Future.microtask(() {});
      expect(rebuildCount, equals(2));
    });

    test("should call listeners when component changes", () async {
      var listenerCalled = false;

      TestCounterState? receivedComponent;

      reference.listen<TestCounterState>((component) {
        listenerCalled = true;
        receivedComponent = component;
      });

      final counter = reference.get<TestCounterState>()..update(7);

      await Future.microtask(() {});

      expect(listenerCalled, isTrue);
      expect(receivedComponent, equals(counter));
      expect(receivedComponent!.value, equals(7));
    });

    test("should call onEnter callback when initialized", () async {
      var onEnterCalled = false;

      reference
        ..onEnter(() {
          onEnterCalled = true;
        })
        ..initialize();

      await Future.microtask(() {});

      expect(onEnterCalled, isTrue);
    });

    test("should call onExit callback when disposed", () async {
      var onExitCalled = false;

      reference
        ..onExit(() {
          onExitCalled = true;
        })
        ..dispose();

      await Future.microtask(() {});
      expect(onExitCalled, isTrue);
    });

    test("should only set onEnter callback once", () {
      reference
        ..onEnter(() {
          // First callback
        })
        ..onEnter(() {
          // Second callback should be ignored
        });

      expect(reference.onEnterListener, isNotNull);
      // Second callback should be ignored - the listener should not change
    });

    test("should clean up listeners on dispose", () async {
      final counter = reference.watch<TestCounterState>();

      // Verify listener is added
      expect(counter.listeners.length, equals(2));

      reference.dispose();

      // Verify listener is removed
      expect(counter.listeners.length, equals(1));
    });

    test("should handle disposed state correctly", () {
      reference.dispose();

      expect(reference.disposed, isTrue);
    });
  });

  group("View Integration Tests", () {
    testWidgets("should build with FlowReference", (WidgetTester tester) async {
      final feature = TestFeature();
      FlowContext? capturedReference;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: TestView(
              onBuild: (reference) {
                capturedReference = reference;
              },
            ),
          ),
        ),
      );

      expect(capturedReference, isNotNull);
      expect(capturedReference!.manager, isA<FlowManager>());
      expect(find.text("Counter: 0"), findsOneWidget);
      expect(find.text("String: initial"), findsOneWidget);
    });

    testWidgets("should rebuild when watched component changes", (
      WidgetTester tester,
    ) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: const TestView(),
          ),
        ),
      );

      // Verify initial state
      expect(find.text("Counter: 0"), findsOneWidget);

      // Change the counter value
      feature.getComponent<TestCounterState>().update(42);

      await tester.pump();

      // Verify the widget rebuilt with new value
      expect(find.text("Counter: 42"), findsOneWidget);
      expect(find.text("Counter: 0"), findsNothing);
    });

    testWidgets("should handle onEnter and onExit lifecycle", (
      WidgetTester tester,
    ) async {
      final feature = TestFeature();
      var onEnterCalled = false;
      var onExitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: TestView(
              customBuilder: (context, reference) {
                reference
                  ..onEnter(() {
                    onEnterCalled = true;
                  })
                  ..onExit(() {
                    onExitCalled = true;
                  });

                return const Text("Test");
              },
            ),
          ),
        ),
      );

      // Wait for post-frame callback
      await tester.pump();

      expect(onEnterCalled, isTrue);
      expect(onExitCalled, isFalse);

      // Remove the widget to trigger onExit
      await tester.pumpWidget(
        const MaterialApp(
          home: Text("Different Widget"),
        ),
      );

      await tester.pumpAndSettle();

      expect(onExitCalled, isTrue);
    });

    testWidgets("should handle listen callbacks", (WidgetTester tester) async {
      final feature = TestFeature();
      var listenerCallCount = 0;

      TestCounterState? receivedComponent;

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: TestView(
              customBuilder: (context, reference) {
                reference.listen<TestCounterState>((component) {
                  listenerCallCount++;
                  receivedComponent = component;
                });

                final counter = reference.watch<TestCounterState>();
                return Text("Counter: ${counter.value}");
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(listenerCallCount, equals(0));

      // Change the counter
      final counter = feature.getComponent<TestCounterState>()..update(25);

      await tester.pump();

      expect(listenerCallCount, equals(1));
      expect(receivedComponent, equals(counter));
      expect(receivedComponent!.value, equals(25));
    });

    testWidgets("should not rebuild after disposal", (WidgetTester tester) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: const TestView(),
          ),
        ),
      );

      // Get reference to counter before disposal
      final counter = feature.getComponent<TestCounterState>();

      // Remove the widget (this should dispose the reference)
      await tester.pumpWidget(
        const MaterialApp(
          home: Text("Different Widget"),
        ),
      );

      await tester.pumpAndSettle();

      // Try to change the counter after disposal
      counter.update(99);

      // Pump again to see if any rebuilds happen (they shouldn"t)
      await tester.pump();

      // Verify the old widget is gone
      expect(find.text("Counter: 99"), findsNothing);
    });

    testWidgets("should handle multiple Views independently", (
      WidgetTester tester,
    ) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: FlowScope(
            features: {feature},
            child: const Column(
              children: [
                TestView(
                  key: Key("widget1"),
                ),
                TestView(
                  key: Key("widget2"),
                ),
              ],
            ),
          ),
        ),
      );

      // Both widgets should show the same initial value
      expect(find.text("Counter: 0"), findsNWidgets(2));

      // Change the counter
      feature.getComponent<TestCounterState>().update(15);

      await tester.pump();

      // Both widgets should update
      expect(find.text("Counter: 15"), findsNWidgets(2));
      expect(find.text("Counter: 0"), findsNothing);
    });
  });

  group("Edge Cases and Error Handling", () {
    test("should handle rapid component changes", () async {
      final manager = FlowManager();
      final feature = TestFeature();
      manager.addFeature(feature);

      var rebuildCount = 0;
      final reference = FlowContext(manager, () {
        rebuildCount++;
      });

      reference.watch<TestCounterState>()
        // Rapid changes
        ..update(1)
        ..update(2)
        ..update(3)
        ..update(4)
        ..update(5);

      await Future.microtask(() {});

      // Should still only rebuild once due to microtask batching
      expect(rebuildCount, equals(1));

      reference.dispose();
    });

    test(
      "should prevent multiple builds when previous build is not completed",
      () async {
        final manager = FlowManager();
        final feature = TestFeature();
        manager.addFeature(feature);

        var rebuildCount = 0;

        final reference = FlowContext(manager, () {
          rebuildCount++;
        });

        reference.watch<TestCounterState>()
          // Trigger first build
          ..update(1)
          // Immediately trigger more changes while first build is in progress
          ..update(2)
          ..update(3)
          ..update(4);

        // Verify reference is locked during build
        expect(reference.locked, isTrue);

        await Future.microtask(() {});

        // Should only rebuild once despite multiple changes
        expect(rebuildCount, equals(1));

        // After microtask, reference should be unlocked
        expect(reference.locked, isFalse);

        reference.dispose();
      },
    );

    test("should handle watching same component multiple times", () {
      final manager = FlowManager();
      final feature = TestFeature();

      manager.addFeature(feature);

      final reference = FlowContext(manager, () {});
      final counter1 = reference.watch<TestCounterState>();
      final counter2 = reference.watch<TestCounterState>();

      expect(counter1, equals(counter2));
      expect(reference.watchers.length, equals(1));

      reference.dispose();
    });
  });
}
