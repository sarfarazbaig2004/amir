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
      backgroundColor: const Color(0xFFF5F8FC),
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 120,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: NavigationRail(
                leading: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: const [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF0F172A),
                        child: Icon(
                          Icons.wifi_tethering,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'MEMCO',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: Color(0xFF22C55E)),
                        SizedBox(width: 8),
                        Text(
                          'Live',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    _selectedIndex = value;
                  });
                },
                backgroundColor: const Color(0xFFF8FAFC),
                labelType: NavigationRailLabelType.all,
                minWidth: 96,
                groupAlignment: -0.95,
                indicatorColor: const Color(0xFFCBD5E1),
                selectedIconTheme: const IconThemeData(
                  color: Color(0xFF0F172A),
                  size: 28,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: Color(0xFF64748B),
                  size: 24,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
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
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
