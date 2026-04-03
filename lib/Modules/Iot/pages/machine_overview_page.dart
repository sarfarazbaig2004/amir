import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/metric_row.dart';
import '../helpers/responsive.dart';
import '../services/machine_service.dart';

class MachineOverviewPage extends StatefulWidget {
  const MachineOverviewPage({super.key});

  @override
  State<MachineOverviewPage> createState() => _MachineOverviewPageState();
}

class _MachineOverviewPageState extends State<MachineOverviewPage> {
  static const double _desktopMaxWidth = 1400;
  static const double _pagePadding = 16;
  static const double _gap = 16;

  Map<String, dynamic>? overviewData;
  bool isLoading = true;
  String errorMessage = '';
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOverview();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadOverview(showLoader: false);
    });
  }

  Future<void> _loadOverview({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final data = await MachineService.fetchOverview();

      if (!mounted) return;

      setState(() {
        overviewData = data;
        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && overviewData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty && overviewData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (Responsive.isDesktop(context)) {
      return _buildDesktop(context);
    } else if (Responsive.isTablet(context)) {
      return _buildTablet(context);
    } else {
      return _buildMobile(context);
    }
  }

  Widget _buildDesktop(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _desktopMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_pagePadding),
          child: Column(
            children: [
              _buildTopSummary(context, isMobile: false),
              const SizedBox(height: _gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildWeldingCard(context),
                        const SizedBox(height: _gap),
                        _buildTemperatureCard(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: Column(
                      children: [
                        _buildInputPowerCard(context),
                        const SizedBox(height: _gap),
                        _buildWelderRfidCard(context),
                        const SizedBox(height: _gap),
                        _buildAcVoltageTrendCard(context),
                        const SizedBox(height: _gap),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildAlarmsCard(context)),
                            const SizedBox(width: _gap),
                            Expanded(child: _buildWarningsCard(context)),
                          ],
                        ),
                      ],
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

  Widget _buildTablet(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_pagePadding),
          child: Column(
            children: [
              _buildTopSummary(context, isMobile: false),
              const SizedBox(height: _gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildWeldingCard(context)),
                  const SizedBox(width: _gap),
                  Expanded(child: _buildInputPowerCard(context)),
                ],
              ),
              const SizedBox(height: _gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTemperatureCard(context)),
                  const SizedBox(width: _gap),
                  Expanded(child: _buildWelderRfidCard(context)),
                ],
              ),
              const SizedBox(height: _gap),
              _buildAcVoltageTrendCard(context),
              const SizedBox(height: _gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildAlarmsCard(context)),
                  const SizedBox(width: _gap),
                  Expanded(child: _buildWarningsCard(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildTopSummary(context, isMobile: true),
              const SizedBox(height: 12),
              _buildWeldingCard(context),
              const SizedBox(height: 12),
              _buildInputPowerCard(context),
              const SizedBox(height: 12),
              _buildTemperatureCard(context),
              const SizedBox(height: 12),
              _buildWelderRfidCard(context),
              const SizedBox(height: 12),
              _buildAcVoltageTrendCard(context),
              const SizedBox(height: 12),
              _buildAlarmsCard(context),
              const SizedBox(height: 12),
              _buildWarningsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSummary(BuildContext context, {required bool isMobile}) {
    final status = _stringValue('status', '-');
    final health = _stringValue('health', 'GREEN');
    final alarmCount = _stringValue('alarmCount', '0');
    final warningCount = _stringValue('warningCount', '0');
    final updatedAt = _stringValue('lastUpdatedAt', '-');

    final statusColor = _getStatusColor(status);
    final healthColor = _getHealthColor(health);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MEMCO Machine Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Machine: ARC400   |   Company: MEMCO',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip(status, statusColor),
                    _circle(health, healthColor),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Alarm Count: $alarmCount',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Warning Count: $warningCount',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text('Live • $updatedAt'),
              ],
            )
          : Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEMCO Machine Overview',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Machine: ARC400   |   Company: MEMCO',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                _chip(status, statusColor),
                const SizedBox(width: 12),
                _circle(health, healthColor),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alarm Count: $alarmCount',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Warning Count: $warningCount',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text('Live • $updatedAt'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildWeldingCard(BuildContext context) {
    return DashboardCard(
      title: 'Welding Data',
      child: Column(
        children: [
          MetricRow(
            label: 'Welding Current',
            value: '${_numValue('weldingCurrent').toStringAsFixed(1)} A',
          ),
          MetricRow(
            label: 'Welding Voltage',
            value: '${_numValue('weldingVoltage').toStringAsFixed(1)} V',
          ),
          MetricRow(
            label: 'Current Setting',
            value: '${_numValue('currentSetting').round()} A',
          ),
          MetricRow(
            label: 'Fan Speed',
            value: '${_numValue('fanSpeed').round()} RPM',
          ),
          const SizedBox(height: 12),
          _fakeChartBox(title: 'Current / Voltage Trend', height: 180),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Set current clicked')),
                    );
                  },
                  child: const Text('Set Current'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset welding data clicked')),
                    );
                  },
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputPowerCard(BuildContext context) {
    final inputVoltage =
        (overviewData?['inputVoltage'] as Map<String, dynamic>?) ?? {};

    return DashboardCard(
      title: 'Input Power Supply',
      child: Column(
        children: [
          MetricRow(
            label: 'In Voltage R',
            value: '${(inputVoltage['R'] ?? 0).round()} V',
          ),
          MetricRow(
            label: 'In Voltage Y',
            value: '${(inputVoltage['Y'] ?? 0).round()} V',
          ),
          MetricRow(
            label: 'In Voltage B',
            value: '${(inputVoltage['B'] ?? 0).round()} V',
          ),
          const MetricRow(label: 'Heartbeat', value: 'OK'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniGauge(
                  label: 'R Voltage',
                  value: (inputVoltage['R'] ?? 0).round().toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniGauge(
                  label: 'Y Voltage',
                  value: (inputVoltage['Y'] ?? 0).round().toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniGauge(
                  label: 'B Voltage',
                  value: (inputVoltage['B'] ?? 0).round().toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(BuildContext context) {
    final temperature =
        (overviewData?['temperature'] as Map<String, dynamic>?) ?? {};

    return DashboardCard(
      title: 'Temperature',
      child: Column(
        children: [
          MetricRow(
            label: 'Trafo Core Temperature',
            value:
                '${((temperature['trafoCore'] ?? 0) as num).toStringAsFixed(1)} °C',
          ),
          MetricRow(
            label: 'IGBT Temperature',
            value:
                '${((temperature['igbt'] ?? 0) as num).toStringAsFixed(1)} °C',
          ),
          MetricRow(
            label: 'Heat Sync Temp.',
            value:
                '${((temperature['heatSync'] ?? 0) as num).toStringAsFixed(1)} °C',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniGauge(
                  label: 'Trafo',
                  value:
                      ((temperature['trafoCore'] ?? 0) as num).toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniGauge(
                  label: 'IGBT',
                  value: ((temperature['igbt'] ?? 0) as num).toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniGauge(
                  label: 'Heat Sync',
                  value:
                      ((temperature['heatSync'] ?? 0) as num).toStringAsFixed(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Set temperature clicked')),
                    );
                  },
                  child: const Text('Set Temperature'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset temperature data clicked'),
                      ),
                    );
                  },
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelderRfidCard(BuildContext context) {
    return DashboardCard(
      title: 'Welder Identification (RFID)',
      child: Column(
        children: [
          const MetricRow(label: 'RFID Card', value: 'RFID-000127'),
          const MetricRow(label: 'Welder Name', value: 'Mohd. Arif'),
          const MetricRow(label: 'Employee Code', value: 'WLD-019'),
          const MetricRow(label: 'Shift', value: 'A'),
          const MetricRow(label: 'Authorization', value: 'Active'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assign RFID clicked')),
                    );
                  },
                  child: const Text('Assign RFID'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clear welder session clicked')),
                    );
                  },
                  child: const Text('Clear Session'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcVoltageTrendCard(BuildContext context) {
    return DashboardCard(
      title: 'AC Voltage Trend',
      child: Column(
        children: [
          _fakeChartBox(title: 'R / Y / B Phase Trend', height: 220),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voltage threshold clicked')),
                    );
                  },
                  child: const Text('Set Voltage Limit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset voltage trend clicked')),
                    );
                  },
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmsCard(BuildContext context) {
    final alarms = (overviewData?['alarms'] as List<dynamic>?) ?? [];

    return DashboardCard(
      title: 'Alarms',
      child: Column(
        children: [
          _StatusRow(
            label: 'OVERHEAT',
            color: alarms.contains('OVERHEAT') ? Colors.red : Colors.green,
          ),
          _StatusRow(
            label: 'HIGH_VOLTAGE',
            color: alarms.contains('HIGH_VOLTAGE') ? Colors.red : Colors.green,
          ),
          _StatusRow(
            label: 'OVER_CURRENT',
            color: alarms.contains('OVER_CURRENT') ? Colors.red : Colors.green,
          ),
          const _StatusRow(label: 'Fan Speed', color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildWarningsCard(BuildContext context) {
    final warnings = (overviewData?['warnings'] as List<dynamic>?) ?? [];

    return DashboardCard(
      title: 'Warnings',
      child: Column(
        children: [
          _StatusRow(
            label: 'TEMP_WARNING',
            color: warnings.contains('TEMP_WARNING')
                ? Colors.orange
                : Colors.green,
          ),
          _StatusRow(
            label: 'VOLTAGE_WARNING',
            color: warnings.contains('VOLTAGE_WARNING')
                ? Colors.orange
                : Colors.green,
          ),
          const _StatusRow(label: 'Dust Collector Sensor', color: Colors.green),
        ],
      ),
    );
  }

  Widget _fakeChartBox({
    required String title,
    required double height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _stringValue(String key, String fallback) {
    final value = overviewData?[key];
    return value == null ? fallback : value.toString();
  }

  num _numValue(String key) {
    final value = overviewData?[key];
    if (value is num) return value;
    return 0;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WELDING':
        return Colors.green;
      case 'IDLE':
        return Colors.blue;
      case 'OFF':
      default:
        return Colors.grey;
    }
  }

  Color _getHealthColor(String health) {
    switch (health.toUpperCase()) {
      case 'RED':
        return Colors.red;
      case 'YELLOW':
        return Colors.orange;
      case 'GREEN':
      default:
        return Colors.green;
    }
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _circle(String text, Color color) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniGauge extends StatelessWidget {
  final String label;
  final String value;

  const _MiniGauge({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green, width: 6),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}