import 'package:flutter_test/flutter_test.dart';

import 'package:kinora_flow/kinora_flow.dart';

// Test Event
class ScopedEvent {
  const ScopedEvent(this.id);
  final String id;
}

// Test Logic
class ScopedEventLogic extends FlowEventLogic<ScopedEvent> {
  final List<String> receivedIds = [];

  @override
  void react(ScopedEvent event) {
    receivedIds.add(event.id);
  }
}

// Test Feature
class ScopedFeature extends FlowFeature {
  ScopedFeature();
}

void main() {
  group("Scoped Event Dispatching", () {
    test("event bubbles from child to parent manager", () {
      final parentManager = FlowManager();
      final parentFeature = ScopedFeature();
      final parentLogic = ScopedEventLogic();

      parentFeature.addLogic(parentLogic);
      parentManager.addFeature(parentFeature);

      final childManager = FlowManager(parentManager: parentManager);
      final childFeature = ScopedFeature();

      childManager
        ..addFeature(childFeature)
        // Dispatch in child
        ..dispatch(const ScopedEvent("child-event"));

      // Should be received by parent logic
      expect(parentLogic.receivedIds.length, 1);
      expect(parentLogic.receivedIds.first, "child-event");
    });

    test("event triggers both child and parent logics", () {
      final parentManager = FlowManager();
      final parentFeature = ScopedFeature();
      final parentLogic = ScopedEventLogic();

      parentFeature.addLogic(parentLogic);
      parentManager.addFeature(parentFeature);

      final childManager = FlowManager(parentManager: parentManager);
      final childFeature = ScopedFeature();
      final childLogic = ScopedEventLogic();

      childFeature.addLogic(childLogic);

      childManager
        ..addFeature(childFeature)
        // Dispatch in child
        ..dispatch(const ScopedEvent("shared-event"));

      // Should be received by both
      expect(childLogic.receivedIds.length, 1);
      expect(childLogic.receivedIds.first, "shared-event");

      expect(parentLogic.receivedIds.length, 1);
      expect(parentLogic.receivedIds.first, "shared-event");
    });

    test("event bubbles through multiple levels", () {
      final rootManager = FlowManager();
      final rootFeature = ScopedFeature();
      final rootLogic = ScopedEventLogic();

      rootFeature.addLogic(rootLogic);
      rootManager.addFeature(rootFeature);

      final middleManager = FlowManager(parentManager: rootManager);

      FlowManager(parentManager: middleManager).
      // Dispatch in leaf
      dispatch(const ScopedEvent("deep-event"));

      // Should be received by root logic
      expect(rootLogic.receivedIds.length, 1);
      expect(rootLogic.receivedIds.first, "deep-event");
    });

    test("parent events do NOT propagate down to children", () {
      final parentManager = FlowManager();

      final childManager = FlowManager(parentManager: parentManager);
      final childFeature = ScopedFeature();
      final childLogic = ScopedEventLogic();

      childFeature.addLogic(childLogic);
      childManager.addFeature(childFeature);

      // Dispatch in parent
      parentManager.dispatch(const ScopedEvent("parent-event"));

      // Should NOT be received by child logic
      expect(childLogic.receivedIds, isEmpty);
    });
  });
}
