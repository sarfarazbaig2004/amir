import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import 'services/machine_service.dart';

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
      final data = await MachineService.getMachineOverview(
        AppConfig.defaultMachineId,
      );

      setState(() {
        overviewData = data;
        isLoading = false;
        errorMessage = '';
        lastRefreshTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Color getHealthColor(String health) {
    final normalized = health.trim().toUpperCase();
    switch (normalized) {
      case 'RED':
        return Colors.red.shade700;
      case 'YELLOW':
        return Colors.amber.shade700;
      case 'GREY':
      case 'GRAY':
        return Colors.grey.shade700;
      case 'GREEN':
      default:
        return Colors.green.shade700;
    }
  }

  Color getStatusColor(String status) {
    final normalized = status.trim().toUpperCase();
    switch (normalized) {
      case 'WELDING':
        return Colors.orange.shade700;
      case 'IDLE':
        return Colors.blue.shade700;
      case 'OFFLINE':
      case 'OFF':
      default:
        return Colors.grey.shade800;
    }
  }

  Widget buildHealthBadge(String health) {
    final normalized = health.trim().toUpperCase();
    final color = getHealthColor(normalized);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 51),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        'HEALTH: $normalized',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildStatusBadge(String status) {
    final normalized = status.trim().toUpperCase();
    final color = getStatusColor(normalized);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 61),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        normalized,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String formatRefreshText() {
    if (lastRefreshTime == null) return 'Live';
    return 'Live • ${lastRefreshTime!.hour.toString().padLeft(2, '0')}:${lastRefreshTime!.minute.toString().padLeft(2, '0')}:${lastRefreshTime!.second.toString().padLeft(2, '0')}';
  }

  Widget buildShellCard({required String title, required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            child,
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLocationCard(Map<String, dynamic>? data) {
    final gpsFix = data?['gpsFix'] == true;
    final gpsLat = data?['gpsLat'];
    final gpsLng = data?['gpsLng'];
    final mapUrl = data?['mapUrl']?.toString();

    if (!gpsFix || mapUrl == null || mapUrl.isEmpty) {
      return buildShellCard(
        title: 'GPS Location',
        child: const Text(
          'GPS location not available',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return buildShellCard(
      title: 'GPS Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildMetricRow('GPS Status', 'Fixed', bold: true),
          buildMetricRow('Latitude', '$gpsLat'),
          buildMetricRow('Longitude', '$gpsLng'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(mapUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.location_on),
            label: const Text('View Location'),
          ),
        ],
      ),
    );
  }

  Widget buildPhaseGauge(String label, String value) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            textAlign: TextAlign.center,
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
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            textAlign: TextAlign.center,
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            emptyText,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.toString(),
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
                      color: activeColor.withValues(alpha: 128),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildTrendChart(List<dynamic> trend) {
    if (trend.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          alignment: Alignment.center,
          child: const Text('No trend data available'),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.show_chart, size: 18),
            SizedBox(width: 8),
            Text(
              'Current / Voltage Trend',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 16 / 9,
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUIK IoT | MEMCO',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Machine: ARC400  |  Company: MEMCO',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                buildHealthBadge(health),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildStatusBadge(status),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildMetricRow('Alarm Count', alarmCount, bold: true),
                      buildMetricRow('Warning Count', warningCount, bold: true),
                      Row(
                        children: [
                          const Icon(
                            Icons.wifi_tethering,
                            color: Colors.green,
                            size: 16,
                          ),
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
          ],
        ),
      ),
    );
  }

  Widget buildResponsiveCards(double width, List<Widget> cards) {
    final bool stack = width < 1150;

    if (stack) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: card,
              ),
            )
            .toList(),
      );
    }

    final cardWidth = (width - 16) / 2;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards
          .map((card) => SizedBox(width: cardWidth, child: card))
          .toList(),
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
    final temperatures = data?['temperatures'] as Map<String, dynamic>? ?? {};
    final alarms = data?['alarms'] as List<dynamic>? ?? [];
    final warnings = data?['warnings'] as List<dynamic>? ?? [];
    final trend = data?['trend'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xfff4f6f8),
      appBar: AppBar(
        title: const Text('QUIK IoT | MEMCO'),
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
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
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
                      buildResponsiveCards(constraints.maxWidth, [
                        buildShellCard(
                          title: 'Welding Data',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 12),
                              buildTrendChart(trend),
                            ],
                          ),
                        ),
                        buildShellCard(
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
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  buildPhaseGauge(
                                    'R Voltage',
                                    '${inputVoltage['R'] ?? 0}',
                                  ),
                                  buildPhaseGauge(
                                    'Y Voltage',
                                    '${inputVoltage['Y'] ?? 0}',
                                  ),
                                  buildPhaseGauge(
                                    'B Voltage',
                                    '${inputVoltage['B'] ?? 0}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        buildLocationCard(data),
                        buildShellCard(
                          title: 'Temperature',
                          child: Column(
                            children: [
                              buildMetricRow(
                                'Trafo Core Temperature',
                                '${temperatures['trafoCore'] ?? 0}',
                              ),
                              buildMetricRow(
                                'IGBT Temperature',
                                '${temperatures['igbt'] ?? 0}',
                              ),
                              buildMetricRow(
                                'Heat Sync Temperature',
                                '${temperatures['heatSync'] ?? 0}',
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  buildTempGauge(
                                    'Trafo',
                                    '${temperatures['trafoCore'] ?? 0}',
                                    Colors.orange,
                                  ),
                                  buildTempGauge(
                                    'IGBT',
                                    '${temperatures['igbt'] ?? 0}',
                                    Colors.red,
                                  ),
                                  buildTempGauge(
                                    'Heat Sync',
                                    '${temperatures['heatSync'] ?? 0}',
                                    Colors.deepOrange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        buildShellCard(
                          title: 'Alarms & Warnings',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alarms',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              buildIndicatorList(
                                alarms,
                                activeColor: Colors.red,
                                emptyText: 'No active alarms',
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Warnings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              buildIndicatorList(
                                warnings,
                                activeColor: Colors.orange,
                                emptyText: 'No active warnings',
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
