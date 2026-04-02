import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/metric_row.dart';
import '../helpers/responsive.dart';

class MachineOverviewPage extends StatelessWidget {
  const MachineOverviewPage({super.key});

  static const double _desktopMaxWidth = 1400;
  static const double _pagePadding = 16;
  static const double _gap = 16;

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
                    _chip('WELDING', Colors.green),
                    _circle('RED', Colors.red),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Alarm Count: 3',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Warning Count: 0',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Live • 15:42:10'),
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
                _chip('WELDING', Colors.green),
                const SizedBox(width: 12),
                _circle('RED', Colors.red),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alarm Count: 3',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('Warning Count: 0',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('Live • 15:42:10'),
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
          const MetricRow(label: 'Welding Current', value: '353.19 A'),
          const MetricRow(label: 'Welding Voltage', value: '18.1 V'),
          const MetricRow(label: 'Current Setting', value: '400 A'),
          const MetricRow(label: 'Fan Speed', value: '0 RPM'),
          const SizedBox(height: 12),
          _fakeChartBox(
            title: 'Current / Voltage Trend',
            height: 180,
          ),
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
    return DashboardCard(
      title: 'Input Power Supply',
      child: Column(
        children: [
          const MetricRow(label: 'In Voltage R', value: '211 V'),
          const MetricRow(label: 'In Voltage Y', value: '224 V'),
          const MetricRow(label: 'In Voltage B', value: '231 V'),
          const MetricRow(label: 'Heartbeat', value: 'OK'),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _MiniGauge(label: 'R Voltage', value: '211')),
              SizedBox(width: 12),
              Expanded(child: _MiniGauge(label: 'Y Voltage', value: '224')),
              SizedBox(width: 12),
              Expanded(child: _MiniGauge(label: 'B Voltage', value: '231')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(BuildContext context) {
    return DashboardCard(
      title: 'Temperature',
      child: Column(
        children: [
          const MetricRow(label: 'Trafo Core Temperature', value: '34.21 °C'),
          const MetricRow(label: 'IGBT Temperature', value: '42.67 °C'),
          const MetricRow(label: 'Heat Sync Temp.', value: '47.3 °C'),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _MiniGauge(label: 'Trafo', value: '34')),
              SizedBox(width: 12),
              Expanded(child: _MiniGauge(label: 'IGBT', value: '42')),
              SizedBox(width: 12),
              Expanded(child: _MiniGauge(label: 'Heat Sync', value: '47')),
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
                      const SnackBar(content: Text('Reset temperature data clicked')),
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
          _fakeChartBox(
            title: 'R / Y / B Phase Trend',
            height: 220,
          ),
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
    return DashboardCard(
      title: 'Alarms',
      child: Column(
        children: const [
          _StatusRow(label: 'Trafo Core Temperature HI', color: Colors.green),
          _StatusRow(label: 'IGBT Temperature HI', color: Colors.green),
          _StatusRow(label: 'Heat Sink Temperature HI', color: Colors.green),
          _StatusRow(label: 'R Voltage', color: Colors.green),
          _StatusRow(label: 'Y Voltage', color: Colors.green),
          _StatusRow(label: 'B Voltage', color: Colors.green),
          _StatusRow(label: 'Fan Speed', color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildWarningsCard(BuildContext context) {
    return DashboardCard(
      title: 'Warnings',
      child: Column(
        children: const [
          _StatusRow(label: 'Trafo Core Temperature HI', color: Colors.green),
          _StatusRow(label: 'IGBT Temperature HI', color: Colors.green),
          _StatusRow(label: 'Heat Sink Temperature HI', color: Colors.green),
          _StatusRow(label: 'R Voltage', color: Colors.green),
          _StatusRow(label: 'Y Voltage', color: Colors.green),
          _StatusRow(label: 'B Voltage', color: Colors.green),
          _StatusRow(label: 'Dust Collector Sensor', color: Colors.orange),
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
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
            style: const TextStyle(
              fontSize: 22,
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