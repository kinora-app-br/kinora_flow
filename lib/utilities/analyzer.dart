part of '../kinora_flow.dart';

@immutable
final class FlowNode {
  FlowNode({
    required this.type,
    required this.description,
  });

  final Type type;
  final String description;
  final outgoing = <FlowEdge>{};
  final incoming = <FlowEdge>{};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FlowNode &&
        runtimeType == other.runtimeType &&
        type == other.type;
  }

  @override
  int get hashCode {
    return type.hashCode;
  }

  @override
  String toString() {
    return "$description ($type)";
  }
}

@immutable
final class FlowEdge {
  const FlowEdge({
    required this.from,
    required this.to,
    this.type,
    this.description,
  });

  final FlowNode from;
  final FlowNode to;
  final Type? type;
  final String? description;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FlowEdge &&
        runtimeType == other.runtimeType &&
        from == other.from &&
        to == other.to &&
        type == other.type;
  }

  @override
  int get hashCode {
    return Object.hash(from, to, type);
  }
}

final class FlowFlow {
  FlowFlow({required this.nodes, required this.edges});

  final List<FlowNode> nodes;
  final List<FlowEdge> edges;

  int get length => nodes.length;

  bool get isCircular => nodes.isNotEmpty && nodes.first == nodes.last;
}

final class FlowSummary {
  const FlowSummary({
    required this.totalComponents,
    required this.totalConnections,
    required this.cascadeTriggers,
    required this.cascadeTargets,
    required this.circularDependencies,
    required this.maxFlowDepth,
  });

  final int totalComponents;
  final int totalConnections;
  final int cascadeTriggers;
  final int cascadeTargets;
  final int circularDependencies;
  final int maxFlowDepth;

  @override
  String toString() {
    return """
      Cascade Summary:
      - Total Components: $totalComponents
      - Total Connections: $totalConnections
      - Cascade Triggers: $cascadeTriggers
      - Cascade Targets: $cascadeTargets
      - Circular Dependencies: $circularDependencies
      - Max Flow Depth: $maxFlowDepth
    """;
  }
}

final class FlowAnalysis {
  const FlowAnalysis({
    required this.nodes,
    required this.edges,
  });

  final Map<Type, FlowNode> nodes;
  final Set<FlowEdge> edges;

  /// Returns all components that can potentially trigger cascades
  Set<Type> getCascadeTriggers() {
    return nodes.values
        .where((node) => node.outgoing.isNotEmpty)
        .map((node) => node.type)
        .toSet();
  }

  /// Returns all components that can be affected by cascades
  Set<Type> getCascadeTargets() {
    return nodes.values
        .where((node) => node.incoming.isNotEmpty)
        .map((node) => node.type)
        .toSet();
  }

  /// Returns a summary of the cascade logic
  FlowSummary getCascadeSummary() {
    final circular = getCircularDependencies();
    var maxDepth = 0;

    for (final type in nodes.keys) {
      final flows = getCascadeFlowsFrom(type, maxDepth: 20);

      for (final flow in flows) {
        if (flow.isCircular == false && flow.length > maxDepth) {
          maxDepth = flow.length;
        }
      }
    }

    return FlowSummary(
      totalComponents: nodes.length,
      totalConnections: edges.length,
      cascadeTriggers: getCascadeTriggers().length,
      cascadeTargets: getCascadeTargets().length,
      circularDependencies: circular.length,
      maxFlowDepth: maxDepth,
    );
  }

  /// Finds all potential cascade flows from a specific component type
  List<FlowFlow> getCascadeFlowsFrom(Type componentType, {int maxDepth = 10}) {
    final startNode = nodes[componentType];

    if (startNode == null) return [];

    final flows = <FlowFlow>[];
    final visited = <FlowNode>{};

    void findFlowsRecursive(
      FlowNode currentNode,
      List<FlowNode> currentPath,
      List<FlowEdge> currentEdges,
      List<FlowFlow> flows,
      Set<FlowNode> visited,
      int remainingDepth,
    ) {
      if (remainingDepth <= 0) return;

      currentPath.add(currentNode);

      if (visited.contains(currentNode)) {
        flows.add(
          FlowFlow(
            nodes: .from(currentPath),
            edges: .from(currentEdges),
          ),
        );

        currentPath.removeLast();
        return;
      }

      visited.add(currentNode);

      if (currentNode.outgoing.isEmpty) {
        flows.add(
          FlowFlow(
            nodes: .from(currentPath),
            edges: .from(currentEdges),
          ),
        );
      } else {
        // Continue exploring outgoing edges
        for (final edge in currentNode.outgoing) {
          currentEdges.add(edge);

          findFlowsRecursive(
            edge.to,
            currentPath,
            currentEdges,
            flows,
            visited,
            remainingDepth - 1,
          );

          currentEdges.removeLast();
        }
      }

      visited.remove(currentNode);
      currentPath.removeLast();
    }

    findFlowsRecursive(
      startNode,
      [],
      [],
      flows,
      visited,
      maxDepth,
    );

    return flows;
  }

  /// Returns all circular dependencies in the logic
  List<FlowFlow> getCircularDependencies() {
    final circularFlows = <FlowFlow>[];
    final visited = <FlowNode>{};
    final recursionStack = <FlowNode>{};

    void findCircularDependencies(
      FlowNode node,
      Set<FlowNode> visited,
      Set<FlowNode> recursionStack,
      List<FlowNode> path,
      List<FlowEdge> edges,
      List<FlowFlow> circularFlows,
    ) {
      visited.add(node);
      recursionStack.add(node);
      path.add(node);

      for (final edge in node.outgoing) {
        final neighbor = edge.to;

        edges.add(edge);

        if (visited.contains(neighbor) == false) {
          findCircularDependencies(
            neighbor,
            visited,
            recursionStack,
            path,
            edges,
            circularFlows,
          );
        } else if (recursionStack.contains(neighbor)) {
          final cycleStartIndex = path.indexOf(neighbor);
          final cyclePath = path.sublist(cycleStartIndex)..add(neighbor);
          final cycleEdges = edges.sublist(cycleStartIndex);

          circularFlows.add(
            FlowFlow(
              nodes: .from(cyclePath),
              edges: .from(cycleEdges),
            ),
          );
        }

        edges.removeLast();
      }

      path.removeLast();
      recursionStack.remove(node);
    }

    for (final node in nodes.values) {
      if (visited.contains(node) == false) {
        findCircularDependencies(
          node,
          visited,
          recursionStack,
          [],
          [],
          circularFlows,
        );
      }
    }

    return circularFlows;
  }

  /// Returns cascade analysis
  List<String> getCascadeAnalysis() {
    final steps = <String>["Circular Dependencies:"];
    final circular = getCircularDependencies();

    if (circular.isEmpty) {
      steps.add("✅ No circular dependencies found");
    } else {
      for (var index = 0; index < circular.length; index++) {
        final flow = circular[index];

        final description = flow.nodes
            .map((node) => node.type.toString())
            .join(" -> ");

        final means = flow.edges.map((edge) => edge.type.toString()).join(", ");

        steps.add("${index + 1}. $description via $means");
      }
    }

    steps
      ..add("")
      ..add("Cascade Triggers:");

    final triggers = getCascadeTriggers();

    if (triggers.isEmpty) {
      steps.add("No cascade triggers found");
    } else {
      for (final trigger in triggers) {
        final flows = getCascadeFlowsFrom(trigger);

        steps.add("• $trigger -> ${flows.length} potential flows");
      }
    }

    steps
      ..add("")
      ..add("Cascade Targets:");

    final targets = getCascadeTargets();

    if (targets.isEmpty) {
      steps.add("No cascade targets found");
    } else {
      for (final target in targets) {
        steps.add("• $target");
      }
    }

    return steps;
  }

  /// Validates the cascade system and returns issues
  List<String> validateCascadeSystem() {
    final issues = <String>[];

    // Check for circular dependencies
    final circular = getCircularDependencies();

    for (final flow in circular) {
      issues.add("Circular dependency: $flow");
    }

    // Check for very deep cascades (potential performance issues)
    final summary = getCascadeSummary();

    if (summary.maxFlowDepth > 5) {
      issues.add(
        "Very deep cascade flows detected (max depth: ${summary.maxFlowDepth})",
      );
    }

    final triggers = getCascadeTriggers();

    for (final trigger in triggers) {
      final flows = getCascadeFlowsFrom(trigger);
      if (flows.length > 10) {
        issues.add(
          "Component $trigger has too many outgoing connections (${flows.length})",
        );
      }
    }

    return issues;
  }

  /// Get detailed flows for a specific component type
  List<String> getFlowsForComponent(Type componentType) {
    final steps = <String>[];
    final flows = getCascadeFlowsFrom(componentType);

    steps.add("=== FLOWS FROM $componentType ===");

    if (flows.isEmpty) {
      steps.add("No flows found from $componentType");
      return steps;
    }

    for (var i = 0; i < flows.length; i++) {
      final flow = flows[i];

      steps.add("Flow ${i + 1}:");

      if (flow.isCircular) {
        steps.add("  ⚠️  CIRCULAR DEPENDENCY");
      }

      for (var j = 0; j < flow.nodes.length; j++) {
        final node = flow.nodes[j];

        steps.add("  ${j + 1}. ${node.description}: ${node.type}");

        if (j < flow.edges.length) {
          final edge = flow.edges[j];

          steps.add("     └─ via ${edge.type}");
        }
      }

      steps.add("");
    }

    return steps;
  }

  /// Validates the cascade logic and returns issues
  List<String> validateCascadeLogic() {
    final issues = <String>[];

    // Check for circular dependencies
    final circular = getCircularDependencies();

    for (final flow in circular) {
      issues.add("Circular dependency: $flow");
    }

    // Check for very deep cascades (potential performance issues)
    final summary = getCascadeSummary();

    if (summary.maxFlowDepth > 5) {
      issues.add(
        "Very deep cascade flows detected (max depth: ${summary.maxFlowDepth})",
      );
    }

    final triggers = getCascadeTriggers();
    for (final trigger in triggers) {
      final flows = getCascadeFlowsFrom(trigger);

      if (flows.length > 10) {
        issues.add(
          "Component $trigger has too many outgoing connections (${flows.length})",
        );
      }
    }

    return issues;
  }

  /// Generates a DOT graph representation for visualization
  String generateDotGraph() {
    final buffer = StringBuffer()
      ..writeln("digraph Flow_Cascade_Flow {")
      ..writeln("  rankdir=LR;")
      ..writeln("  node [shape=box];")
      ..writeln();

    for (final node in nodes.values) {
      if (node.incoming.isEmpty && node.outgoing.isEmpty) continue;

      final String color;

      if (node.type.toString().contains("Component")) {
        color = "yellow";
      } else if (node.type.toString().contains("Event")) {
        color = "green";
      } else if ([
        "InitializeLogic",
        "ExecuteLogic",
      ].contains(node.type.toString())) {
        color = "red";
      } else {
        color = "purple";
      }

      buffer.writeln('  "${node.type}" [fillcolor=$color, style=filled];');
    }

    buffer.writeln();

    for (final edge in edges) {
      buffer.writeln('  "${edge.from.type}" -> "${edge.to.type}"');

      if (edge.type == null) {
        buffer.write(";");
      } else {
        buffer.write('[label="${edge.type}"];');
      }
    }

    buffer.writeln("}");

    return buffer.toString();
  }

  /// Simulates a cascade flow from a specific component type
  List<String> simulateCascadeFlow(Type triggerComponent) {
    final flows = getCascadeFlowsFrom(triggerComponent);
    final simulation = <String>["Simulating cascade from $triggerComponent:"];

    if (flows.isEmpty) {
      simulation.add("  No cascade flows triggered");

      return simulation;
    }

    for (var i = 0; i < flows.length; i++) {
      final flow = flows[i];

      simulation.add("  Flow ${i + 1}:");

      for (var j = 0; j < flow.edges.length; j++) {
        final edge = flow.edges[j];

        simulation
          ..add("    ${edge.from.type} triggers ${edge.type}")
          ..add("    ${edge.type} affects ${edge.to.type}");
      }

      if (flow.isCircular) {
        simulation.add("    ⚠️  This creates a circular dependency!");
      }
    }

    return simulation;
  }
}

final class FlowAnalyzer {
  FlowAnalyzer._();
  static final Map<Type, FlowNode> _nodes = {};
  static final Set<FlowEdge> _edges = {};
  static FlowAnalysis? _graph;

  static final FlowNode _executeNode = FlowNode(
    type: FlowFrameExecutionLogic,
    description: "Execute",
  );

  static final FlowNode _initializeNode = FlowNode(
    type: FlowFeatureInitializationLogic,
    description: "Initialize",
  );

  static FlowAnalysis? get graph {
    return _graph;
  }

  /// Builds the cascade graph for the Flow logic
  static FlowAnalysis analyze(
    FlowManager manager, {
    Set<Type> excludeFeatures = const {},
  }) {
    _nodes.clear();
    _nodes[_executeNode.type] = _executeNode;
    _nodes[_initializeNode.type] = _initializeNode;

    _edges.clear();

    for (final feature in manager.features) {
      if (excludeFeatures.contains(feature.runtimeType)) {
        continue;
      }

      for (final component in feature.components) {
        _createNodeForComponent(component.runtimeType);
      }
    }

    for (final feature in manager.features) {
      if (excludeFeatures.contains(feature.runtimeType)) {
        continue;
      }

      for (final entry in feature.reactiveLogics.entries) {
        final triggerType = entry.key;
        final logics = entry.value;

        for (final logic in logics) {
          _createEdgesForLogic(triggerType, logic);
        }
      }

      for (final logic in feature.initializeLogics) {
        _createNodeForInitializeLogic(logic);
      }

      for (final logic in feature.disposalLogics) {
        _createNodeForLogic(logic);
      }

      for (final logic in feature.cleanupLogics) {
        _createNodeForLogic(logic);
      }

      for (final logic in feature.executeLogics) {
        _createNodeForExecuteLogic(logic);
      }
    }

    return FlowAnalysis(
      nodes: .unmodifiable(_nodes),
      edges: .unmodifiable(_edges),
    );
  }

  static void _createNodeForComponent(Type componentType) {
    if (_nodes.containsKey(componentType)) return;

    final String description;

    if (componentType.toString().contains("Component")) {
      description = "Component";
    } else {
      description = "Event";
    }

    _nodes[componentType] = FlowNode(
      type: componentType,
      description: description,
    );
  }

  static void _createEdgesForLogic(Type triggerType, FlowReactiveLogic logic) {
    final fromNode = _nodes[triggerType];

    if (fromNode == null) return;

    for (final interactionType in logic.interactsWith) {
      _createNodeForComponent(interactionType);

      final toNode = _nodes[interactionType];

      if (toNode == null) continue;

      final edge = FlowEdge(
        from: fromNode,
        to: toNode,
        type: logic.runtimeType,
        description: logic.runtimeType.toString(),
      );

      _edges.add(edge);
      fromNode.outgoing.add(edge);
      toNode.incoming.add(edge);
    }
  }

  static void _createNodeForLogic(FlowLogic logic) {
    if (logic.interactsWith.isEmpty) return;

    final logicNode = _nodes.putIfAbsent(logic.runtimeType, () {
      return FlowNode(
        type: logic.runtimeType,
        description: logic.runtimeType.toString(),
      );
    });

    for (final type in logic.interactsWith) {
      _createNodeForComponent(type);

      final componentNode = _nodes[type];

      if (componentNode == null) continue;

      final outgoingEdge = FlowEdge(
        from: logicNode,
        to: componentNode,
      );

      _edges.add(outgoingEdge);

      logicNode.outgoing.add(outgoingEdge);
      componentNode.incoming.add(outgoingEdge);
    }
  }

  static void _createNodeForInitializeLogic(FlowFeatureInitializationLogic logic) {
    if (logic.interactsWith.isEmpty) return;

    for (final type in logic.interactsWith) {
      _createNodeForComponent(type);

      final componentNode = _nodes[type];

      if (componentNode == null) continue;

      final outgoingEdge = FlowEdge(
        from: _initializeNode,
        to: componentNode,
        type: logic.runtimeType,
      );

      _edges.add(outgoingEdge);

      _initializeNode.outgoing.add(outgoingEdge);
      componentNode.incoming.add(outgoingEdge);
    }
  }

  static void _createNodeForExecuteLogic(FlowFrameExecutionLogic logic) {
    if (logic.interactsWith.isEmpty) return;

    for (final type in logic.interactsWith) {
      _createNodeForComponent(type);

      final componentNode = _nodes[type];

      if (componentNode == null) continue;

      final outgoingEdge = FlowEdge(
        from: _executeNode,
        to: componentNode,
        type: logic.runtimeType,
      );

      _edges.add(outgoingEdge);

      _executeNode.outgoing.add(outgoingEdge);
      componentNode.incoming.add(outgoingEdge);
    }
  }
}
