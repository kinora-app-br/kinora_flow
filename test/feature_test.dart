import "dart:async";

import "package:flutter_test/flutter_test.dart";

import "package:kinora_flow/kinora_flow.dart";

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

class DummyDisposalLogic extends FlowFeatureDisposalLogic {
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

class DisposableInitLogic extends FlowFeatureInitializationLogic {
  bool disposed = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  void initialize() {}

  @override
  void dispose() {
    disposed = true;
  }
}

class DisposableCleanupLogic extends FlowCleanUpLogic {
  bool disposed = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  void cleanup() {}

  @override
  void dispose() {
    disposed = true;
  }
}

class DisposableExecuteLogic extends FlowFrameExecutionLogic {
  bool disposed = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  void execute(Duration elapsed) {}

  @override
  void dispose() {
    disposed = true;
  }
}

class DisposableReactiveLogic extends FlowReactiveLogic {
  bool disposed = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  Set<Type> get reactsTo => {DummyEvent};

  @override
  void react() {}

  @override
  void dispose() {
    disposed = true;
  }
}

class StreamSubscriptionLogic extends FlowFeatureInitializationLogic {
  StreamSubscription<int>? subscription;
  bool disposed = false;
  int receivedValue = 0;

  @override
  Set<Type> get interactsWith => {};

  @override
  void initialize() {
    final controller = StreamController<int>.broadcast();

    subscription = controller.stream.listen((value) {
      receivedValue = value;
    });

    controller.add(42);
  }

  @override
  void dispose() {
    unawaited(subscription?.cancel());
    subscription = null;
    disposed = true;
  }
}

class CustomDisposableReactiveLogic extends FlowReactiveLogic {
  CustomDisposableReactiveLogic();

  bool disposed = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  Set<Type> get reactsTo => {DummyState};

  @override
  void react() {}

  @override
  void dispose() {
    disposed = true;
  }
}

class StreamListeningInitLogic extends FlowFeatureInitializationLogic {
  StreamListeningInitLogic(this.controller);

  final StreamController<int> controller;
  final List<int> receivedValues = [];

  StreamSubscription<int>? subscription;

  @override
  Set<Type> get interactsWith => {};

  @override
  void initialize() {
    subscription = controller.stream.listen(receivedValues.add);
  }

  @override
  void dispose() {
    unawaited(subscription?.cancel());
    subscription = null;
  }
}

class DisposableMultiReactiveLogic extends FlowReactiveLogic {
  int disposeCallCount = 0;

  @override
  Set<Type> get interactsWith => {};

  @override
  Set<Type> get reactsTo => {DummyEvent, DummyState};

  @override
  void react() {}

  @override
  void dispose() {
    disposeCallCount++;
  }
}

class StateWatchingInitLogic extends FlowFeatureInitializationLogic {
  StateWatchingInitLogic(this.state);

  final DummyState state;
  final List<int> receivedValues = [];
  void Function()? _unsubscribe;
  bool disposed = false;

  @override
  Set<Type> get interactsWith => {DummyState};

  @override
  void initialize() {
    _unsubscribe = state.onChanged(receivedValues.add);
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _unsubscribe = null;
    disposed = true;
  }
}

class StateWatchingWithCurrentValueInitLogic
    extends FlowFeatureInitializationLogic {
  StateWatchingWithCurrentValueInitLogic(this.state);

  final DummyState state;
  final List<int> receivedValues = [];
  void Function()? _unsubscribe;

  @override
  Set<Type> get interactsWith => {DummyState};

  @override
  void initialize() {
    _unsubscribe = state.onChanged(
      receivedValues.add,
      triggerWithCurrentValue: true,
    );
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _unsubscribe = null;
  }
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

    test("dispose calls dispose on all initialization logics", () {
      final feature = TestFeature();
      final initLogic = DisposableInitLogic();

      feature
        ..addLogic(initLogic)
        ..dispose();

      expect(initLogic.disposed, isTrue);
    });

    test("dispose calls dispose on all cleanup logics", () {
      final feature = TestFeature();
      final cleanupLogic = DisposableCleanupLogic();

      feature
        ..addLogic(cleanupLogic)
        ..dispose();

      expect(cleanupLogic.disposed, isTrue);
    });

    test("dispose calls dispose on all execute logics", () {
      final feature = TestFeature();
      final executeLogic = DisposableExecuteLogic();

      feature
        ..addLogic(executeLogic)
        ..dispose();

      expect(executeLogic.disposed, isTrue);
    });

    test("dispose calls dispose on all reactive logics", () {
      final feature = TestFeature();
      final reactiveLogic = DisposableReactiveLogic();

      feature
        ..addLogic(reactiveLogic)
        ..dispose();

      expect(reactiveLogic.disposed, isTrue);
    });

    test("dispose calls dispose on all logic types", () {
      final feature = TestFeature();
      final initLogic = DisposableInitLogic();
      final disposalLogic = DummyDisposalLogic();
      final cleanupLogic = DisposableCleanupLogic();
      final executeLogic = DisposableExecuteLogic();
      final reactiveLogic = DisposableReactiveLogic();

      feature
        ..addLogic(initLogic)
        ..addLogic(disposalLogic)
        ..addLogic(cleanupLogic)
        ..addLogic(executeLogic)
        ..addLogic(reactiveLogic)
        ..dispose();

      expect(initLogic.disposed, isTrue);
      expect(disposalLogic.tornDown, isTrue);
      expect(cleanupLogic.disposed, isTrue);
      expect(executeLogic.disposed, isTrue);
      expect(reactiveLogic.disposed, isTrue);
    });

    test("dispose calls dispose on multiple logics of same type", () {
      final feature = TestFeature();
      final initLogic1 = DisposableInitLogic();
      final initLogic2 = DisposableInitLogic();
      final executeLogic1 = DisposableExecuteLogic();
      final executeLogic2 = DisposableExecuteLogic();

      feature
        ..addLogics({initLogic1, initLogic2, executeLogic1, executeLogic2})
        ..dispose();

      expect(initLogic1.disposed, isTrue);
      expect(initLogic2.disposed, isTrue);
      expect(executeLogic1.disposed, isTrue);
      expect(executeLogic2.disposed, isTrue);
    });

    test(
      "FlowFeatureInitializationLogic disposes StreamSubscription on feature dispose",
      () async {
        final feature = TestFeature();
        final streamLogic = StreamSubscriptionLogic();

        feature
          ..addLogic(streamLogic)
          ..initialize();

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(streamLogic.receivedValue, 42);
        expect(streamLogic.disposed, isFalse);
        expect(streamLogic.subscription, isNotNull);

        feature.dispose();

        expect(streamLogic.disposed, isTrue);
        expect(streamLogic.subscription, isNull);
      },
    );

    test(
      "FlowFeatureInitializationLogic with StreamSubscription receives events before dispose",
      () async {
        final feature = TestFeature();
        final controller = StreamController<int>.broadcast();
        final initLogic = StreamListeningInitLogic(controller);

        feature
          ..addLogic(initLogic)
          ..initialize();

        controller
          ..add(1)
          ..add(2)
          ..add(3);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(initLogic.receivedValues, [1, 2, 3]);
        expect(initLogic.subscription, isNotNull);

        feature.dispose();

        controller.add(4);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(initLogic.receivedValues, [1, 2, 3]);
        expect(initLogic.subscription, isNull);
      },
    );

    test(
      "dispose handles multiple reactive logics with different component types",
      () {
        final feature = TestFeature();
        final reactiveLogic1 = DisposableReactiveLogic();
        final reactiveLogic2 = MultiReactiveLogic();
        final customReactiveLogic = CustomDisposableReactiveLogic();

        feature
          ..addLogic(reactiveLogic1)
          ..addLogic(reactiveLogic2)
          ..addLogic(customReactiveLogic)
          ..dispose();

        expect(reactiveLogic1.disposed, isTrue);
        expect(customReactiveLogic.disposed, isTrue);
      },
    );

    test("dispose is safe to call multiple times", () {
      final feature = TestFeature();
      final initLogic = DisposableInitLogic();
      final executeLogic = DisposableExecuteLogic();

      feature
        ..addLogics({initLogic, executeLogic})
        ..dispose();

      expect(initLogic.disposed, isTrue);
      expect(executeLogic.disposed, isTrue);

      feature.dispose();

      expect(initLogic.disposed, isTrue);
      expect(executeLogic.disposed, isTrue);
    });

    test(
      "dispose calls dispose only once on reactive logic that reacts to multiple component types",
      () {
        final feature = TestFeature();
        final multiReactiveLogic = DisposableMultiReactiveLogic();

        feature
          ..addLogic(multiReactiveLogic)
          ..dispose();

        expect(multiReactiveLogic.disposeCallCount, 1);
      },
    );

    test(
      "FlowFeatureInitializationLogic can use state.onChanged to watch state changes",
      () {
        final feature = TestFeature();
        final state = DummyState(0);
        final logic = StateWatchingInitLogic(state);

        feature
          ..addComponent(state)
          ..addLogic(logic)
          ..initialize();

        expect(logic.receivedValues, isEmpty);

        state.update(10);
        expect(logic.receivedValues, [10]);

        state.update(20);
        expect(logic.receivedValues, [10, 20]);

        state.update(30);
        expect(logic.receivedValues, [10, 20, 30]);
      },
    );

    test(
      "FlowFeatureInitializationLogic state.onChanged disposes on feature dispose",
      () {
        final feature = TestFeature();
        final state = DummyState(0);
        final logic = StateWatchingInitLogic(state);

        feature
          ..addComponent(state)
          ..addLogic(logic)
          ..initialize();

        state.update(10);
        expect(logic.receivedValues, [10]);

        feature.dispose();

        state.update(20);
        expect(logic.receivedValues, [10]); // Should not receive 20 after dispose
        expect(logic.disposed, isTrue);
      },
    );

    test(
      "FlowFeatureInitializationLogic state.onChanged with triggerWithCurrentValue",
      () {
        final feature = TestFeature();
        final state = DummyState(42);
        final logic = StateWatchingWithCurrentValueInitLogic(state);

        feature
          ..addComponent(state)
          ..addLogic(logic)
          ..initialize();

        expect(logic.receivedValues, [42]); // Should receive current value immediately

        state.update(100);
        expect(logic.receivedValues, [42, 100]);
      },
    );
  });
}
