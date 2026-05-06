import 'package:flutter/material.dart';
import 'models/auth_user.dart';
import 'models/customer_access.dart';
import 'pages/customer_arcing_report_page.dart';
import 'pages/customer_access_control_page.dart';
import 'pages/machine_fleet_overview_page.dart';
import 'pages/machine_overview_page.dart';
import 'pages/machine_production_page.dart';
import 'pages/machine_engineering_page.dart';
import 'pages/logger_calibration_page.dart';
import 'services/customer_access_service.dart';

class MachineDashboardShell extends StatefulWidget {
  const MachineDashboardShell({
    super.key,
    required this.user,
    required this.onLogout,
    this.access,
  });

  final AuthUser user;
  final VoidCallback onLogout;
  final CustomerAccess? access;

  @override
  State<MachineDashboardShell> createState() => _MachineDashboardShellState();
}

class _MachineDashboardShellState extends State<MachineDashboardShell> {
  int _selectedIndex = 0;

  List<_NavItem> get _items {
    if (widget.user.isCustomer) {
      final access =
          widget.access ??
          CustomerAccessService.accessForEmail(widget.user.email);
      return _customerItems(access);
    }

    return const [
      _NavItem(
        title: 'Machine Fleet Overview',
        label: 'Fleet',
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view,
        page: MachineFleetOverviewPage(),
      ),
      _NavItem(
        title: 'Machine Overview',
        label: 'Overview',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        page: MachineOverviewPage(),
      ),
      _NavItem(
        title: 'Machine Production',
        label: 'Production',
        icon: Icons.factory_outlined,
        selectedIcon: Icons.factory,
        page: MachineProductionPage(),
      ),
      _NavItem(
        title: 'Machine Engineering Data',
        label: 'Engineering',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        page: MachineEngineeringPage(),
      ),
      _NavItem(
        title: 'Logger Calibration',
        label: 'Calibration',
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune,
        page: LoggerCalibrationPage(),
      ),
      _NavItem(
        title: 'Customer Access Control',
        label: 'Access',
        icon: Icons.admin_panel_settings_outlined,
        selectedIcon: Icons.admin_panel_settings,
        page: CustomerAccessControlPage(),
      ),
    ];
  }

  List<_NavItem> _customerItems(CustomerAccess access) {
    final items = <_NavItem>[];

    if (access.hasModule('reports')) {
      items.add(
        _NavItem(
          title: 'Customer Arcing Report',
          label: 'Reports',
          icon: Icons.assessment_outlined,
          selectedIcon: Icons.assessment,
          page: CustomerArcingReportPage(
            allowedMachineCodes: access.allMachines
                ? null
                : access.allowedMachineCodes,
            allowedMachineIds: access.allMachines
                ? null
                : access.allowedMachineIds,
          ),
        ),
      );
    }

    if (access.hasModule('fleet')) {
      items.add(
        _NavItem(
          title: 'Machine Fleet Overview',
          label: 'Fleet',
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view,
          page: MachineFleetOverviewPage(
            allowedMachineCodes: access.allMachines
                ? null
                : access.allowedMachineCodes,
          ),
        ),
      );
    }

    if (access.hasModule('overview')) {
      items.add(
        _NavItem(
          title: 'Machine Overview',
          label: 'Overview',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          page: MachineOverviewPage(
            machineId: access.allowedMachineCodes.isEmpty
                ? null
                : access.allowedMachineCodes.first,
            access: access,
          ),
        ),
      );
    }

    if (access.hasModule('production')) {
      items.add(
        _NavItem(
          title: 'Machine Production',
          label: 'Production',
          icon: Icons.factory_outlined,
          selectedIcon: Icons.factory,
          page: MachineProductionPage(
            machineId: access.allowedMachineCodes.isEmpty
                ? null
                : access.allowedMachineCodes.first,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _NavItem(
          title: 'No Access',
          label: 'Access',
          icon: Icons.lock_outline,
          selectedIcon: Icons.lock,
          page: _NoAccessPage(),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CustomerAccessService.version,
      builder: (context, _, __) {
        return _buildShell(context);
      },
    );
  }

  Widget _buildShell(BuildContext context) {
    final items = _items;
    final selectedIndex = _selectedIndex.clamp(0, items.length - 1);

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
                        'QUIK IoT | MEMCO',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 10,
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
                selectedIndex: selectedIndex,
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
                destinations: items
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            items[selectedIndex].title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              widget.user.role,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton.icon(
                          onPressed: widget.onLogout,
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Logout'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: items[selectedIndex].page),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAccessPage extends StatelessWidget {
  const _NoAccessPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No modules are enabled for this customer.',
        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.title,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String title;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}
