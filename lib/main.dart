import 'package:flutter/material.dart';
import 'modules/iot/machine_dashboard_shell.dart';

void main() {
  runApp(const MemcoApp());
}

class MemcoApp extends StatelessWidget {
  const MemcoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MachineDashboardShell(),
    );
  }
}