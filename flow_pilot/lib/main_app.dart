import 'dart:developer';

import 'package:flutter/material.dart';

final class MainApp extends StatelessWidget {
  const MainApp(this.snapshot, {super.key});

  final AsyncSnapshot<void> snapshot;

  @override
  Widget build(BuildContext context) {
    log("🏗️  $runtimeType (${snapshot.connectionState})");

    return const MaterialApp(
      home: Scaffold(body: Center(child: Text("Main App"))),
    );
  }
}
