import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/metric_row.dart';
import '../helpers/responsive.dart';

class MachineProductionPage extends StatefulWidget {
  const MachineProductionPage({super.key});

  @override
  State<MachineProductionPage> createState() => _MachineProductionPageState();
}

class _MachineProductionPageState extends State<MachineProductionPage> {
  final Map<String, String> _runningJobMetrics = {
    'Arcing Time': '0:49:20',
    'Idle Time': '0:9:20',
    'DC Energy': '2.27',
    'Deposition': '7.82',
    'Wire Feed Meter': '0',
    'No Of Arcs': '27',
  };

  final Map<String, String> _lifetimeMetrics = {
    'Arcing Time': '4:55:29',
    'Idle Time': '3:23:50',
    'DC Energy': '2.67',
    'Deposition': '9.2',
    'Wire Feed Meter': '0',
    'No Of Arcs': '58',
  };

  static const double _pagePadding = 16;
  static const double _gap = 16;
  static const double _maxWidth = 1400;

  void _resetRunningJobMetrics() {
    setState(() {
      _runningJobMetrics
        ..['Arcing Time'] = '0:00:00'
        ..['Idle Time'] = '0:00:00'
        ..['DC Energy'] = '0'
        ..['Deposition'] = '0'
        ..['Wire Feed Meter'] = '0'
        ..['No Of Arcs'] = '0';
    });
  }

  void _resetLifetimeMetrics() {
    setState(() {
      _lifetimeMetrics
        ..['Arcing Time'] = '0:00:00'
        ..['Idle Time'] = '0:00:00'
        ..['DC Energy'] = '0'
        ..['Deposition'] = '0'
        ..['Wire Feed Meter'] = '0'
        ..['No Of Arcs'] = '0';
    });
  }

  @override
  Widget build(BuildContext context) {
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
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_pagePadding),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRunningJobCard(context)),
                  const SizedBox(width: _gap),
                  Expanded(child: _buildLifetimeCard(context)),
                ],
              ),
              const SizedBox(height: _gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTemperatureCard()),
                  const SizedBox(width: _gap),
                  Expanded(child: _buildAcVoltageCard()),
                ],
              ),
              const SizedBox(height: _gap),
              _buildMachineLiveDataCard(),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRunningJobCard(context)),
                  const SizedBox(width: _gap),
                  Expanded(child: _buildLifetimeCard(context)),
                ],
              ),
              const SizedBox(height: _gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTemperatureCard()),
                  const SizedBox(width: _gap),
                  Expanded(child: _buildAcVoltageCard()),
                ],
              ),
              const SizedBox(height: _gap),
              _buildMachineLiveDataCard(),
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
              _buildRunningJobCard(context),
              const SizedBox(height: 12),
              _buildLifetimeCard(context),
              const SizedBox(height: 12),
              _buildTemperatureCard(),
              const SizedBox(height: 12),
              _buildAcVoltageCard(),
              const SizedBox(height: 12),
              _buildMachineLiveDataCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunningJobCard(BuildContext context) {
    return DashboardCard(
      title: 'Running Job',
      child: Column(
        children: [
          ..._runningJobMetrics.entries.map(
            (metric) => MetricRow(label: metric.key, value: metric.value),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showResetDialog(
                context,
                title: 'Reset Job Data',
                message:
                    'Are you sure you want to reset current job production data?',
                successText: 'Job data reset',
                onConfirm: _resetRunningJobMetrics,
              ),
              child: const Text('Reset Job Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimeCard(BuildContext context) {
    return DashboardCard(
      title: 'Machine Lifetime',
      child: Column(
        children: [
          ..._lifetimeMetrics.entries.map(
            (metric) => MetricRow(label: metric.key, value: metric.value),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showResetDialog(
                context,
                title: 'Reset Machine Lifetime Data',
                message:
                    'This should usually be allowed only for admin or service engineer. Do you want to continue?',
                successText: 'Machine lifetime data reset',
                onConfirm: _resetLifetimeMetrics,
              ),
              child: const Text('Reset Machine Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard() {
    return DashboardCard(
      title: 'Temperature Data',
      child: Column(
        children: const [
          MetricRow(label: 'Temperature 1', value: '36.7 °C'),
          MetricRow(label: 'Temperature 2', value: '41.73 °C'),
          MetricRow(label: 'Temperature 3', value: '40.55 °C'),
        ],
      ),
    );
  }

  Widget _buildAcVoltageCard() {
    return DashboardCard(
      title: 'AC Voltage',
      child: Column(
        children: const [
          MetricRow(label: 'R phase Voltage', value: '217 V'),
          MetricRow(label: 'Y phase Voltage', value: '228 V'),
          MetricRow(label: 'B phase Voltage', value: '235 V'),
        ],
      ),
    );
  }

  Widget _buildMachineLiveDataCard() {
    return DashboardCard(
      title: 'Machine Live Data',
      child: Column(
        children: const [
          MetricRow(label: 'Welding Current', value: '1.17 A'),
          MetricRow(label: 'Welding Voltage', value: '95.4 V'),
          MetricRow(label: 'Current set by Knob', value: '401 A'),
        ],
      ),
    );
  }

  void _showResetDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String successText,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(successText)),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
