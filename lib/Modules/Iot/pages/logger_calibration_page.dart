import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/metric_row.dart';

class LoggerCalibrationPage extends StatelessWidget {
  const LoggerCalibrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    InputDecoration fieldDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        isDense: true,
      );
    }

    Widget actionButtons() {
      return Row(
        children: [
          ElevatedButton(
            onPressed: () {},
            child: const Text('submit'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {},
            child: const Text('clear'),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'ADC Live Data',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('ADC Live Readings'),
                      SizedBox(height: 12),
                      MetricRow(label: 'ADC No', value: 'No data'),
                      MetricRow(label: 'Count', value: '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: DashboardCard(
                  title: 'Set Five Points Calib',
                  child: Column(
                    children: [
                      TextField(decoration: fieldDecoration('ADC No')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 0 Count')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 0 Quantity')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 1 Count')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 1 Quantity')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 2 Count')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 2 Quantity')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 3 Count')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 3 Quantity')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 4 Count')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Point 4 Quantity')),
                      const SizedBox(height: 16),
                      actionButtons(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DashboardCard(
                  title: 'Analog Output Calib',
                  child: Column(
                    children: [
                      TextField(decoration: fieldDecoration('CCR For 5V')),
                      const SizedBox(height: 16),
                      actionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'Server Connection',
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Set mf'),
                      ),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('R MF')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Y MF')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('B MF')),
                      const SizedBox(height: 16),
                      actionButtons(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: DashboardCard(
                  title: 'AC Voltage Calibration',
                  child: Column(
                    children: [
                      TextField(decoration: fieldDecoration('R Phase')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Y Phase')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('B Phase')),
                      const SizedBox(height: 16),
                      actionButtons(),
                      const SizedBox(height: 16),
                      const MetricRow(label: 'R', value: '217'),
                      const MetricRow(label: 'Y', value: '226'),
                      const MetricRow(label: 'B', value: '234'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}