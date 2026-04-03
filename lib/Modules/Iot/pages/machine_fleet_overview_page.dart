import 'dart:async';
import 'package:flutter/material.dart';
import '../services/machine_service.dart';
import 'machine_overview_page.dart';

class MachineFleetOverviewPage extends StatefulWidget {
  const MachineFleetOverviewPage({super.key});

  @override
  State<MachineFleetOverviewPage> createState() =>
      _MachineFleetOverviewPageState();
}

class _MachineFleetOverviewPageState extends State<MachineFleetOverviewPage> {
  List machines = [];
  bool isLoading = true;
  Timer? timer;
  Timer? blinkTimer;
  bool isBlinkOn = true;

  @override
  void initState() {
    super.initState();
    fetchData();

    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchData();
    });

    blinkTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() {
        isBlinkOn = !isBlinkOn;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    blinkTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final data = await MachineService.fetchFleet();
      if (!mounted) return;

      final sortedMachines = List<Map<String, dynamic>>.from(data);

      sortedMachines.sort((a, b) {
        const priority = {
          'RED': 0,
          'YELLOW': 1,
          'GREEN': 2,
        };

        final aHealth = (a['health'] ?? 'GREEN').toString().toUpperCase();
        final bHealth = (b['health'] ?? 'GREEN').toString().toUpperCase();

        return (priority[aHealth] ?? 99).compareTo(priority[bHealth] ?? 99);
      });

      setState(() {
        machines = sortedMachines;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Fleet fetch error: $e');
    }
  }

  Color getHealthColor(String health) {
    switch (health.toUpperCase()) {
      case 'RED':
        return Colors.red;
      case 'YELLOW':
        return Colors.orange;
      case 'GREEN':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WELDING':
        return Colors.green;
      case 'IDLE':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color getCardBackground(String health) {
    switch (health.toUpperCase()) {
      case 'RED':
        return Colors.red.withOpacity(0.05);
      case 'YELLOW':
        return Colors.orange.withOpacity(0.04);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Machine Fleet Overview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Machines: ${machines.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: machines.map((m) {
              final health = (m['health'] ?? 'GREEN').toString();
              final status = (m['status'] ?? 'IDLE').toString();
              final healthColor = getHealthColor(health);
              final statusColor = getStatusColor(status);
              final isRed = health.toUpperCase() == 'RED';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MachineOverviewPage(),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getCardBackground(health),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRed
                          ? (isBlinkOn ? Colors.red : Colors.red.shade200)
                          : healthColor,
                      width: isRed ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isRed
                            ? Colors.red.withOpacity(0.15)
                            : Colors.black12,
                        blurRadius: isRed ? 12 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (m['code'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _row(context, 'Status', status),
                      _row(context, 'Health', health),
                      _row(context, 'Serial', (m['serialNumber'] ?? '').toString()),
                      _row(context, 'Location', (m['location'] ?? '').toString()),
                      _row(context, 'Current', '${(m['current'] ?? 0).round()} A'),
                      _row(context, 'Temp', '${(m['temperature'] ?? 0).round()} °C'),
                      _row(context, 'Welder', (m['welder'] ?? 'Unknown').toString()),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MachineOverviewPage(),
                              ),
                            );
                          },
                          child: const Text('Open Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}