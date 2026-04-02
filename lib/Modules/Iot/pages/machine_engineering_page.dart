import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';

class MachineEngineeringPage extends StatelessWidget {
  const MachineEngineeringPage({super.key});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DashboardCard(
              title: 'Set Date and Time',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STM time    8/15/2025, 4:30:39 PM'),
                  const SizedBox(height: 16),
                  TextField(decoration: fieldDecoration('dd/mm/yyyy')),
                  const SizedBox(height: 12),
                  TextField(decoration: fieldDecoration('--:--')),
                  const SizedBox(height: 16),
                  actionButtons(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Read All Set Points'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DashboardCard(
              title: 'AC Voltage Thresholds',
              child: Column(
                children: [
                  TextField(decoration: fieldDecoration('AC Low')),
                  const SizedBox(height: 12),
                  TextField(decoration: fieldDecoration('AC Low Low')),
                  const SizedBox(height: 12),
                  TextField(decoration: fieldDecoration('AC High')),
                  const SizedBox(height: 12),
                  TextField(decoration: fieldDecoration('AC High High')),
                  const SizedBox(height: 16),
                  actionButtons(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DashboardCard(
              title: 'Temperature Thresholds',
              child: Column(
                children: [
                  TextField(decoration: fieldDecoration('Temp 1 H')),
                  const SizedBox(height: 12),
                  TextField(decoration: fieldDecoration('Temp 1 HH')),
                  const SizedBox(height: 12),
                  TextField(decoration: fieldDecoration('Temp 2 H')),
                  const SizedBox(height: 12),
                  TextField(decoration: fieldDecoration('Temp 2 HH')),
                  const SizedBox(height: 12),
                  TextField(decoration: fieldDecoration('Temp 3 H')),
                  const SizedBox(height: 12),
                  TextField(decoration: fieldDecoration('Temp 3 HH')),
                  const SizedBox(height: 16),
                  actionButtons(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                DashboardCard(
                  title: 'Parameter Settings',
                  child: Column(
                    children: [
                      TextField(decoration: fieldDecoration('Deposition Coefficient')),
                      const SizedBox(height: 12),
                      actionButtons(),
                      const SizedBox(height: 16),
                      TextField(decoration: fieldDecoration('Machine rated Current Limit')),
                      const SizedBox(height: 12),
                      actionButtons(),
                      const SizedBox(height: 16),
                      TextField(decoration: fieldDecoration('Machine Rated Current')),
                      const SizedBox(height: 12),
                      actionButtons(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DashboardCard(
                  title: 'Fan and Wirefeed',
                  child: Column(
                    children: [
                      TextField(decoration: fieldDecoration('Normal Fan Pulse per min')),
                      const SizedBox(height: 12),
                      TextField(decoration: fieldDecoration('Wire Feed Pulse Count')),
                      const SizedBox(height: 16),
                      actionButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}