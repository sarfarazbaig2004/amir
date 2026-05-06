import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/app_config.dart';
import '../models/customer_access.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/metric_row.dart';
import '../helpers/responsive.dart';
import '../services/machine_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

class MachineOverviewPage extends StatefulWidget {
  const MachineOverviewPage({super.key, this.machineId, this.access});

  final String? machineId;
  final CustomerAccess? access;

  @override
  State<MachineOverviewPage> createState() => _MachineOverviewPageState();
}

class _MachineOverviewPageState extends State<MachineOverviewPage> {
  static const double _desktopMaxWidth = 1400;
  static const double _pagePadding = 24;
  static const double _gap = 24;

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

  String get _machineCode {
    return _stringValue('machineCode', widget.machineId ?? '');
  }

  MachineFeatureConfig get _machineConfig {
    final access = widget.access;
    final code = _machineCode;
    if (access == null || code.isEmpty) {
      return const MachineFeatureConfig();
    }
    return access.machineFeatureConfig[code] ?? const MachineFeatureConfig();
  }

  bool _hasFeature(String key) {
    final access = widget.access;
    if (access == null) return true;
    return access.hasFeature(key);
  }

  bool _hasButton(String key) {
    final access = widget.access;
    if (access == null) return true;
    return access.hasButton(key);
  }

  bool _hasPremiumFeature(String key) {
    final access = widget.access;
    if (access == null) return true;
    return access.hasPremiumFeature(key);
  }

  bool get _showInputVoltageSection {
    return _hasFeature('inputVoltageSection') &&
        _machineConfig.showVoltageSection;
  }

  bool get _showAcVoltageTrend {
    return _showInputVoltageSection && _hasFeature('acVoltageTrend');
  }

  Future<void> _loadOverview({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final data = await MachineService.getMachineOverview(
        widget.machineId ?? AppConfig.defaultMachineId,
      );

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
                    flex: 7,
                    child: Column(
                      children: [
                        _buildWeldingCard(context),
                        if (_showAcVoltageTrend) ...[
                          const SizedBox(height: _gap),
                          _buildAcVoltageTrendCard(context),
                        ],
                        const SizedBox(height: _gap),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_hasFeature('alarms'))
                              Expanded(child: _buildAlarmsCard(context)),
                            if (_hasFeature('alarms') &&
                                _hasFeature('warnings'))
                              const SizedBox(width: _gap),
                            if (_hasFeature('warnings'))
                              Expanded(child: _buildWarningsCard(context)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        if (_showInputVoltageSection) ...[
                          _buildInputPowerCard(context),
                          const SizedBox(height: _gap),
                        ],
                        if (_hasFeature('temperature')) ...[
                          _buildTemperatureCard(context),
                          const SizedBox(height: _gap),
                        ],
                        if (_hasPremiumFeature('rfidWelderIdentification'))
                          _buildWelderRfidCard(context),
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
                  if (_showInputVoltageSection) ...[
                    const SizedBox(width: _gap),
                    Expanded(child: _buildInputPowerCard(context)),
                  ],
                ],
              ),
              const SizedBox(height: _gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasFeature('temperature'))
                    Expanded(child: _buildTemperatureCard(context)),
                  if (_hasFeature('temperature') &&
                      _hasPremiumFeature('rfidWelderIdentification'))
                    const SizedBox(width: _gap),
                  if (_hasPremiumFeature('rfidWelderIdentification'))
                    Expanded(child: _buildWelderRfidCard(context)),
                ],
              ),
              const SizedBox(height: _gap),
              if (_showAcVoltageTrend) ...[
                _buildAcVoltageTrendCard(context),
                const SizedBox(height: _gap),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasFeature('alarms'))
                    Expanded(child: _buildAlarmsCard(context)),
                  if (_hasFeature('alarms') && _hasFeature('warnings'))
                    const SizedBox(width: _gap),
                  if (_hasFeature('warnings'))
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
              if (_showInputVoltageSection) ...[
                _buildInputPowerCard(context),
                const SizedBox(height: 12),
              ],
              if (_hasFeature('temperature')) ...[
                _buildTemperatureCard(context),
                const SizedBox(height: 12),
              ],
              if (_hasPremiumFeature('rfidWelderIdentification')) ...[
                _buildWelderRfidCard(context),
                const SizedBox(height: 12),
              ],
              if (_showAcVoltageTrend) ...[
                _buildAcVoltageTrendCard(context),
                const SizedBox(height: 12),
              ],
              if (_hasFeature('alarms')) ...[
                _buildAlarmsCard(context),
                const SizedBox(height: 12),
              ],
              if (_hasFeature('warnings')) _buildWarningsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSummary(BuildContext context, {required bool isMobile}) {
    final machineCode = _stringValue('machineCode', 'Machine');
    final serialNumber = _stringValue('serialNumber', '-');
    final location = _stringValue('location', 'Shop Floor');
    final status = _stringValue('status', '-');
    final health = _stringValue('health', 'GREEN');
    final alarmCount = _stringValue('alarmCount', '0');
    final warningCount = _stringValue('warningCount', '0');
    final updatedAt = _formatUpdatedAt(_stringValue('lastUpdatedAt', '-'));
    final mapUrl = _googleMapUrl;

    final statusColor = _getStatusColor(status);
    final healthColor = _getHealthColor(health);
    final cardPadding = isMobile ? 18.0 : 28.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Machine Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$machineCode · $serialNumber · $location',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (mapUrl != null && _hasPremiumFeature('liveLocation')) ...[
                  const SizedBox(height: 12),
                  _buildMapButton(mapUrl),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(status, statusColor),
                _chip(health, healthColor),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSummaryPill(
                  'Alarms',
                  alarmCount,
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFCBD5E1),
                ),
                _buildSummaryPill(
                  'Warnings',
                  warningCount,
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFCBD5E1),
                ),
                _buildSummaryPill(
                  'Updated',
                  updatedAt,
                  backgroundColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Machine Details',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$machineCode · $serialNumber · $location',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (mapUrl != null &&
                          _hasPremiumFeature('liveLocation')) ...[
                        const SizedBox(height: 14),
                        _buildMapButton(mapUrl),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  flex: 5,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildSummaryPill(
                        'Alarms',
                        alarmCount,
                        backgroundColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFCBD5E1),
                      ),
                      _buildSummaryPill(
                        'Warnings',
                        warningCount,
                        backgroundColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFCBD5E1),
                      ),
                      _buildSummaryPill(
                        'Updated',
                        updatedAt,
                        backgroundColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _chip(status, statusColor),
                const SizedBox(width: 12),
                _chip(health, healthColor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapButton(String mapUrl) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(mapUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        }
      },
      icon: const Icon(Icons.map_outlined, size: 18),
      label: const Text('View Location'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F172A),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildWeldingCard(BuildContext context) {
    return DashboardCard(
      title: 'Welding Data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              if (_hasFeature('weldingCurrent'))
                MetricRow(
                  label: 'Welding Current',
                  value: '${_numValue('weldingCurrent').toStringAsFixed(1)} A',
                ),
              if (_hasFeature('weldingVoltage'))
                MetricRow(
                  label: 'Welding Voltage',
                  value: '${_numValue('weldingVoltage').toStringAsFixed(1)} V',
                ),
              MetricRow(
                label: 'Current Setting',
                value: '${_numValue('currentSetting').round()} A',
              ),
              if (_hasFeature('fanSpeed'))
                MetricRow(
                  label: 'Fan Speed',
                  value: '${_numValue('fanSpeed').round()} RPM',
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 18),
          _buildTrendChart(),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 18),
          Row(
            children: [
              if (_hasButton('setCurrent'))
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Set current clicked')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Set Current'),
                  ),
                ),
              if (_hasButton('setCurrent')) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset welding data clicked'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
    final inputVoltage = _mapValue('inputVoltage');
    final config = _machineConfig;
    final showSingle =
        config.shouldShowSingleVoltage && _hasFeature('inputVoltageSingle');
    final showR =
        config.shouldShowThreePhaseVoltage &&
        config.showPhaseVoltageR &&
        _hasFeature('inputVoltageR');
    final showY =
        config.shouldShowThreePhaseVoltage &&
        config.showPhaseVoltageY &&
        _hasFeature('inputVoltageY');
    final showB =
        config.shouldShowThreePhaseVoltage &&
        config.showPhaseVoltageB &&
        _hasFeature('inputVoltageB');

    return DashboardCard(
      title: 'Input Power Supply',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              if (showSingle)
                MetricRow(
                  label: 'Input Voltage',
                  value: '${_singleInputVoltage.round()} V',
                ),
              if (showR)
                MetricRow(
                  label: 'In Voltage R',
                  value: '${_numFromMap(inputVoltage, 'R').round()} V',
                ),
              if (showY)
                MetricRow(
                  label: 'In Voltage Y',
                  value: '${_numFromMap(inputVoltage, 'Y').round()} V',
                ),
              if (showB)
                MetricRow(
                  label: 'In Voltage B',
                  value: '${_numFromMap(inputVoltage, 'B').round()} V',
                ),
              const MetricRow(label: 'Heartbeat', value: 'OK'),
            ],
          ),
          if (_hasFeature('phaseVoltageCards') &&
              (showSingle || showR || showY || showB)) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE2E8F0), thickness: 1),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showSingle)
                  Expanded(
                    child: _MiniGauge(
                      label: 'Input',
                      value: _singleInputVoltage.round().toString(),
                    ),
                  ),
                if (showR)
                  Expanded(
                    child: _MiniGauge(
                      label: 'R',
                      value: _numFromMap(inputVoltage, 'R').round().toString(),
                    ),
                  ),
                if ((showSingle || showR) && showY) const SizedBox(width: 12),
                if (showY)
                  Expanded(
                    child: _MiniGauge(
                      label: 'Y',
                      value: _numFromMap(inputVoltage, 'Y').round().toString(),
                    ),
                  ),
                if ((showSingle || showR || showY) && showB)
                  const SizedBox(width: 12),
                if (showB)
                  Expanded(
                    child: _MiniGauge(
                      label: 'B',
                      value: _numFromMap(inputVoltage, 'B').round().toString(),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  num get _singleInputVoltage {
    final direct = _numValue('inputVoltageSingle');
    if (direct > 0) return direct;

    final inputVoltage = _mapValue('inputVoltage');
    return [
      _numFromMap(inputVoltage, 'single'),
      _numFromMap(inputVoltage, 'S'),
      _numFromMap(inputVoltage, 'R'),
      _numFromMap(inputVoltage, 'Y'),
      _numFromMap(inputVoltage, 'B'),
    ].reduce(max);
  }

  Widget _buildTemperatureCard(BuildContext context) {
    final temperatures = _mapValue('temperatures');

    return DashboardCard(
      title: 'Temperature',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              if (_hasFeature('trafoCoreTemperature'))
                MetricRow(
                  label: 'Trafo Core Temperature',
                  value:
                      '${_numFromMap(temperatures, 'trafoCore').toStringAsFixed(1)} °C',
                ),
              if (_hasFeature('igbtTemperature'))
                MetricRow(
                  label: 'IGBT Temperature',
                  value:
                      '${_numFromMap(temperatures, 'igbt').toStringAsFixed(1)} °C',
                ),
              if (_hasFeature('heatSyncTemperature'))
                MetricRow(
                  label: 'Heat Sync Temp.',
                  value:
                      '${_numFromMap(temperatures, 'heatSync').toStringAsFixed(1)} °C',
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _MiniGauge(
                  label: 'Trafo',
                  value: _numFromMap(
                    temperatures,
                    'trafoCore',
                  ).toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniGauge(
                  label: 'IGBT',
                  value: _numFromMap(temperatures, 'igbt').toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniGauge(
                  label: 'Heat Sync',
                  value: _numFromMap(
                    temperatures,
                    'heatSync',
                  ).toStringAsFixed(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 18),
          Row(
            children: [
              if (_hasButton('setTemperature')) ...[
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Set temperature clicked'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Set Temperature'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset temperature data clicked'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
          const SizedBox(height: 18),
          Row(
            children: [
              if (_hasButton('assignRFID')) ...[
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assign RFID clicked')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Assign RFID'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clear welder session clicked'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAcVoltagePhaseCards(),
          const SizedBox(height: 18),
          _buildAcVoltageChart(),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voltage threshold clicked'),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Set Voltage Limit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset voltage trend clicked'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcVoltagePhaseCards() {
    final inputVoltage = _mapValue('inputVoltage');
    final config = _machineConfig;
    final phaseItems = [
      if (config.shouldShowSingleVoltage && _hasFeature('inputVoltageSingle'))
        (
          label: 'Input',
          value: '${_singleInputVoltage.round()} V',
          color: const Color(0xFF0EA5E9),
        ),
      if (config.shouldShowThreePhaseVoltage &&
          config.showPhaseVoltageR &&
          _hasFeature('inputVoltageR'))
        (
          label: 'R',
          value: '${_numFromMap(inputVoltage, 'R').round()} V',
          color: const Color(0xFF0EA5E9),
        ),
      if (config.shouldShowThreePhaseVoltage &&
          config.showPhaseVoltageY &&
          _hasFeature('inputVoltageY'))
        (
          label: 'Y',
          value: '${_numFromMap(inputVoltage, 'Y').round()} V',
          color: const Color(0xFFF59E0B),
        ),
      if (config.shouldShowThreePhaseVoltage &&
          config.showPhaseVoltageB &&
          _hasFeature('inputVoltageB'))
        (
          label: 'B',
          value: '${_numFromMap(inputVoltage, 'B').round()} V',
          color: const Color(0xFF2563EB),
        ),
    ];

    if (phaseItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: phaseItems.map((phase) {
            final columns = phaseItems.length.clamp(1, 3);
            final width = isNarrow
                ? constraints.maxWidth
                : (constraints.maxWidth - (12 * (columns - 1))) / columns;

            return SizedBox(
              width: width,
              child: _VoltagePhaseCard(
                label: phase.label,
                value: phase.value,
                color: phase.color,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAlarmsCard(BuildContext context) {
    final alarms = (overviewData?['alarms'] as List<dynamic>?) ?? [];

    return DashboardCard(
      title: 'Alarms',
      child: Column(
        children: [
          _StatusRow(
            label: 'Overheat',
            color: alarms.contains('OVERHEAT')
                ? const Color(0xFFDC2626)
                : const Color(0xFF10B981),
            active: alarms.contains('OVERHEAT'),
          ),
          _StatusRow(
            label: 'High Voltage',
            color: alarms.contains('HIGH_VOLTAGE')
                ? const Color(0xFFDC2626)
                : const Color(0xFF10B981),
            active: alarms.contains('HIGH_VOLTAGE'),
          ),
          _StatusRow(
            label: 'Over Current',
            color: alarms.contains('OVER_CURRENT')
                ? const Color(0xFFDC2626)
                : const Color(0xFF10B981),
            active: alarms.contains('OVER_CURRENT'),
          ),
          _StatusRow(
            label: 'Fan Speed',
            color: const Color(0xFF10B981),
            active: true,
          ),
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
            label: 'Temp Warning',
            color: warnings.contains('TEMP_WARNING')
                ? const Color(0xFFEA580C)
                : const Color(0xFF10B981),
            active: warnings.contains('TEMP_WARNING'),
          ),
          _StatusRow(
            label: 'Voltage Warning',
            color: warnings.contains('VOLTAGE_WARNING')
                ? const Color(0xFFEA580C)
                : const Color(0xFF10B981),
            active: warnings.contains('VOLTAGE_WARNING'),
          ),
          _StatusRow(
            label: 'Dust Collector Sensor',
            color: const Color(0xFF10B981),
            active: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAcVoltageChart() {
    final inputVoltage = _mapValue('inputVoltage');
    final config = _machineConfig;
    final phaseItems = [
      if (config.shouldShowThreePhaseVoltage &&
          config.showPhaseVoltageR &&
          _hasFeature('inputVoltageR'))
        (label: 'R', color: const Color(0xFF0EA5E9)),
      if (config.shouldShowThreePhaseVoltage &&
          config.showPhaseVoltageY &&
          _hasFeature('inputVoltageY'))
        (label: 'Y', color: const Color(0xFFF59E0B)),
      if (config.shouldShowThreePhaseVoltage &&
          config.showPhaseVoltageB &&
          _hasFeature('inputVoltageB'))
        (label: 'B', color: const Color(0xFF2563EB)),
    ];

    if (phaseItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final phases = phaseItems.map((item) => item.label).toList();
    final phaseColors = phaseItems.map((item) => item.color).toList();
    final phaseValues = phases
        .map((phase) => _numFromMap(inputVoltage, phase).toDouble())
        .toList();

    if (phaseValues.every((value) => value == 0)) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No AC phase voltages available',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final maxValue = phaseValues.reduce(max);
    final minY = 0.0;
    final maxY = maxValue + 20.0;
    final interval = max(20.0, (maxY - minY) / 4);

    final barGroups = List<BarChartGroupData>.generate(
      phases.length,
      (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: phaseValues[index],
            color: phaseColors[index],
            width: 24,
            borderRadius: BorderRadius.circular(8),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: const Color(0xFFCBD5E1).withValues(alpha: 20),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.electrical_services,
              size: 18,
              color: Color(0xFF0F172A),
            ),
            const SizedBox(width: 8),
            const Text(
              '3 Phase Voltage',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: minY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xFFCBD5E1), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= phases.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            phases[index],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                barGroups: barGroups,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${phases[group.x.toInt()]}\n${rod.toY.toStringAsFixed(1)} V',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    final trend = overviewData?['trend'] as List<dynamic>? ?? [];

    if (trend.isEmpty) {
      return const Center(
        child: Text('No trend data', style: TextStyle(color: Colors.grey)),
      );
    }

    final currentSpots = <FlSpot>[];
    final voltageSpots = <FlSpot>[];

    for (int i = 0; i < trend.length; i++) {
      final item = trend[i] as Map<String, dynamic>;
      final current = ((item['current'] ?? 0) as num).toDouble();
      final voltage = ((item['voltage'] ?? 0) as num).toDouble();

      currentSpots.add(FlSpot(i.toDouble(), current));
      voltageSpots.add(FlSpot(i.toDouble(), voltage));
    }

    final yValues = [
      ...currentSpots.map((spot) => spot.y),
      ...voltageSpots.map((spot) => spot.y),
    ];
    final minY = yValues.reduce(min);
    final maxY = yValues.reduce(max);
    final range = max(5, maxY - minY);
    final chartMinY = minY - range * 0.12;
    final chartMaxY = maxY + range * 0.12;
    final yInterval = max(1.0, (chartMaxY - chartMinY) / 4);

    final visibleBottomLabels = trend.length <= 5
        ? List.generate(trend.length, (index) => index)
        : [0, ((trend.length - 1) / 2).round(), trend.length - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart, size: 18, color: Color(0xFF0F172A)),
            const SizedBox(width: 8),
            const Text(
              'Current / Voltage Trend',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              _buildLegendDot(const Color(0xFF14B8A6), 'Current A'),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFF2563EB), 'Voltage V'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (trend.length - 1).toDouble(),
                  minY: chartMinY,
                  maxY: chartMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final int index = value.toInt();
                          if (!visibleBottomLabels.contains(index) ||
                              index < 0 ||
                              index >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black87,
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final label = spot.barIndex == 0
                              ? 'Current'
                              : 'Voltage';
                          return LineTooltipItem(
                            '$label\n${spot.y.toStringAsFixed(1)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: currentSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: const Color(0xFF14B8A6),
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: voltageSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: const Color(0xFF2563EB),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  String _stringValue(String key, String fallback) {
    final value = overviewData?[key];
    return value == null ? fallback : value.toString();
  }

  String _formatUpdatedAt(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return "${parsed.toLocal().hour.toString().padLeft(2, '0')}:${parsed.toLocal().minute.toString().padLeft(2, '0')} • ${parsed.toLocal().day.toString().padLeft(2, '0')}/${parsed.toLocal().month.toString().padLeft(2, '0')}/${parsed.toLocal().year}";
  }

  String? get _googleMapUrl {
    final mapUrl = _stringOrNull('mapUrl');
    if (mapUrl != null) {
      return mapUrl;
    }

    final gpsLat = _coordinateValue('gpsLat') ?? _coordinateValue('latitude');
    final gpsLng = _coordinateValue('gpsLng') ?? _coordinateValue('longitude');

    if (gpsLat == null || gpsLng == null) {
      return null;
    }

    return 'https://www.google.com/maps?q=$gpsLat,$gpsLng';
  }

  String? _stringOrNull(String key) {
    final value = overviewData?[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _coordinateValue(String key) {
    final value = overviewData?[key];
    if (value is num && value.isFinite) {
      return value.toString();
    }
    if (value is String) {
      final parsed = num.tryParse(value.trim());
      if (parsed != null && parsed.isFinite) {
        return value.trim();
      }
    }
    return null;
  }

  Widget _buildSummaryPill(
    String label,
    String value, {
    Color backgroundColor = const Color(0xFFF9FAFB),
    Color borderColor = const Color(0xFFE5E7EB),
    Color labelColor = const Color(0xFF64748B),
    Color valueColor = const Color(0xFF0F172A),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      constraints: const BoxConstraints(minWidth: 170),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              letterSpacing: 0.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  num _numValue(String key) {
    final value = overviewData?[key];
    if (value is num) return value;
    return 0;
  }

  Map<String, dynamic> _mapValue(String key) {
    final value = overviewData?[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  num _numFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  Color _getStatusColor(String status) {
    final normalized = status.trim().toUpperCase();
    switch (normalized) {
      case 'WELDING':
        return Colors.orange.shade700;
      case 'IDLE':
        return Colors.blue.shade700;
      case 'OFF':
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getHealthColor(String health) {
    final normalized = health.trim().toUpperCase();
    switch (normalized) {
      case 'RED':
        return const Color(0xFFB91C1C);
      case 'YELLOW':
        return const Color(0xFFB45309);
      case 'GREEN':
      default:
        return const Color(0xFF15803D);
    }
  }

  Widget _chip(String text, Color color) {
    final normalized = text.trim().toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 180)),
      ),
      child: Text(
        normalized,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _MiniGauge extends StatelessWidget {
  final String label;
  final String value;

  const _MiniGauge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _VoltagePhaseCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _VoltagePhaseCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 28),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 90)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;

  const _StatusRow({
    required this.label,
    required this.color,
    this.active = false,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Text(
              active ? 'Active' : 'Standby',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
