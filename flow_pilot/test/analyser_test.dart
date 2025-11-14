import 'package:flutter_test/flutter_test.dart';

import 'package:kinora_flow_pilot/kinora_flow/kinora_flow.dart';

class TestEvent extends FlowEvent {}

class TestState extends FlowState<int> {
  TestState([super.value = 0]);
}

class AnotherEvent extends FlowEvent {}

// Test logics
class TestFlowReactiveLogic extends FlowReactiveLogic {
  @override
  Set<Type> get reactsTo => {TestEvent};

  @override
  Set<Type> get interactsWith => {TestState, AnotherEvent};

  @override
  void react() {}
}

class AnotherFlowReactiveLogic extends FlowReactiveLogic {
  @override
  Set<Type> get reactsTo => {TestState};

  @override
  Set<Type> get interactsWith => {AnotherEvent};

  @override
  void react() {}
}

class TestFeature extends FlowFeature {
  TestFeature() {
    addComponents({
      TestEvent(),
      TestState(),
      AnotherEvent(),
    });

    addLogics({
      TestFlowReactiveLogic(),
      AnotherFlowReactiveLogic(),
    });
  }
}

void main() {
  group("Cascade Flow Analysis Tests", () {
    late FlowManager manager;

    setUp(() {
      manager = FlowManager()..addFeature(TestFeature());
    });

    test("should build cascade graph", () {
      final graph = FlowAnalyser.analize(manager);

      expect(graph.nodes.isNotEmpty, true);
      expect(graph.edges.isNotEmpty, true);
    });

    test("should detect cascade flows from TestEvent", () {
      final graph = FlowAnalyser.analize(manager);
      final flows = graph.getCascadeFlowsFrom(TestEvent);

      expect(flows.isNotEmpty, true);

      // TestEvent should trigger flows through TestFlowReactiveLogic
      final flow = flows.first;
      expect(flow.nodes.first.type, TestEvent);
    });

    test("should get cascade summary", () {
      final graph = FlowAnalyser.analize(manager);
      final summary = graph.getCascadeSummary();

      expect(summary.totalComponents, greaterThan(0));
      expect(summary.totalConnections, greaterThan(0));
    });

    test("should identify cascade triggers", () {
      final graph = FlowAnalyser.analize(manager);
      final triggers = graph.getCascadeTriggers();

      expect(triggers.contains(TestEvent), true);
      expect(triggers.contains(TestState), true);
    });

    test("should identify cascade targets", () {
      final graph = FlowAnalyser.analize(manager);
      final targets = graph.getCascadeTargets();

      expect(targets.contains(TestState), true);
      expect(targets.contains(AnotherEvent), true);
    });

    test("should detect no circular dependencies in simple case", () {
      final graph = FlowAnalyser.analize(manager);
      final circular = graph.getCircularDependencies();

      expect(circular.isEmpty, true);
    });

    test("should validate logic without issues", () {
      final graph = FlowAnalyser.analize(manager);
      final issues = graph.validateCascadeSystem();

      expect(issues.isEmpty, true);
    });

    test("should generate DOT graph", () {
      final graph = FlowAnalyser.analize(manager);
      final dotGraph = graph.generateDotGraph();

      expect(dotGraph.contains("digraph ECS_Cascade_Flow"), true);
      expect(dotGraph.contains("TestEvent"), true);
      expect(dotGraph.contains("TestComponent"), true);
    });

    test("should simulate cascade flow", () {
      final graph = FlowAnalyser.analize(manager);
      final simulation = graph.simulateCascadeFlow(TestEvent);

      expect(simulation.isNotEmpty, true);
      expect(simulation.first.contains("TestEvent"), true);
    });
  });

  group("Circular Dependency Detection Tests", () {
    test("should detect circular dependencies", () {
      final manager = FlowManager();

      // Create a circular dependency
      final feature = _CircularTestFeature();
      manager.addFeature(feature);

      final graph = FlowAnalyser.analize(manager);
      final circular = graph.getCircularDependencies();

      expect(circular.isNotEmpty, true);

      final cycle = circular.first;
      expect(cycle.isCircular, true);
    });
  });
}

// Test feature that creates circular dependencies
class CircularEvent1 extends FlowEvent {}

class CircularEvent2 extends FlowEvent {}

class CircularLogic1 extends FlowReactiveLogic {
  @override
  Set<Type> get reactsTo => {CircularEvent1};

  @override
  Set<Type> get interactsWith => {CircularEvent2};

  @override
  void react() {}
}

class CircularLogic2 extends FlowReactiveLogic {
  @override
  Set<Type> get reactsTo => {CircularEvent2};

  @override
  Set<Type> get interactsWith => {CircularEvent1};

  @override
  void react() {}
}

class _CircularTestFeature extends FlowFeature {
  _CircularTestFeature() {
    addComponents({
      CircularEvent1(),
      CircularEvent2(),
    });

    addLogics({
      CircularLogic1(),
      CircularLogic2(),
    });
  }
}
