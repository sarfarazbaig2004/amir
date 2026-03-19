import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MachineOverviewScreen extends StatefulWidget {
  const MachineOverviewScreen({super.key});

  @override
  State<MachineOverviewScreen> createState() => _MachineOverviewScreenState();
}

class _MachineOverviewScreenState extends State<MachineOverviewScreen> {
  Map<String, dynamic>? overviewData;
  bool isLoading = true;
  String errorMessage = '';
  Timer? refreshTimer;
  DateTime? lastRefreshTime;

  final String apiUrl = 'http://localhost:5000/api/machine/1/overview';

  @override
  void initState() {
    super.initState();
    fetchOverview();
    startAutoRefresh();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  void startAutoRefresh() {
    refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      fetchOverview(showLoader: false);
    });
  }

  Future<void> fetchOverview({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          overviewData = jsonDecode(response.body);
          isLoading = false;
          errorMessage = '';
          lastRefreshTime = DateTime.now();
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load overview. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Color getHealthColor(String health) {
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

  Color getStatusColor(String status) {
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

  String formatRefreshText() {
    if (lastRefreshTime == null) return 'Live';
    return 'Live • ${lastRefreshTime!.hour.toString().padLeft(2, '0')}:${lastRefreshTime!.minute.toString().padLeft(2, '0')}:${lastRefreshTime!.second.toString().padLeft(2, '0')}';
  }

  Widget buildShellCard({
    required String title,
    required Widget child,
    double? height,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget buildMetricRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhaseGauge(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 7),
            ),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTempGauge(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 7),
            ),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildIndicatorList(
    List<dynamic> items, {
    required Color activeColor,
    required String emptyText,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 18),
      itemBuilder: (context, index) {
        return Row(
          children: [
            Expanded(
              child: Text(
                items[index].toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildTrendChart(List<dynamic> trend) {
    if (trend.isEmpty) {
      return const Center(
        child: Text('No trend data available'),
      );
    }

    final currentSpots = <FlSpot>[];
    final voltageSpots = <FlSpot>[];

    for (int i = 0; i < trend.length; i++) {
      final row = trend[i] as Map<String, dynamic>;
      final current = ((row['current'] ?? 0) as num).toDouble();
      final voltage = ((row['voltage'] ?? 0) as num).toDouble();

      currentSpots.add(FlSpot(i.toDouble(), current));
      voltageSpots.add(FlSpot(i.toDouble(), voltage));
    }

    return Column(
      children: [
        Row(
          children: const [
            Icon(Icons.show_chart, size: 18),
            SizedBox(width: 8),
            Text(
              'Current / Voltage Trend',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: currentSpots,
                  isCurved: true,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: voltageSpots,
                  isCurved: true,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTopHeader({
    required String status,
    required String health,
    required String alarmCount,
    required String warningCount,
  }) {
    final statusColor = getStatusColor(status);
    final healthColor = getHealthColor(health);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MEMCO Machine Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Machine: ARC400  |  Company: MEMCO',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 12, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: healthColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: healthColor.withOpacity(0.35),
                    blurRadius: 14,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  health,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildMetricRow('Alarm Count', alarmCount, bold: true),
                  buildMetricRow('Warning Count', warningCount, bold: true),
                  Row(
                    children: [
                      const Icon(Icons.wifi_tethering, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formatRefreshText(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = overviewData;
    final status = data?['status']?.toString() ?? '-';
    final health = data?['health']?.toString() ?? 'GREEN';
    final alarmCount = data?['alarmCount']?.toString() ?? '0';
    final warningCount = data?['warningCount']?.toString() ?? '0';
    final lastUpdatedAt = data?['lastUpdatedAt']?.toString() ?? '-';

    final weldingCurrent = data?['weldingCurrent']?.toString() ?? '0';
    final weldingVoltage = data?['weldingVoltage']?.toString() ?? '0';

    final inputVoltage = data?['inputVoltage'] as Map<String, dynamic>? ?? {};
    final temperature = data?['temperature'] as Map<String, dynamic>? ?? {};
    final alarms = data?['alarms'] as List<dynamic>? ?? [];
    final warnings = data?['warnings'] as List<dynamic>? ?? [];
    final trend = data?['trend'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xfff4f6f8),
      appBar: AppBar(
        title: const Text('MEMCO Dashboard'),
        actions: [
          IconButton(
            onPressed: () => fetchOverview(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildTopHeader(
                        status: status,
                        health: health,
                        alarmCount: alarmCount,
                        warningCount: warningCount,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: buildShellCard(
                                      title: 'Welding Data',
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          buildMetricRow(
                                            'Welding Current',
                                            weldingCurrent,
                                            bold: true,
                                          ),
                                          buildMetricRow(
                                            'Welding Voltage',
                                            weldingVoltage,
                                            bold: true,
                                          ),
                                          buildMetricRow('Current Setting', '400'),
                                          buildMetricRow('Fan Speed', '0'),
                                          const Spacer(),
                                          Expanded(
                                            child: buildTrendChart(trend),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: buildShellCard(
                                      title: 'Temperature',
                                      child: Column(
                                        children: [
                                          buildMetricRow(
                                            'Trafo Core Temperature',
                                            '${temperature['trafoCore'] ?? 0}',
                                          ),
                                          buildMetricRow(
                                            'IGBT Temperature',
                                            '${temperature['igbt'] ?? 0}',
                                          ),
                                          buildMetricRow(
                                            'Heat Sync Temperature',
                                            '${temperature['heatSync'] ?? 0}',
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              buildTempGauge(
                                                'Trafo',
                                                '${temperature['trafoCore'] ?? 0}',
                                                Colors.orange,
                                              ),
                                              const SizedBox(width: 12),
                                              buildTempGauge(
                                                'IGBT',
                                                '${temperature['igbt'] ?? 0}',
                                                Colors.red,
                                              ),
                                              const SizedBox(width: 12),
                                              buildTempGauge(
                                                'Heat Sync',
                                                '${temperature['heatSync'] ?? 0}',
                                                Colors.deepOrange,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: buildShellCard(
                                      title: 'Input Power Supply',
                                      child: Column(
                                        children: [
                                          buildMetricRow(
                                            'In Voltage R',
                                            '${inputVoltage['R'] ?? 0}',
                                            bold: true,
                                          ),
                                          buildMetricRow(
                                            'In Voltage Y',
                                            '${inputVoltage['Y'] ?? 0}',
                                            bold: true,
                                          ),
                                          buildMetricRow(
                                            'In Voltage B',
                                            '${inputVoltage['B'] ?? 0}',
                                            bold: true,
                                          ),
                                          buildMetricRow('Last Updated', lastUpdatedAt),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              buildPhaseGauge(
                                                'R Voltage',
                                                '${inputVoltage['R'] ?? 0}',
                                              ),
                                              const SizedBox(width: 12),
                                              buildPhaseGauge(
                                                'Y Voltage',
                                                '${inputVoltage['Y'] ?? 0}',
                                              ),
                                              const SizedBox(width: 12),
                                              buildPhaseGauge(
                                                'B Voltage',
                                                '${inputVoltage['B'] ?? 0}',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: buildShellCard(
                                            title: 'Alarms',
                                            child: buildIndicatorList(
                                              alarms,
                                              activeColor: Colors.red,
                                              emptyText: 'No active alarms',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: buildShellCard(
                                            title: 'Warnings',
                                            child: buildIndicatorList(
                                              warnings,
                                              activeColor: Colors.orange,
                                              emptyText: 'No active warnings',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}