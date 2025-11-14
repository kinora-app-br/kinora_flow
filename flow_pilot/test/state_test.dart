import 'package:flutter_test/flutter_test.dart';

import 'package:kinora_flow_pilot/kinora_flow/kinora_flow.dart';

class TestState extends FlowState<int> {
  TestState([super.value = 0]);
}

class TestEvent extends FlowEvent {
  TestEvent() : super();
}

class TestListener implements IFlowComponentListener {
  TestListener(this.onChanged);
  final void Function() onChanged;

  @override
  void onComponentChanged(FlowComponent component) => onChanged();
}

void main() {
  group("FlowState", () {
    test("notifies listeners on change", () {
      final component = TestState();
      var notified = false;
      final listener = TestListener(() => notified = true);

      component
        ..addListener(listener)
        ..update(1);

      expect(notified, isTrue);
    });

    test("does not notify if value unchanged", () {
      final component = TestState(5);
      var notified = false;
      final listener = TestListener(() => notified = true);

      component
        ..addListener(listener)
        ..update(5);

      expect(notified, isFalse);
    });

    test("removes listener", () {
      final component = TestState();
      var notified = false;
      final listener = TestListener(() => notified = true);

      component
        ..addListener(listener)
        ..removeListener(listener)
        ..update(2);

      expect(notified, isFalse);
    });
  });

  group("FlowEvent", () {
    test("notifies listeners on trigger", () {
      final event = TestEvent();
      var notified = false;
      final listener = TestListener(() => notified = true);

      event
        ..addListener(listener)
        ..trigger();

      expect(notified, isTrue);
    });

    test("can trigger multiple times", () {
      final event = TestEvent();
      var notificationCount = 0;
      final listener = TestListener(() => notificationCount++);

      event
        ..addListener(listener)
        ..trigger()
        ..trigger()
        ..trigger();

      expect(notificationCount, 3);
    });

    test("notifies multiple listeners", () {
      final event = TestEvent();
      var listener1Notified = false;
      var listener2Notified = false;
      final listener1 = TestListener(() => listener1Notified = true);
      final listener2 = TestListener(() => listener2Notified = true);

      event
        ..addListener(listener1)
        ..addListener(listener2)
        ..trigger();

      expect(listener1Notified, isTrue);
      expect(listener2Notified, isTrue);
    });
  });

  group("FlowState Additional Tests", () {
    test("notifies multiple listeners", () {
      final component = TestState();
      var listener1Notified = false;
      var listener2Notified = false;
      final listener1 = TestListener(() => listener1Notified = true);
      final listener2 = TestListener(() => listener2Notified = true);

      component
        ..addListener(listener1)
        ..addListener(listener2)
        ..update(10);

      expect(listener1Notified, isTrue);
      expect(listener2Notified, isTrue);
    });

    test("can handle rapid value changes", () {
      final component = TestState();
      var notificationCount = 0;
      final listener = TestListener(() => notificationCount++);

      component
        ..addListener(listener)
        ..update(1)
        ..update(2)
        ..update(3)
        ..update(4);

      expect(notificationCount, 4);
    });

    test("getter returns correct value", () {
      final component = TestState(42);

      expect(component.value, 42);
      component.update(100);
      expect(component.value, 100);
    });

    test("removing non-existent listener does not throw", () {
      final component = TestState();
      final listener = TestListener(() {});

      expect(() => component.removeListener(listener), returnsNormally);
    });

    test("adding same listener multiple times only adds once", () {
      final component = TestState();
      var notificationCount = 0;
      final listener = TestListener(() => notificationCount++);

      component
        ..addListener(listener)
        ..addListener(listener)
        ..update(5);

      expect(notificationCount, 1);
    });
  });

  group("FlowComponent Base Tests", () {
    test("listeners set is properly managed", () {
      final component = TestState();
      final listener1 = TestListener(() {});
      final listener2 = TestListener(() {});

      expect(component.listeners.length, 0);

      component.addListener(listener1);
      expect(component.listeners.length, 1);
      expect(component.listeners, contains(listener1));

      component.addListener(listener2);
      expect(component.listeners.length, 2);

      component.removeListener(listener1);
      expect(component.listeners.length, 1);
      expect(component.listeners, isNot(contains(listener1)));
      expect(component.listeners, contains(listener2));
    });
  });
}
