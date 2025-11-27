import "package:flutter_test/flutter_test.dart";

import "package:kinora_flow/kinora_flow.dart";

// Test event classes (immutable)
class SimpleEvent {
  const SimpleEvent();
}

class DataEvent {
  const DataEvent(this.data, this.value);
  final String data;
  final int value;
}

class CustomerEvent {
  const CustomerEvent(this.name, this.email);
  final String name;
  final String email;
}

class CountEvent {
  const CountEvent(this.count);
  final int count;
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
    return event.count.isEven;
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

// Sealed class hierarchy for testing inheritance
sealed class IntentEvent {}

class AddIntentEvent extends IntentEvent {
  AddIntentEvent(this.data);
  final String data;
}

class EditIntentEvent extends IntentEvent {
  EditIntentEvent(this.id);

  // ignore: unreachable_from_main
  final String id;
}

class IntentLogic extends FlowEventLogic<IntentEvent> {
  final List<IntentEvent> receivedEvents = [];

  @override
  Set<Type> get reactsTo => {AddIntentEvent, EditIntentEvent};

  @override
  void react(IntentEvent event) {
    receivedEvents.add(event);
  }
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

      manager
        ..addFeature(feature)
        ..dispatch(const DataEvent("test", 42));

      expect(logic.receivedEvents.length, 1);
      expect(logic.receivedEvents[0].data, "test");
      expect(logic.receivedEvents[0].value, 42);
    });

    test("multiple events of same type", () {
      final feature = TestFeature();
      final logic = DataEventLogic();
      final manager = FlowManager();

      feature.addLogic(logic);

      manager
        ..addFeature(feature)
        ..dispatch(const DataEvent("first", 1))
        ..dispatch(const DataEvent("second", 2))
        ..dispatch(const DataEvent("third", 3));

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

      feature
        ..addLogic(logic1)
        ..addLogic(logic2);

      manager
        ..addFeature(feature)
        ..dispatch(const DataEvent("test", 100));

      expect(logic1.receivedEvents.length, 1);
      expect(logic2.reactionCount, 1);
    });

    test("different event types trigger different logics", () {
      final feature = TestFeature();
      final simpleLogic = SimpleEventLogic();
      final dataLogic = DataEventLogic();
      final manager = FlowManager();

      feature
        ..addLogic(simpleLogic)
        ..addLogic(dataLogic);

      manager
        ..addFeature(feature)
        ..dispatch(const SimpleEvent());

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
      manager
        ..addFeature(feature)
        // Dispatch odd numbers (should be filtered out)
        ..dispatch(const CountEvent(1))
        ..dispatch(const CountEvent(3))
        ..dispatch(const CountEvent(5));

      expect(logic.receivedCounts.length, 0);

      // Dispatch even numbers (should pass filter)
      manager
        ..dispatch(const CountEvent(2))
        ..dispatch(const CountEvent(4));

      expect(logic.receivedCounts.length, 2);
      expect(logic.receivedCounts, [2, 4]);
    });

    test("reactsTo returns correct types", () {
      final logic = DataEventLogic();

      expect(logic.reactsTo, {DataEvent});
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
      final feature = TestFeature()
        ..addLogic(SimpleEventLogic())
        ..addLogic(DataEventLogic())
        ..addLogic(CustomerEventLogic());

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

      FlowContext(
        manager,
        () {},
      ).dispatch(const CustomerEvent("John", "john@example.com"));

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

      manager
        ..addFeature(feature1)
        ..addFeature(feature2)
        ..dispatch(const SimpleEvent());

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

      feature
        ..addComponent(event)
        ..addLogic(logic);

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

      feature
        ..addComponent(event)
        ..addLogic(reactiveLogic)
        ..addLogic(eventLogic);

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

      manager
        ..dispatch(event)
        ..dispatch(event)
        ..dispatch(event);

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

      feature
        ..addLogic(logic1)
        ..addLogic(logic2)
        ..addLogic(logic3);

      expect(logic1.disposed, isFalse);
      expect(logic2.disposed, isFalse);
      expect(logic3.disposed, isFalse);

      feature.dispose();

      expect(logic1.disposed, isTrue);
      expect(logic2.disposed, isTrue);
      expect(logic3.disposed, isTrue);
    });
  });

  group("Sealed Classes and Inheritance", () {
    test("logic responds to subclasses when reactsTo includes them", () {
      final feature = TestFeature();
      final logic = IntentLogic();
      final manager = FlowManager();

      feature.addLogic(logic);

      manager
        ..addFeature(feature)
        // Dispatch subclass events
        ..dispatch(AddIntentEvent("test data"))
        ..dispatch(EditIntentEvent("edit-123"));

      expect(logic.receivedEvents.length, 2);
      expect(logic.receivedEvents[0], isA<AddIntentEvent>());
      expect(logic.receivedEvents[1], isA<EditIntentEvent>());
    });

    test("logic receives correct data from subclass events", () {
      final feature = TestFeature();
      final logic = IntentLogic();
      final manager = FlowManager();

      feature.addLogic(logic);

      manager
        ..addFeature(feature)
        ..dispatch(AddIntentEvent("my data"));

      final event = logic.receivedEvents[0] as AddIntentEvent;

      expect(event.data, "my data");
    });

    test("multiple subclass events trigger same logic", () {
      final feature = TestFeature();
      final logic = IntentLogic();
      final manager = FlowManager();

      feature.addLogic(logic);

      manager
        ..addFeature(feature)
        // Dispatch multiple events of different subtypes
        ..dispatch(AddIntentEvent("first"))
        ..dispatch(AddIntentEvent("second"))
        ..dispatch(EditIntentEvent("edit-1"))
        ..dispatch(AddIntentEvent("third"))
        ..dispatch(EditIntentEvent("edit-2"));

      expect(logic.receivedEvents.length, 5);

      expect(
        logic.receivedEvents.whereType<AddIntentEvent>().length,
        3,
      );

      expect(
        logic.receivedEvents.whereType<EditIntentEvent>().length,
        2,
      );
    });
  });
}
