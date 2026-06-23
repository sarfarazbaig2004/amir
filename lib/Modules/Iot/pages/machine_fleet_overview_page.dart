import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/app_config.dart';
import '../services/machine_service.dart';
import 'machine_overview_page.dart';

class MachineFleetOverviewPage extends StatefulWidget {
  const MachineFleetOverviewPage({
    super.key,
    this.allowedMachineCodes,
    this.allowedMachineIds,
    this.onMachineSelected,
  });

  final Set<String>? allowedMachineCodes;
  final Set<int>? allowedMachineIds;
  final ValueChanged<String>? onMachineSelected;

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
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    fetchData();

    timer = Timer.periodic(const Duration(seconds: 5), (_) {
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
    if (_isFetching) return;
    _isFetching = true;

    try {
      final data = await MachineService.getFleetOverview();
      if (!mounted) return;

      final sortedMachines = List<Map<String, dynamic>>.from(
        data,
      ).where(_isMachineAllowed).toList();

      sortedMachines.sort((a, b) {
        const priority = {'RED': 0, 'YELLOW': 1, 'GREEN': 2};

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
    } finally {
      _isFetching = false;
    }
  }

  Color getHealthColor(String health) {
    final normalized = health.trim().toUpperCase();
    switch (normalized) {
      case 'RED':
        return Colors.red.shade700;
      case 'YELLOW':
        return Colors.orange.shade700;
      case 'GREEN':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  bool _isMachineAllowed(Map<String, dynamic> machine) {
    final allowedMachineCodes = widget.allowedMachineCodes;
    final allowedMachineIds = widget.allowedMachineIds;
    if (allowedMachineCodes == null && allowedMachineIds == null) {
      return true;
    }

    final rawId = machine['id'] ?? machine['machineId'];
    final machineId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');
    if (allowedMachineIds != null &&
        allowedMachineIds.isNotEmpty &&
        machineId != null) {
      return allowedMachineIds.contains(machineId);
    }

    final code = (machine['code'] ?? machine['machineCode'] ?? '').toString();
    return allowedMachineCodes?.contains(code) ?? false;
  }

  Color getStatusColor(String status) {
    final normalized = status.trim().toUpperCase();
    switch (normalized) {
      case 'WELDING':
        return Colors.orange.shade700;
      case 'IDLE':
        return Colors.blue.shade700;
      case 'OFF':
        return Colors.grey.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color getCardBorderColor(String health) {
    final normalized = health.trim().toUpperCase();
    switch (normalized) {
      case 'RED':
        return Colors.red.shade200;
      case 'YELLOW':
        return Colors.amber.shade200;
      case 'GREEN':
        return Colors.green.shade200;
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color getCardBackground(String health) {
    final normalized = health.trim().toUpperCase();
    switch (normalized) {
      case 'RED':
        return const Color(0xFFFFF1F0);
      case 'YELLOW':
        return const Color(0xFFFFFBEB);
      case 'GREEN':
        return const Color(0xFFF5FFFA);
      default:
        return Colors.white;
    }
  }

  Widget buildHealthPill(String health) {
    final normalized = health.trim().toUpperCase();
    final color = getHealthColor(normalized);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildSummaryChip(
    String label,
    String value, {
    Color background = const Color(0xFFF8FAFC),
  }) {
    return Container(
      width: 232,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final redCount = machines
        .where(
          (m) => (m['health'] ?? 'GREEN').toString().toUpperCase() == 'RED',
        )
        .length;
    final yellowCount = machines
        .where(
          (m) => (m['health'] ?? 'GREEN').toString().toUpperCase() == 'YELLOW',
        )
        .length;
    final greenCount = machines
        .where(
          (m) => (m['health'] ?? 'GREEN').toString().toUpperCase() == 'GREEN',
        )
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Machine Fleet Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Live overview of welding machine fleet health, status, and priority alerts.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildSummaryChip('Total machines', '${machines.length}'),
                    _buildSummaryChip(
                      'Healthy',
                      '$greenCount',
                      background: const Color(0xFFF5FFFA),
                    ),
                    _buildSummaryChip(
                      'Warning',
                      '$yellowCount',
                      background: const Color(0xFFFFFBEB),
                    ),
                    _buildSummaryChip(
                      'Critical',
                      '$redCount',
                      background: const Color(0xFFFFF1F0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 28,
            runSpacing: 28,
            alignment: WrapAlignment.start,
            children: machines.isEmpty
                ? [_buildNoMachineAccessCard()]
                : machines.map((machine) {
                    return _buildMachineCard(context, machine);
                  }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMachineAccessCard() {
    return Container(
      width: 520,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'No machines are enabled for this customer.',
        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildMachineCard(BuildContext context, Map<String, dynamic> machine) {
    final machineCode = (machine['code'] ?? AppConfig.defaultMachineId)
        .toString();
    final selectedMachineId = _selectedMachineIdFor(machine);
    final health = (machine['health'] ?? 'GREEN').toString();
    final status = (machine['status'] ?? '-').toString();
    final isWelding = status.trim().toUpperCase() == 'WELDING';
    final current = isWelding ? _toNum(machine['current']) : 0;
    final voltage = isWelding ? _toNum(machine['voltage']) : 0;
    final statusColor = getStatusColor(status);
    final cardBackground = getCardBackground(health);
    final borderColor = getCardBorderColor(health);

    return GestureDetector(
      onTap: () => _openMachine(context, selectedMachineId),
      child: SizedBox(
        width: 340,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 34,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      machineCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                  ),
                  buildHealthPill(health),
                ],
              ),
              const SizedBox(height: 16),
              _buildMachineDetailRow('Status', status, valueColor: statusColor),
              _buildMachineDetailRow(
                'Serial',
                (machine['serialNumber'] ?? '').toString(),
              ),
              _buildMachineDetailRow(
                'Location',
                (machine['location'] ?? '').toString(),
              ),
              _buildMachineDetailRow(
                'Current',
                '${current.toStringAsFixed(0)} A',
                valueColor: const Color(0xFF111827),
              ),
              _buildMachineDetailRow(
                'Voltage',
                '${voltage.toStringAsFixed(0)} V',
                valueColor: const Color(0xFF111827),
              ),
              _buildMachineDetailRow(
                'Temp',
                '${(machine['temperature'] ?? 0).round()} °C',
                valueColor: const Color(0xFF111827),
              ),
              _buildMachineDetailRow(
                'Welder',
                (machine['welder'] ?? 'Unknown').toString(),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE5E7EB), height: 1),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: buildStatusBadge(status)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _openMachine(context, selectedMachineId),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Open Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _selectedMachineIdFor(Map<String, dynamic> machine) {
    final code = (machine['code'] ?? machine['machineCode'] ?? '').toString();
    if (code.trim().isNotEmpty) {
      return code;
    }

    final id = machine['id'] ?? machine['machineId'];
    final idText = id?.toString() ?? '';
    return idText.trim().isNotEmpty ? idText : AppConfig.defaultMachineId;
  }

  void _openMachine(BuildContext context, String machineId) {
    final onMachineSelected = widget.onMachineSelected;
    if (onMachineSelected != null) {
      onMachineSelected(machineId);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MachineOverviewPage(machineId: machineId),
      ),
    );
  }

  Widget _buildMachineDetailRow(
    String label,
    String value, {
    Color valueColor = const Color(0xFF374151),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
