import "package:flutter_test/flutter_test.dart";
import "package:kinora_flow/kinora_flow.dart";

// Test event classes (immutable)
class SimpleEvent {
  const SimpleEvent();
}

class DataEvent {
  final String data;
  final int value;

  const DataEvent(this.data, this.value);
}

class CustomerEvent {
  final String name;
  final String email;

  const CustomerEvent(this.name, this.email);
}

class CountEvent {
  final int count;

  const CountEvent(this.count);
}

// Test logic classes
class SimpleEventLogic extends FlowEventLogic<SimpleEvent> {
  bool reacted = false;
  SimpleEvent? lastEvent;

  @override
  void react(SimpleEvent event) {
    reacted = true;
    lastEvent = event;
  }
}

class DataEventLogic extends FlowEventLogic<DataEvent> {
  final List<DataEvent> receivedEvents = [];

  @override
  void react(DataEvent event) {
    receivedEvents.add(event);
  }
}

class CustomerEventLogic extends FlowEventLogic<CustomerEvent> {
  final List<CustomerEvent> receivedEvents = [];

  @override
  void react(CustomerEvent event) {
    receivedEvents.add(event);
  }
}

class FilteredCountLogic extends FlowEventLogic<CountEvent> {
  final List<int> receivedCounts = [];

  @override
  bool reactsIf(CountEvent event) {
    // Only react to even numbers
    return event.count % 2 == 0;
  }

  @override
  void react(CountEvent event) {
    receivedCounts.add(event.count);
  }
}

class DisposableEventLogic extends FlowEventLogic<SimpleEvent> {
  bool disposed = false;

  @override
  void react(SimpleEvent event) {}

  @override
  void dispose() {
    disposed = true;
  }
}

class MultipleReactionLogic extends FlowEventLogic<DataEvent> {
  int reactionCount = 0;

  @override
  void react(DataEvent event) {
    reactionCount++;
  }
}

// Traditional FlowEvent for backward compatibility tests
class DummyEvent extends FlowEvent {}

class DummyReactiveLogic extends FlowReactiveLogic {
  bool reacted = false;

  @override
  Set<Type> get reactsTo => {DummyEvent};

  @override
  void react() => reacted = true;
}

// Test feature
class TestFeature extends FlowFeature {
  TestFeature();
}

void main() {
  group("FlowEventLogic", () {
    test("basic event dispatch triggers logic", () {
      final feature = TestFeature();
      final logic = SimpleEventLogic();
      final manager = FlowManager();

      feature.addLogic(logic);
      manager.addFeature(feature);

      expect(logic.reacted, isFalse);

      manager.dispatch(const SimpleEvent());

      expect(logic.reacted, isTrue);
      expect(logic.lastEvent, isA<SimpleEvent>());
    });

    test("event with data is received correctly", () {
      final feature = TestFeature();
      final logic = DataEventLogic();
      final manager = FlowManager();

      feature.addLogic(logic);
      manager.addFeature(feature);

      manager.dispatch(const DataEvent("test", 42));

      expect(logic.receivedEvents.length, 1);
      expect(logic.receivedEvents[0].data, "test");
      expect(logic.receivedEvents[0].value, 42);
    });

    test("multiple events of same type", () {
      final feature = TestFeature();
      final logic = DataEventLogic();
      final manager = FlowManager();

      feature.addLogic(logic);
      manager.addFeature(feature);

      manager.dispatch(const DataEvent("first", 1));
      manager.dispatch(const DataEvent("second", 2));
      manager.dispatch(const DataEvent("third", 3));

      expect(logic.receivedEvents.length, 3);
      expect(logic.receivedEvents[0].data, "first");
      expect(logic.receivedEvents[1].data, "second");
      expect(logic.receivedEvents[2].data, "third");
    });

    test("multiple logics for same event type", () {
      final feature = TestFeature();
      final logic1 = DataEventLogic();
      final logic2 = MultipleReactionLogic();
      final manager = FlowManager();

      feature.addLogic(logic1);
      feature.addLogic(logic2);
      manager.addFeature(feature);

      manager.dispatch(const DataEvent("test", 100));

      expect(logic1.receivedEvents.length, 1);
      expect(logic2.reactionCount, 1);
    });

    test("different event types trigger different logics", () {
      final feature = TestFeature();
      final simpleLogic = SimpleEventLogic();
      final dataLogic = DataEventLogic();
      final manager = FlowManager();

      feature.addLogic(simpleLogic);
      feature.addLogic(dataLogic);
      manager.addFeature(feature);

      manager.dispatch(const SimpleEvent());
      expect(simpleLogic.reacted, isTrue);
      expect(dataLogic.receivedEvents.length, 0);

      manager.dispatch(const DataEvent("hello", 5));
      expect(dataLogic.receivedEvents.length, 1);
    });

    test("reactsIf filters events", () {
      final feature = TestFeature();
      final logic = FilteredCountLogic();
      final manager = FlowManager();

      feature.addLogic(logic);
      manager.addFeature(feature);

      // Dispatch odd numbers (should be filtered out)
      manager.dispatch(const CountEvent(1));
      manager.dispatch(const CountEvent(3));
      manager.dispatch(const CountEvent(5));

      expect(logic.receivedCounts.length, 0);

      // Dispatch even numbers (should pass filter)
      manager.dispatch(const CountEvent(2));
      manager.dispatch(const CountEvent(4));

      expect(logic.receivedCounts.length, 2);
      expect(logic.receivedCounts, [2, 4]);
    });

    test("eventType returns correct type", () {
      final logic = DataEventLogic();

      expect(logic.eventType, DataEvent);
    });

    test("dispose is called on event logic", () {
      final feature = TestFeature();
      final logic = DisposableEventLogic();
      final manager = FlowManager();

      feature.addLogic(logic);
      manager.addFeature(feature);

      expect(logic.disposed, isFalse);

      feature.dispose();

      expect(logic.disposed, isTrue);
    });

    test("logicCount includes event logics", () {
      final feature = TestFeature();

      feature.addLogic(SimpleEventLogic());
      feature.addLogic(DataEventLogic());
      feature.addLogic(CustomerEventLogic());

      expect(feature.logicCount, 3);
    });

    test("event logics registered in feature.eventLogics map", () {
      final feature = TestFeature();
      final logic = SimpleEventLogic();

      feature.addLogic(logic);

      expect(feature.eventLogics[SimpleEvent], contains(logic));
    });

    test("dispatch with no registered logics does not throw", () {
      final manager = FlowManager();

      expect(() => manager.dispatch(const SimpleEvent()), returnsNormally);
    });

    test("FlowContext.dispatch works correctly", () {
      final feature = TestFeature();
      final logic = CustomerEventLogic();
      final manager = FlowManager();

      feature.addLogic(logic);
      manager.addFeature(feature);

      final context = FlowContext(manager, () {});

      context.dispatch(const CustomerEvent("John", "john@example.com"));

      expect(logic.receivedEvents.length, 1);
      expect(logic.receivedEvents[0].name, "John");
      expect(logic.receivedEvents[0].email, "john@example.com");
    });

    test("multiple features with event logics", () {
      final feature1 = TestFeature();
      final feature2 = TestFeature();
      final logic1 = SimpleEventLogic();
      final logic2 = SimpleEventLogic();
      final manager = FlowManager();

      feature1.addLogic(logic1);
      feature2.addLogic(logic2);

      manager.addFeature(feature1);
      manager.addFeature(feature2);

      manager.dispatch(const SimpleEvent());

      expect(logic1.reacted, isTrue);
      expect(logic2.reacted, isTrue);
    });
  });

  group("Backward Compatibility", () {
    test("FlowEvent still works with FlowReactiveLogic", () {
      final feature = TestFeature();
      final event = DummyEvent();
      final logic = DummyReactiveLogic();
      final manager = FlowManager();

      feature.addComponent(event);
      feature.addLogic(logic);
      manager.addFeature(feature);

      expect(logic.reacted, isFalse);

      event.trigger();

      expect(logic.reacted, isTrue);
    });

    test("FlowEvent and FlowEventLogic can coexist", () {
      final feature = TestFeature();
      final event = DummyEvent();
      final reactiveLogic = DummyReactiveLogic();
      final eventLogic = SimpleEventLogic();
      final manager = FlowManager();

      feature.addComponent(event);
      feature.addLogic(reactiveLogic);
      feature.addLogic(eventLogic);
      manager.addFeature(feature);

      // Trigger old-style event
      event.trigger();
      expect(reactiveLogic.reacted, isTrue);
      expect(eventLogic.reacted, isFalse);

      // Dispatch new-style event
      manager.dispatch(const SimpleEvent());
      expect(eventLogic.reacted, isTrue);
    });
  });

  group("Edge Cases", () {
    test("dispatching same event instance multiple times", () {
      final feature = TestFeature();
      final logic = DataEventLogic();
      final manager = FlowManager();

      feature.addLogic(logic);
      manager.addFeature(feature);

      const event = DataEvent("shared", 999);

      manager.dispatch(event);
      manager.dispatch(event);
      manager.dispatch(event);

      expect(logic.receivedEvents.length, 3);
      expect(logic.receivedEvents.every((e) => e.data == "shared"), isTrue);
    });

    test("event logic with feature not added to manager", () {
      final feature = TestFeature();
      final logic = SimpleEventLogic();

      // Add logic but don't add feature to manager
      feature.addLogic(logic);

      // This should not throw, just not register the logic
      expect(() => feature.addLogic(logic), returnsNormally);
    });

    test("dispose feature with multiple event logics", () {
      final feature = TestFeature();
      final logic1 = DisposableEventLogic();
      final logic2 = DisposableEventLogic();
      final logic3 = DisposableEventLogic();

      feature.addLogic(logic1);
      feature.addLogic(logic2);
      feature.addLogic(logic3);

      expect(logic1.disposed, isFalse);
      expect(logic2.disposed, isFalse);
      expect(logic3.disposed, isFalse);

      feature.dispose();

      expect(logic1.disposed, isTrue);
      expect(logic2.disposed, isTrue);
      expect(logic3.disposed, isTrue);
    });
  });
}
