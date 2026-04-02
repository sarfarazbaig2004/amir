import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/metric_row.dart';
import '../helpers/responsive.dart';

class MachineProductionPage extends StatelessWidget {
  const MachineProductionPage({super.key});

  static const double _pagePadding = 16;
  static const double _gap = 16;
  static const double _maxWidth = 1400;

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
          const MetricRow(label: 'Arcing Time', value: '0:49:20'),
          const MetricRow(label: 'Idle Time', value: '0:9:20'),
          const MetricRow(label: 'DC Energy', value: '2.27'),
          const MetricRow(label: 'Deposition', value: '7.82'),
          const MetricRow(label: 'Wire Feed Meter', value: '0'),
          const MetricRow(label: 'No Of Arcs', value: '27'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showResetDialog(
                context,
                title: 'Reset Job Data',
                message:
                    'Are you sure you want to reset current job production data?',
                successText: 'Job data reset action triggered',
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
          const MetricRow(label: 'Arcing Time', value: '4:55:29'),
          const MetricRow(label: 'Idle Time', value: '3:23:50'),
          const MetricRow(label: 'DC Energy', value: '2.67'),
          const MetricRow(label: 'Deposition', value: '9.2'),
          const MetricRow(label: 'Wire Feed Meter', value: '0'),
          const MetricRow(label: 'No Of Arcs', value: '58'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showResetDialog(
                context,
                title: 'Reset Machine Lifetime Data',
                message:
                    'This should usually be allowed only for admin or service engineer. Do you want to continue?',
                successText: 'Machine lifetime reset action triggered',
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