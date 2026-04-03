import 'package:flutter/material.dart';
import 'pages/machine_fleet_overview_page.dart';
import 'pages/machine_overview_page.dart';
import 'pages/machine_production_page.dart';
import 'pages/machine_engineering_page.dart';
import 'pages/logger_calibration_page.dart';

class MachineDashboardShell extends StatefulWidget {
  const MachineDashboardShell({super.key});

  @override
  State<MachineDashboardShell> createState() => _MachineDashboardShellState();
}

class _MachineDashboardShellState extends State<MachineDashboardShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    MachineFleetOverviewPage(),
    MachineOverviewPage(),
    MachineProductionPage(),
    MachineEngineeringPage(),
    LoggerCalibrationPage(),
  ];

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Machine Fleet Overview';
      case 1:
        return 'Machine Overview';
      case 2:
        return 'Machine Production';
      case 3:
        return 'Machine Engineering Data';
      case 4:
        return 'Logger Calibration';
      default:
        return 'MEMCO Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (value) {
              setState(() {
                _selectedIndex = value;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: Text('Fleet'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.factory_outlined),
                selectedIcon: Icon(Icons.factory),
                label: Text('Production'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Engineering'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: Text('Calibration'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Text(
                    _titleForIndex(_selectedIndex),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}