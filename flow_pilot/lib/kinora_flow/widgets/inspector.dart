part of '../kinora_flow.dart';

final class FlowInspector extends StatefulWidget {
  const FlowInspector({
    super.key,
    this.refreshDelay = const Duration(milliseconds: 100),
  });
  final Duration refreshDelay;

  @override
  State<FlowInspector> createState() => _FlowInspectorState();
}

final class _FlowInspectorState extends State<FlowInspector> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    _refreshTimer = Timer.periodic(widget.refreshDelay, (timer) {
      if (mounted == false) return;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: "Summary"),
                Tab(text: "Components"),
                Tab(text: "Logs"),
              ],
            ),
            Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _SummaryView(),
                  _ComponentsView(),
                  _LogsView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SummaryView extends StatefulWidget {
  const _SummaryView();

  @override
  State<_SummaryView> createState() => _SummaryViewState();
}

final class _SummaryViewState extends State<_SummaryView> {
  @override
  Widget build(BuildContext context) {
    final manager = FlowScope.of(context);
    final analysis = FlowAnalyser.analize(manager);
    final cascade = analysis.getCascadeAnalysis();

    return ListView(
      children: [
        for (final line in cascade)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Text(line),
          ),
      ],
    );
  }
}

final class _ComponentsView extends StatefulWidget {
  const _ComponentsView();

  @override
  State<_ComponentsView> createState() => _ComponentsViewState();
}

final class _ComponentsViewState extends State<_ComponentsView> {
  String? search;
  String? type;
  String? feature;

  @override
  Widget build(BuildContext context) {
    final manager = FlowScope.of(context);
    final components = manager.components;
    final features = manager.features;

    final filtered = components.where((component) {
      if (feature != null) {
        if (component._feature.runtimeType.toString() != feature!) {
          return false;
        }
      }

      if (type != null) {
        if (type == "event") {
          if (component is! FlowEvent) {
            return false;
          }
        }
        if (type == "component") {
          if (component is! FlowState) {
            return false;
          }
        }
      }

      if (search != null && search!.isNotEmpty) {
        final searchTerm = search!.toLowerCase();
        final componentName = component.toString().toLowerCase();

        if (componentName.contains(searchTerm) == false) {
          return false;
        }
      }

      return true;
    });

    return Material(
      clipBehavior: Clip.antiAlias,
      child: Column(
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.grey.shade200,
              backgroundColor: Colors.grey.shade200,
              title: const Text("Filters"),
              childrenPadding: const EdgeInsets.all(8),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: feature,
                        decoration: const InputDecoration(
                          labelText: "Feature",
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            child: Text("Any"),
                          ),
                          for (final feature in features)
                            DropdownMenuItem(
                              value: feature.runtimeType.toString(),
                              child: Text(feature.runtimeType.toString()),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            feature = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: "Type",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            child: Text("Any"),
                          ),
                          DropdownMenuItem(
                            value: "component",
                            child: Text("Component"),
                          ),
                          DropdownMenuItem(
                            value: "event",
                            child: Text("Event"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            type = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    labelText: "Search",
                    border: const OutlineInputBorder(),
                    suffix: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          search = null;
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      search = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      "No components found",
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) {
                    return const Divider(height: 0);
                  },
                  itemBuilder: (context, index) {
                    final component = filtered.elementAt(index);

                    if (component is FlowEvent) {
                      return ExpansionTile(
                        title: Text(
                          "${component._feature.runtimeType}.${component.runtimeType}",
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [component.buildInspector(context)],
                      );
                    }

                    if (component is FlowState) {
                      return ExpansionTile(
                        title: Text(
                          "${component._feature.runtimeType}.${component.runtimeType}",
                        ),
                        childrenPadding: const EdgeInsets.all(8),
                        expandedAlignment: Alignment.centerLeft,
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          component.buildInspector(context, component.value),
                        ],
                      );
                    }

                    throw UnimplementedError(
                      "Unknown component type: ${component.runtimeType}",
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final class _LogsView extends StatefulWidget {
  const _LogsView();

  @override
  State<_LogsView> createState() => _LogsViewState();
}

final class _LogsViewState extends State<_LogsView> {
  String? search;
  FlowLogLevel? level;

  @override
  Widget build(BuildContext context) {
    final entries = FlowLogger.entries.reversed;

    final filtered = entries.where((entry) {
      if (level != null) {
        if (entry.level != level) {
          return false;
        }
      }

      if (search != null) {
        final searchTerm = search!.toLowerCase();
        final description = entry.description.toLowerCase();
        if (description.contains(searchTerm) == false) {
          return false;
        }
      }

      return true;
    });

    return Material(
      clipBehavior: Clip.antiAlias,
      child: Column(
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.grey.shade200,
              backgroundColor: Colors.grey.shade200,
              title: const Text("Logs Info"),
              childrenPadding: const EdgeInsets.all(8),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        initialValue: level,
                        decoration: const InputDecoration(
                          labelText: "Level",
                          border: OutlineInputBorder(),
                        ),
                        items: FlowLogLevel.values.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            level = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          minimumSize: const Size.fromHeight(55),
                        ),
                        onPressed: () {
                          setState(FlowLogger.clear);
                        },
                        child: const Text("Clear Logs"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    labelText: "Search",
                    border: const OutlineInputBorder(),
                    suffix: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          search = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text("No logs found"),
                  );
                }

                return ListView.separated(
                  reverse: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final log = filtered.elementAt(index);
                    return ExpansionTile(
                      title: Text("${log.level.name.toUpperCase()} - ${log.time}"),
                      subtitle: Text(log.description),
                      childrenPadding: const EdgeInsets.all(8),
                      children: [
                        const Row(
                          children: [
                            Text("Call Stack:"),
                          ],
                        ),
                        SelectableText(log.stack.toString()),
                      ],
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const Divider(height: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
