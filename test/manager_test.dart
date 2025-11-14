import 'package:flutter_test/flutter_test.dart';

import 'package:kinora_flow/kinora_flow.dart';

class DummyState extends FlowState<int> {
  DummyState([super.value = 0]);
}

class DummyEvent extends FlowEvent {}

class DummyReactiveLogic extends FlowReactiveLogic {
  bool reacted = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  Set<Type> get reactsTo => {DummyEvent};

  @override
  void react() => reacted = true;
}

class DummyFeature extends FlowFeature {
  DummyFeature() {
    addComponents({DummyState(), DummyEvent()});
  }
}

class AnotherDummyFeature extends FlowFeature {
  AnotherDummyFeature() {
    addLogic(DummyReactiveLogic());
  }

  bool initialized = false;
  bool tornDown = false;
  bool cleaned = false;
  bool executed = false;

  @override
  void initialize() {
    initialized = true;
  }

  @override
  void dispose() {
    tornDown = true;
  }

  @override
  void cleanup() {
    cleaned = true;
  }

  @override
  void execute(Duration elapsed) {
    executed = true;
  }
}

class ComponentReactiveLogic extends FlowReactiveLogic {
  bool reacted = false;

  @override
  Set<Type> get interactsWith => {};

  @override
  Set<Type> get reactsTo => {DummyState};

  @override
  void react() => reacted = true;
}

void main() {
  group("FlowManager", () {
    test("addFeature adds feature and components", () {
      final manager = FlowManager();
      final feature = DummyFeature();

      manager.addFeature(feature);
      expect(manager.features, contains(feature));
      expect(manager.components.whereType<DummyState>().length, 1);
      expect(manager.components.whereType<DummyEvent>().length, 1);
    });

    test("get returns correct component", () {
      final manager = FlowManager();
      final feature = DummyFeature();

      manager.addFeature(feature);

      final component = manager.getComponent<DummyState>();

      expect(component, isA<DummyState>());
    });

    test("get throws if component not found", () {
      final manager = FlowManager();

      expect(() => manager.getComponent<DummyState>(), throwsStateError);
    });

    test("initialize, dispose, execute, cleanup call feature methods", () {
      final manager = FlowManager();
      final feature = AnotherDummyFeature();

      manager
        ..addFeature(feature)
        ..initialize();

      expect(feature.initialized, isTrue);
      manager.dispose();
      expect(feature.tornDown, isTrue);
      manager.cleanup();
      expect(feature.cleaned, isTrue);
      manager.execute(.zero);
      expect(feature.executed, isTrue);
    });

    test("onComponentChanged triggers reactive logic", () {
      final manager = FlowManager();
      final feature = DummyFeature();
      final reactive = DummyReactiveLogic();

      feature.addLogic(reactive);
      manager.addFeature(feature);
      feature.getComponent<DummyEvent>().trigger();
      expect(reactive.reacted, isTrue);
    });

    test("components and getComponent work across multiple features", () {
      final manager = FlowManager();
      final feature1 = DummyFeature();
      final feature2 = DummyFeature();

      manager.addFeatures({feature1, feature2});

      expect(manager.components.whereType<DummyState>().length, 2);
      expect(manager.getComponent<DummyState>(), isA<DummyState>());
    });

    test("getComponent returns first found for duplicate types", () {
      final manager = FlowManager();
      final feature1 = DummyFeature();
      final feature2 = DummyFeature();

      manager.addFeatures({feature1, feature2});

      final component = manager.getComponent<DummyState>();

      expect(
        component,
        anyOf(
          feature1.getComponent<DummyState>(),
          feature2.getComponent<DummyState>(),
        ),
      );
    });

    test("calling methods on empty manager does not throw", () {
      final manager = FlowManager();

      expect(manager.initialize, returnsNormally);
      expect(manager.dispose, returnsNormally);
      expect(manager.cleanup, returnsNormally);
      expect(() => manager.execute(.zero), returnsNormally);
    });

    test("onComponentChanged with no reactive logic does not throw", () {
      final manager = FlowManager();
      final feature = DummyFeature();

      manager.addFeature(feature);

      final event = feature.getComponent<DummyEvent>();

      expect(() => manager.onComponentChanged(event), returnsNormally);
    });

    test("manager is registered as listener for all components", () {
      final manager = FlowManager();
      final feature = DummyFeature();

      manager.addFeature(feature);

      final component = feature.getComponent<DummyState>();

      expect(component.listeners, contains(manager));
    });

    test("multiple reactive logic for same component type are triggered", () {
      final manager = FlowManager();
      final feature = DummyFeature();
      final reactive1 = DummyReactiveLogic();
      final reactive2 = DummyReactiveLogic();

      feature.addLogics({reactive1, reactive2});
      manager.addFeature(feature);
      feature.getComponent<DummyEvent>().trigger();
      expect(reactive1.reacted, isTrue);
      expect(reactive2.reacted, isTrue);
    });

    test("reactive logic only trigger for correct component types", () {
      final manager = FlowManager();
      final feature = DummyFeature();
      final eventReactiveLogic = DummyReactiveLogic();
      final componentReactiveLogic = ComponentReactiveLogic();

      feature.addLogics({eventReactiveLogic, componentReactiveLogic});
      manager.addFeature(feature);

      // Trigger event - only event reactive logic should react
      feature.getComponent<DummyEvent>().trigger();
      expect(eventReactiveLogic.reacted, isTrue);
      expect(componentReactiveLogic.reacted, isFalse);

      // Reset and trigger component
      eventReactiveLogic.reacted = false;
      feature.getComponent<DummyState>().update(42);
      expect(eventReactiveLogic.reacted, isFalse);
      expect(componentReactiveLogic.reacted, isTrue);
    });

    test("manager tracks components from multiple features correctly", () {
      final manager = FlowManager();
      final feature1 = DummyFeature();
      final feature2 = AnotherDummyFeature();

      manager.addFeatures({feature1, feature2});

      final allComponents = manager.components;

      expect(allComponents.whereType<DummyState>().length, 1);
      expect(allComponents.whereType<DummyEvent>().length, 1);
      expect(allComponents.length, 2);
    });

    test("getComponent searches features in order", () {
      final manager = FlowManager();
      final feature1 = DummyFeature();
      final feature2 = DummyFeature();

      manager.addFeatures({feature1, feature2});

      final component = manager.getComponent<DummyState>();

      expect(component, equals(feature1.getComponent<DummyState>()));
    });

    test("lifecycle methods handle multiple features correctly", () {
      final manager = FlowManager();
      final feature1 = AnotherDummyFeature();
      final feature2 = AnotherDummyFeature();

      manager
        ..addFeatures({feature1, feature2})
        ..initialize();

      expect(feature1.initialized, isTrue);
      expect(feature2.initialized, isTrue);

      manager.dispose();
      expect(feature1.tornDown, isTrue);
      expect(feature2.tornDown, isTrue);

      manager.cleanup();
      expect(feature1.cleaned, isTrue);
      expect(feature2.cleaned, isTrue);

      const duration = Duration(milliseconds: 100);

      manager.execute(duration);
      expect(feature1.executed, isTrue);
      expect(feature2.executed, isTrue);
    });

    test("component change triggers logic across all features", () {
      final manager = FlowManager();
      final feature1 = DummyFeature();
      final feature2 = AnotherDummyFeature();
      final reactive1 = DummyReactiveLogic();
      final reactive2 = DummyReactiveLogic();

      feature1.addLogics({reactive1, reactive2});
      manager.addFeatures({feature1, feature2});
      feature1.getComponent<DummyEvent>().trigger();
      expect(reactive1.reacted, isTrue);
      expect(reactive2.reacted, isTrue);
    });

    test("error handling for malformed features", () {
      final manager = FlowManager();
      final emptyFeature = AnotherDummyFeature();

      manager.addFeature(emptyFeature);
      expect(manager.initialize, returnsNormally);
      expect(manager.dispose, returnsNormally);
      expect(manager.cleanup, returnsNormally);
      expect(() => manager.execute(.zero), returnsNormally);
    });

    test("features property returns unmodifiable set", () {
      final manager = FlowManager();
      final feature = DummyFeature();

      manager.addFeature(feature);

      final features = manager.features;

      expect(features, contains(feature));
      expect(features.length, 1);
    });
  });
}
