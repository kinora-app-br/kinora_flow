import 'package:flutter_test/flutter_test.dart';

import 'package:kinora_flow/kinora_flow.dart';

class DummyState extends FlowState<int> {
  DummyState([super.value = 0]);
}

class DummyEvent extends FlowEvent {}

class DummyInitLogic extends FlowFeatureInitializationLogic {
  bool initialized = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  void initialize() => initialized = true;
}

class DummyDisposalLogic extends FlutterFeatureDisposalLogic {
  bool tornDown = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  void dispose() => tornDown = true;
}

class DummyCleanupLogic extends FlowCleanUpLogic {
  bool cleaned = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  void cleanup() => cleaned = true;
}

class DummyExecuteLogic extends FlowFrameExecutionLogic {
  Duration? lastElapsed;

  @override
  Set<Type> get interactsWith => {};

  @override
  void execute(Duration elapsed) => lastElapsed = elapsed;
}

class DummyReactiveLogic extends FlowReactiveLogic {
  bool reacted = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  Set<Type> get reactsTo => {DummyEvent};

  @override
  void react() => reacted = true;
}

class TestFeature extends FlowFeature {
  TestFeature();
}

class MultiReactiveLogic extends FlowReactiveLogic {
  bool reacted = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  Set<Type> get reactsTo => {DummyEvent, DummyState};

  @override
  void react() => reacted = true;
}

void main() {
  group("FlowFeature", () {
    test("addComponent and getComponent", () {
      final feature = TestFeature()..addComponents({DummyState(), DummyEvent()});

      expect(feature.getComponent<DummyState>(), isA<DummyState>());
      expect(feature.getComponent<DummyEvent>(), isA<DummyEvent>());
    });

    test("addLogic registers all logic types", () {
      final feature = TestFeature();
      final init = DummyInitLogic();
      final dispose = DummyDisposalLogic();
      final cleanup = DummyCleanupLogic();
      final execute = DummyExecuteLogic();
      final reactive = DummyReactiveLogic();

      feature
        ..addLogic(init)
        ..addLogic(dispose)
        ..addLogic(cleanup)
        ..addLogic(execute)
        ..addLogic(reactive);

      expect(feature.initializeLogics, contains(init));
      expect(feature.disposalLogics, contains(dispose));
      expect(feature.cleanupLogics, contains(cleanup));
      expect(feature.executeLogics, contains(execute));
      expect(feature.reactiveLogics[DummyEvent], contains(reactive));
    });

    test("initialize calls all InitializeLogics", () {
      final feature = TestFeature();
      final init = DummyInitLogic();

      feature
        ..addLogic(init)
        ..initialize();

      expect(init.initialized, isTrue);
    });

    test("dispose calls all DisposalLogics", () {
      final feature = TestFeature();
      final dispose = DummyDisposalLogic();

      feature
        ..addLogic(dispose)
        ..dispose();

      expect(dispose.tornDown, isTrue);
    });

    test("cleanup calls all CleanupLogics", () {
      final feature = TestFeature();
      final cleanup = DummyCleanupLogic();

      feature
        ..addLogic(cleanup)
        ..cleanup();

      expect(cleanup.cleaned, isTrue);
    });

    test("execute calls all ExecuteLogics", () {
      final feature = TestFeature();
      final execute = DummyExecuteLogic();

      feature.addLogic(execute);

      const duration = Duration(milliseconds: 123);

      feature.execute(duration);

      expect(execute.lastElapsed, duration);
    });

    test("reactiveLogics map is correct", () {
      final feature = TestFeature();
      final reactive = DummyReactiveLogic();

      feature.addLogic(reactive);
      expect(feature.reactiveLogics[DummyEvent], contains(reactive));
    });

    test("logicsCount returns correct total", () {
      final feature = TestFeature()
        ..addLogic(DummyInitLogic())
        ..addLogic(DummyDisposalLogic())
        ..addLogic(DummyCleanupLogic())
        ..addLogic(DummyExecuteLogic())
        ..addLogic(DummyReactiveLogic());

      expect(feature.logicCount, 5);
    });

    test("getComponent throws StateError for non-existent component type", () {
      final feature = TestFeature();

      expect(() => feature.getComponent<DummyState>(), throwsA(isA<StateError>()));
    });

    test("multiple components of same type returns first", () {
      final component1 = DummyState(10);
      final component2 = DummyState(20);
      final feature = TestFeature()..addComponents({component1, component2});
      final retrieved = feature.getComponent<DummyState>();

      expect(retrieved, equals(component1));
    });

    test("multiple logics of same type are all registered", () {
      final init1 = DummyInitLogic();
      final init2 = DummyInitLogic();
      final feature = TestFeature()..addLogics({init1, init2});

      expect(feature.initializeLogics.length, 2);
      expect(feature.initializeLogics, contains(init1));
      expect(feature.initializeLogics, contains(init2));
    });

    test("multiple reactive logics for same event type", () {
      final reactive1 = DummyReactiveLogic();
      final reactive2 = DummyReactiveLogic();
      final feature = TestFeature()..addLogics({reactive1, reactive2});

      expect(feature.reactiveLogics[DummyEvent]?.length, 2);
      expect(feature.reactiveLogics[DummyEvent], contains(reactive1));
      expect(feature.reactiveLogics[DummyEvent], contains(reactive2));
    });

    test("lifecycle methods work with multiple logics", () {
      final init1 = DummyInitLogic();
      final init2 = DummyInitLogic();
      final dispose1 = DummyDisposalLogic();
      final dispose2 = DummyDisposalLogic();

      final feature = TestFeature()
        ..addLogics({init1, init2, dispose1, dispose2})
        ..initialize();

      expect(init1.initialized, isTrue);
      expect(init2.initialized, isTrue);

      feature.dispose();
      expect(dispose1.tornDown, isTrue);
      expect(dispose2.tornDown, isTrue);
    });

    test("empty feature lifecycle methods work", () {
      final feature = TestFeature();

      expect(feature.initialize, returnsNormally);
      expect(feature.dispose, returnsNormally);
      expect(feature.cleanup, returnsNormally);
      expect(() => feature.execute(.zero), returnsNormally);
    });

    test("logicsCount is zero for empty feature", () {
      final feature = TestFeature();

      expect(feature.logicCount, 0);
    });

    test("components set contains all added components", () {
      final feature = TestFeature();
      final component = DummyState();
      final event = DummyEvent();

      feature.addComponents({component, event});
      expect(feature.components.length, 2);
      expect(feature.components, contains(component));
      expect(feature.components, contains(event));
    });

    test("reactive logic with multiple reactsTo types", () {
      final feature = TestFeature();
      final multiReactiveLogic = MultiReactiveLogic();

      feature.addLogic(multiReactiveLogic);
      expect(feature.reactiveLogics[DummyEvent], contains(multiReactiveLogic));
      expect(feature.reactiveLogics[DummyState], contains(multiReactiveLogic));
    });
  });
}
