import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../config/app_config.dart';
import '../services/machine_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/metric_row.dart';
import '../helpers/responsive.dart';

class MachineProductionPage extends StatefulWidget {
  const MachineProductionPage({super.key, this.machineId});

  final String? machineId;

  @override
  State<MachineProductionPage> createState() => _MachineProductionPageState();
}

class _MachineProductionPageState extends State<MachineProductionPage> {
  static const double _pagePadding = 16;
  static const double _gap = 16;
  static const double _maxWidth = 1400;

  Map<String, dynamic>? _overviewData;
  Map<String, dynamic>? _dailyProductionData;
  List<dynamic> _productionTimeline = [];
  DateTime _selectedDate = DateTime.now().toUtc();
  Timer? _productionClockTimer;
  Timer? _refreshTimer;
  bool _refreshInProgress = false;
  int _loadGeneration = 0;
  bool _isLoading = true;
  bool _isProductionLoading = true;
  String _errorMessage = '';
  String _productionErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOverview();
    _loadProductionData();
    _productionClockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _hasOpenTimelineEvent) {
        setState(() {});
      }
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshLiveData();
    });
  }

  @override
  void didUpdateWidget(covariant MachineProductionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machineId != widget.machineId) {
      _loadGeneration++;
      _overviewData = null;
      _dailyProductionData = null;
      _productionTimeline = [];
      _loadOverview();
      _loadProductionData();
    }
  }

  @override
  void dispose() {
    _productionClockTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOverview({bool showLoader = true}) async {
    final loadGeneration = _loadGeneration;
    final machineId = _machineId;
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final data = await MachineService.getMachineOverview(machineId);

      if (!mounted || loadGeneration != _loadGeneration) return;

      setState(() {
        _overviewData = data;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (error) {
      if (!mounted || loadGeneration != _loadGeneration) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadProductionData({bool showLoader = true}) async {
    final loadGeneration = _loadGeneration;
    final machineId = _machineId;
    if (showLoader) {
      setState(() {
        _isProductionLoading = true;
        _productionErrorMessage = '';
      });
    }

    final date = _apiDate(_selectedDate);

    try {
      final results = await Future.wait([
        MachineService.getMachineDailyProduction(machineId, date),
        MachineService.getMachineProductionTimeline(machineId, date),
      ]);

      if (!mounted || loadGeneration != _loadGeneration) return;

      setState(() {
        _dailyProductionData = results[0] as Map<String, dynamic>;
        _productionTimeline = results[1] as List<dynamic>;
        _isProductionLoading = false;
        _productionErrorMessage = '';
      });
    } catch (error) {
      if (!mounted || loadGeneration != _loadGeneration) return;

      setState(() {
        _isProductionLoading = false;
        _productionErrorMessage = error.toString();
      });
    }
  }

  Future<void> _refreshLiveData() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    try {
      await Future.wait([
        _loadOverview(showLoader: false),
        if (_isSelectedDateToday) _loadProductionData(showLoader: false),
      ]);
    } finally {
      _refreshInProgress = false;
    }
  }

  Future<void> _resetRunningJobData() async {
    await MachineService.resetJobData(_machineId);
    await _loadOverview(showLoader: false);
  }

  Future<void> _resetMachineLifetimeData() async {
    await MachineService.resetMachineLifetimeData(_machineId);
    await _loadOverview(showLoader: false);
  }

  Future<void> _selectProductionDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedDate = pickedDate;
    });
    await _loadProductionData();
  }

  String get _machineId => widget.machineId ?? AppConfig.defaultMachineId;

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _overviewData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _overviewData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage,
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
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_pagePadding),
          child: Column(
            children: [
              _buildProductionHistorySection(context),
              const SizedBox(height: _gap),
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
              _buildProductionHistorySection(context),
              const SizedBox(height: _gap),
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
              _buildProductionHistorySection(context),
              const SizedBox(height: 12),
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

  Widget _buildProductionHistorySection(BuildContext context) {
    final isWide = !Responsive.isMobile(context);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: _buildDailySummaryCard(context)),
          const SizedBox(width: _gap),
          Expanded(flex: 5, child: _buildTimelineCard(context)),
        ],
      );
    }

    return Column(
      children: [
        _buildDailySummaryCard(context),
        const SizedBox(height: 12),
        _buildTimelineCard(context),
      ],
    );
  }

  Widget _buildDailySummaryCard(BuildContext context) {
    final metrics = _dailySummaryMetrics;

    return DashboardCard(
      title: 'Daily Production Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(context),
          const SizedBox(height: 16),
          if (_isProductionLoading && _dailyProductionData == null)
            const SizedBox(
              height: 148,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_productionErrorMessage.isNotEmpty &&
              _dailyProductionData == null)
            _buildInlineError(_productionErrorMessage)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 760
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth >= 480
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics.entries.map((metric) {
                    return SizedBox(
                      width: cardWidth,
                      child: _buildSummaryTile(metric.key, metric.value),
                    );
                  }).toList(),
                );
              },
            ),
          if (_productionErrorMessage.isNotEmpty &&
              _dailyProductionData != null) ...[
            const SizedBox(height: 12),
            _buildInlineError(_productionErrorMessage),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _displayDate(_selectedDate),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _isProductionLoading ? null : _selectProductionDate,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: const Text('Select Date'),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh production data',
          onPressed: _isProductionLoading
              ? null
              : () => _loadProductionData(showLoader: false),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildSummaryTile(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    return DashboardCard(
      title: 'Production Timeline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayDate(_selectedDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (_isProductionLoading && _productionTimeline.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_productionErrorMessage.isNotEmpty &&
              _productionTimeline.isEmpty)
            _buildInlineError(_productionErrorMessage)
          else if (_productionTimeline.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No timeline events found for this date.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ..._productionTimeline.map(_buildTimelineItem),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(dynamic item) {
    final event = _timelineEvent(item);
    final status = event.status;
    final statusColor = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${event.start} to ${event.end} $status',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB91C1C),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRunningJobCard(BuildContext context) {
    final metrics = _runningJobMetrics;

    return DashboardCard(
      title: 'Running Job',
      child: Column(
        children: [
          ...metrics.entries.map(
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
                onConfirm: _resetRunningJobData,
              ),
              child: const Text('Reset Job Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimeCard(BuildContext context) {
    final metrics = _lifetimeMetrics;

    return DashboardCard(
      title: 'Machine Lifetime',
      child: Column(
        children: [
          ...metrics.entries.map(
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
                onConfirm: _resetMachineLifetimeData,
              ),
              child: const Text('Reset Machine Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard() {
    final temperatures = _mapValue('temperatures');

    return DashboardCard(
      title: 'Temperature Data',
      child: Column(
        children: [
          MetricRow(
            label: 'Temperature 1',
            value:
                '${_numFromMap(temperatures, 'trafoCore').toStringAsFixed(1)} °C',
          ),
          MetricRow(
            label: 'Temperature 2',
            value: '${_numFromMap(temperatures, 'igbt').toStringAsFixed(1)} °C',
          ),
          MetricRow(
            label: 'Temperature 3',
            value:
                '${_numFromMap(temperatures, 'heatSync').toStringAsFixed(1)} °C',
          ),
        ],
      ),
    );
  }

  Widget _buildAcVoltageCard() {
    final inputVoltage = _mapValue('inputVoltage');

    return DashboardCard(
      title: 'AC Voltage',
      child: Column(
        children: [
          MetricRow(
            label: 'R phase Voltage',
            value: '${_numFromMap(inputVoltage, 'R').round()} V',
          ),
          MetricRow(
            label: 'Y phase Voltage',
            value: '${_numFromMap(inputVoltage, 'Y').round()} V',
          ),
          MetricRow(
            label: 'B phase Voltage',
            value: '${_numFromMap(inputVoltage, 'B').round()} V',
          ),
        ],
      ),
    );
  }

  Widget _buildMachineLiveDataCard() {
    return DashboardCard(
      title: 'Machine Live Data',
      child: Column(
        children: [
          MetricRow(label: 'Machine Status', value: _currentMachineStatus),
          MetricRow(
            label: 'Current Status Time',
            value: _formatDuration(_currentTimelineSeconds),
          ),
          MetricRow(label: 'Today OFF/OFFLINE', value: _todayOffOfflineTime),
          MetricRow(
            label: 'Welding Current',
            value: '${_numValue('weldingCurrent').toStringAsFixed(2)} A',
          ),
          MetricRow(
            label: 'Welding Voltage',
            value: '${_numValue('weldingVoltage').toStringAsFixed(1)} V',
          ),
          MetricRow(
            label: 'Current set by Knob',
            value: '${_numValue('currentSetting').round()} A',
          ),
        ],
      ),
    );
  }

  Map<String, String> get _runningJobMetrics {
    final runningJob = _mapValue('runningJob');
    return {
      'Arcing Time': _stringFromMap(runningJob, 'arcingTime', '0:00:00'),
      'Idle Time': _stringFromMap(runningJob, 'idleTime', '0:00:00'),
      'DC Energy': _stringFromMap(runningJob, 'dcEnergy', '0'),
      'Deposition': _stringFromMap(runningJob, 'deposition', '0'),
      'Wire Feed Meter': _stringFromMap(runningJob, 'wireFeedMeter', '0'),
      'No Of Arcs': _stringFromMap(runningJob, 'arcCount', '0'),
    };
  }

  Map<String, String> get _lifetimeMetrics {
    final lifetime = _mapValue('machineLifetime');
    return {
      'Arcing Time': _stringFromMap(lifetime, 'arcingTime', '0:00:00'),
      'Idle Time': _stringFromMap(lifetime, 'idleTime', '0:00:00'),
      'DC Energy': _stringFromMap(lifetime, 'dcEnergy', '0'),
      'Deposition': _stringFromMap(lifetime, 'deposition', '0'),
      'Wire Feed Meter': _stringFromMap(lifetime, 'wireFeedMeter', '0'),
      'No Of Arcs': _stringFromMap(lifetime, 'arcCount', '0'),
    };
  }

  Map<String, String> get _dailySummaryMetrics {
    final summary = _productionSummary;
    final timelineSummary = _timelineSummary;
    return {
      'Arc Time': _durationMetricWithFallback(summary, const [
        'arcTime',
        'arcingTime',
        'arc_time',
        'arcing_time',
      ], timelineSummary.arcSeconds),
      'Idle Time': _durationMetricWithFallback(summary, const [
        'idleTime',
        'idle_time',
      ], timelineSummary.idleSeconds),
      'OFF/OFFLINE Time': _combinedDurationMetricWithFallback(summary, const [
        'offTime',
        'offlineTime',
        'offOfflineTime',
        'off_time',
        'offline_time',
      ], timelineSummary.offSeconds + timelineSummary.offlineSeconds),
      'Machine ON Time': _durationMetricWithFallback(summary, const [
        'machineOnTime',
        'onTime',
        'machine_on_time',
      ], timelineSummary.machineOnSeconds),
      'No. of Arcs': _plainMetric(summary, const [
        'arcCount',
        'noOfArcs',
        'numberOfArcs',
        'arcs',
      ], '0'),
      'Utilization %': _percentMetric(summary, const [
        'utilization',
        'utilizationPercent',
        'utilizationPercentage',
      ]),
      'Arc Efficiency %': _percentMetric(summary, const [
        'arcEfficiency',
        'arcEfficiencyPercent',
        'arcEfficiencyPercentage',
      ]),
    };
  }

  String get _todayOffOfflineTime {
    final summary = _productionSummary;
    final timelineSummary = _timelineSummary;
    return _combinedDurationMetricWithFallback(summary, const [
      'offTime',
      'offlineTime',
      'offOfflineTime',
      'off_time',
      'offline_time',
    ], timelineSummary.offSeconds + timelineSummary.offlineSeconds);
  }

  Map<String, dynamic> get _productionSummary {
    final data = _dailyProductionData;
    if (data == null) return const {};

    for (final key in const ['summary', 'dailySummary', 'production', 'data']) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        return _withTimelineFallback(value);
      }
      if (value is Map) {
        return _withTimelineFallback(Map<String, dynamic>.from(value));
      }
    }

    return _withTimelineFallback(data);
  }

  Map<String, dynamic> _mapValue(String key) {
    final value = _overviewData?[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  num _numValue(String key) {
    final value = _overviewData?[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  num _numFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  String _stringFromMap(Map<String, dynamic> map, String key, String fallback) {
    final value = map[key];
    if (value == null) return fallback;
    return value.toString();
  }

  String _durationMetric(Map<String, dynamic> map, List<String> keys) {
    final value = _firstValue(map, keys);
    if (value == null) return '0:00:00';
    if (value is num) return _formatDuration(value);

    final text = value.toString().trim();
    if (text.isEmpty) return '0:00:00';
    final seconds = num.tryParse(text);
    if (seconds != null) return _formatDuration(seconds);
    return text;
  }

  String _combinedDurationMetric(Map<String, dynamic> map, List<String> keys) {
    var totalSeconds = 0;
    var hasNumericValue = false;

    for (final key in keys) {
      final value = map[key];
      final seconds = _secondsValue(value);
      if (seconds != null) {
        hasNumericValue = true;
        totalSeconds += seconds.round();
      }
    }

    if (hasNumericValue) {
      return _formatDuration(totalSeconds);
    }

    return _durationMetric(map, keys);
  }

  String _durationMetricWithFallback(
    Map<String, dynamic> map,
    List<String> keys,
    int fallbackSeconds,
  ) {
    final backendSeconds = _secondsValue(_firstValue(map, keys));
    if (backendSeconds != null || fallbackSeconds > 0) {
      return _formatDuration(_largerDuration(backendSeconds, fallbackSeconds));
    }

    return _durationMetric(map, keys);
  }

  String _combinedDurationMetricWithFallback(
    Map<String, dynamic> map,
    List<String> keys,
    int fallbackSeconds,
  ) {
    var backendSeconds = 0;
    var hasBackendValue = false;

    for (final key in keys) {
      final seconds = _secondsValue(map[key]);
      if (seconds != null) {
        hasBackendValue = true;
        backendSeconds += seconds;
      }
    }

    if (hasBackendValue || fallbackSeconds > 0) {
      return _formatDuration(_largerDuration(backendSeconds, fallbackSeconds));
    }

    return _combinedDurationMetric(map, keys);
  }

  String _percentMetric(Map<String, dynamic> map, List<String> keys) {
    final value = _firstValue(map, keys);
    if (value == null) return '0%';

    if (value is num) {
      return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';
    }

    final text = value.toString().trim();
    if (text.isEmpty) return '0%';
    if (text.endsWith('%')) return text;

    final parsed = num.tryParse(text);
    if (parsed == null) return text;
    return '${parsed.toStringAsFixed(parsed % 1 == 0 ? 0 : 1)}%';
  }

  String _plainMetric(
    Map<String, dynamic> map,
    List<String> keys,
    String fallback,
  ) {
    final value = _firstValue(map, keys);
    if (value == null) return fallback;
    return value.toString();
  }

  dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key];
      }
    }
    return null;
  }

  int _largerDuration(int? backendSeconds, int fallbackSeconds) {
    final normalizedBackendSeconds = backendSeconds ?? 0;
    return normalizedBackendSeconds > fallbackSeconds
        ? normalizedBackendSeconds
        : fallbackSeconds;
  }

  Map<String, dynamic> _withTimelineFallback(Map<String, dynamic> summary) {
    final nextSummary = Map<String, dynamic>.from(summary);
    final derivedSummary = _timelineSummary;

    _setDurationFallback(nextSummary, 'arcTime', derivedSummary.arcSeconds);
    _setDurationFallback(nextSummary, 'idleTime', derivedSummary.idleSeconds);
    _setDurationFallback(nextSummary, 'offTime', derivedSummary.offSeconds);
    _setDurationFallback(
      nextSummary,
      'offlineTime',
      derivedSummary.offlineSeconds,
    );
    _setDurationFallback(
      nextSummary,
      'machineOnTime',
      derivedSummary.machineOnSeconds,
    );
    _setDurationFallback(
      nextSummary,
      'trackedSeconds',
      derivedSummary.trackedSeconds,
    );

    if (_isMissingOrZero(nextSummary['utilizationPercent']) &&
        derivedSummary.trackedSeconds > 0) {
      nextSummary['utilizationPercent'] =
          derivedSummary.machineOnSeconds / derivedSummary.trackedSeconds * 100;
    }

    if (_isMissingOrZero(nextSummary['arcEfficiencyPercent']) &&
        derivedSummary.machineOnSeconds > 0) {
      nextSummary['arcEfficiencyPercent'] =
          derivedSummary.arcSeconds / derivedSummary.machineOnSeconds * 100;
    }

    return nextSummary;
  }

  void _setDurationFallback(
    Map<String, dynamic> summary,
    String key,
    int fallbackSeconds,
  ) {
    if (fallbackSeconds > 0 && _isMissingOrZero(summary[key])) {
      summary[key] = fallbackSeconds;
    }
  }

  bool _isMissingOrZero(dynamic value) {
    final seconds = _secondsValue(value);
    return seconds == null || seconds == 0;
  }

  int? _secondsValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final numericValue = num.tryParse(text);
    if (numericValue != null) return numericValue.round();

    final parts = text.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      final seconds = int.tryParse(parts[2]);
      if (hours != null && minutes != null && seconds != null) {
        return hours * 3600 + minutes * 60 + seconds;
      }
    }

    return null;
  }

  _TimelineSummary get _timelineSummary {
    var arcSeconds = 0;
    var idleSeconds = 0;
    var offSeconds = 0;
    var offlineSeconds = 0;

    for (final item in _productionTimeline) {
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      final status = _plainMetric(map, const [
        'status',
        'state',
        'mode',
        'type',
      ], 'UNKNOWN').toUpperCase();
      final effectiveStatus = _effectiveTimelineStatus(map, status);
      final durationSeconds = _timelineDurationSeconds(map);

      switch (effectiveStatus) {
        case 'ARC':
        case 'ARCING':
        case 'WELDING':
          arcSeconds += durationSeconds;
          break;
        case 'IDLE':
          idleSeconds += durationSeconds;
          break;
        case 'OFF':
          offSeconds += durationSeconds;
          break;
        case 'OFFLINE':
          offlineSeconds += durationSeconds;
          break;
      }
    }

    return _TimelineSummary(
      arcSeconds: arcSeconds,
      idleSeconds: idleSeconds,
      offSeconds: offSeconds,
      offlineSeconds: offlineSeconds,
    );
  }

  String get _currentMachineStatus {
    final currentMap = _currentTimelineMap;
    if (currentMap != null) {
      final status = _plainMetric(currentMap, const [
        'status',
        'state',
        'mode',
        'type',
      ], '').toUpperCase();
      final effectiveStatus = _effectiveTimelineStatus(currentMap, status);
      if (effectiveStatus.isNotEmpty) return effectiveStatus;
    }

    final overviewStatus = _overviewData?['status'];
    if (overviewStatus != null && overviewStatus.toString().trim().isNotEmpty) {
      return overviewStatus.toString().trim().toUpperCase();
    }

    return 'UNKNOWN';
  }

  String _effectiveTimelineStatus(
    Map<String, dynamic> map,
    String fallbackStatus,
  ) {
    if (!_isOpenTimelineEvent(map)) {
      return fallbackStatus;
    }

    final derivedStatus = _derivedTelemetryStatus;
    if (derivedStatus == null) {
      return fallbackStatus;
    }

    switch (fallbackStatus) {
      case '':
      case 'UNKNOWN':
      case 'OFF':
      case 'OFFLINE':
      case 'OFF/OFFLINE':
        return derivedStatus;
      default:
        return fallbackStatus;
    }
  }

  int get _currentTimelineSeconds {
    final currentMap = _currentTimelineMap;
    if (currentMap == null) return 0;
    return _timelineDurationSeconds(currentMap);
  }

  Map<String, dynamic>? get _currentTimelineMap {
    for (final item in _productionTimeline.reversed) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final end = _firstValue(map, const ['end', 'endTime', 'to', 'toTime']);
      if (end == null) return map;
    }

    for (final item in _productionTimeline.reversed) {
      if (item is Map) return Map<String, dynamic>.from(item);
    }

    return null;
  }

  int _timelineDurationSeconds(Map<String, dynamic> map) {
    final duration = _secondsValue(
      _firstValue(map, const ['durationSeconds', 'duration', 'seconds']),
    );
    if (duration != null && duration > 0) {
      return duration;
    }

    final start = _dateTimeValue(
      _firstValue(map, const ['start', 'startTime', 'from', 'fromTime']),
    );
    if (start == null) return 0;

    final end = _dateTimeValue(
      _firstValue(map, const ['end', 'endTime', 'to', 'toTime']),
    );

    final effectiveEnd = end ?? (_isSelectedDateToday ? DateTime.now() : null);
    if (effectiveEnd == null) {
      return 0;
    }

    if (effectiveEnd.isBefore(start)) {
      final localDayStart = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      if (effectiveEnd.isBefore(localDayStart)) {
        return 0;
      }
      return effectiveEnd.difference(localDayStart).inSeconds;
    }

    return effectiveEnd.difference(start).inSeconds;
  }

  String? get _derivedTelemetryStatus {
    final telemetryTime = _telemetryTimestamp;
    if (telemetryTime == null) {
      return null;
    }

    final arcOn = _telemetryBool(const ['arcOn', 'arc_on', 'isArcing']);
    final machineOn = _telemetryBool(const [
      'machineOn',
      'machine_on',
      'isMachineOn',
    ]);

    final effectiveArcOn = arcOn ?? _outputCurrent > 5;
    final effectiveMachineOn = machineOn ?? _inputVoltage > 100;

    if (effectiveArcOn) {
      return 'ARC';
    }
    if (effectiveMachineOn) {
      return 'IDLE';
    }
    return 'OFFLINE';
  }

  DateTime? get _telemetryTimestamp {
    final telemetry = _mapValue('telemetry');
    final value =
        _firstValue(telemetry, const ['timestamp', 'time', 'createdAt']) ??
        _firstValue(_overviewData ?? const {}, const [
          'timestamp',
          'lastUpdatedAt',
          'telemetryTimestamp',
        ]);
    return _dateTimeValue(value);
  }

  bool? _telemetryBool(List<String> keys) {
    final telemetry = _mapValue('telemetry');
    final value =
        _firstValue(telemetry, keys) ??
        _firstValue(_overviewData ?? const {}, keys);

    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  num get _outputCurrent {
    return _numValue('outputCurrent') == 0
        ? _numValue('weldingCurrent')
        : _numValue('outputCurrent');
  }

  num get _inputVoltage {
    final inputVoltage = _mapValue('inputVoltage');
    final phaseVoltage = [
      _numFromMap(inputVoltage, 'R'),
      _numFromMap(inputVoltage, 'Y'),
      _numFromMap(inputVoltage, 'B'),
    ].fold<num>(0, max);

    if (phaseVoltage > 0) {
      return phaseVoltage;
    }

    return _numValue('inputVoltage');
  }

  DateTime? _dateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString().trim());
  }

  bool get _hasOpenTimelineEvent {
    return _productionTimeline.any((item) {
      if (item is! Map) return false;
      final map = Map<String, dynamic>.from(item);
      return _isOpenTimelineEvent(map);
    });
  }

  bool _isOpenTimelineEvent(Map<String, dynamic> map) {
    return _firstValue(map, const ['end', 'endTime', 'to', 'toTime']) == null;
  }

  bool get _isSelectedDateToday {
    final now = DateTime.now().toUtc();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String _formatDuration(num totalSeconds) {
    final duration = Duration(seconds: totalSeconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  _TimelineEvent _timelineEvent(dynamic item) {
    if (item is String) {
      return _TimelineEvent.fromText(item);
    }

    final map = item is Map<String, dynamic>
        ? item
        : item is Map
        ? Map<String, dynamic>.from(item)
        : const <String, dynamic>{};

    final start = _formatTimelineTime(
      _firstValue(map, const ['start', 'startTime', 'from', 'fromTime']),
    );
    final rawEnd = _firstValue(map, const ['end', 'endTime', 'to', 'toTime']);
    final end = rawEnd == null ? 'Now' : _formatTimelineTime(rawEnd);
    final rawStatus = _plainMetric(map, const [
      'status',
      'state',
      'mode',
      'type',
    ], 'UNKNOWN').toUpperCase();
    final status = _effectiveTimelineStatus(map, rawStatus);

    return _TimelineEvent(start: start, end: end, status: status);
  }

  String _formatTimelineTime(dynamic value) {
    if (value == null) return '--:--';

    if (value is num) {
      final duration = Duration(seconds: value.round());
      final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
      final minutes = duration.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      return '$hours:$minutes';
    }

    final text = value.toString().trim();
    if (text.isEmpty) return '--:--';

    final parsedDate = DateTime.tryParse(text);
    if (parsedDate != null) {
      return _timeText(parsedDate);
    }

    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (timeMatch != null) {
      final hour = timeMatch.group(1)!.padLeft(2, '0');
      final minute = timeMatch.group(2)!;
      return '$hour:$minute';
    }

    return text;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ARC':
      case 'ARCING':
      case 'WELDING':
        return const Color(0xFF16A34A);
      case 'IDLE':
        return const Color(0xFFF59E0B);
      case 'OFF':
      case 'OFFLINE':
      case 'OFF/OFFLINE':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _apiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _timeText(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showResetDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String successText,
    required Future<void> Function() onConfirm,
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
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await onConfirm();
                } on MachineServiceException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.message)));
                  return;
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(successText)));
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.start,
    required this.end,
    required this.status,
  });

  factory _TimelineEvent.fromText(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length >= 4) {
      return _TimelineEvent(
        start: parts[0],
        end: parts[2],
        status: parts.sublist(3).join(' ').toUpperCase(),
      );
    }

    return _TimelineEvent(start: '--:--', end: '--:--', status: text);
  }

  final String start;
  final String end;
  final String status;
}

class _TimelineSummary {
  const _TimelineSummary({
    required this.arcSeconds,
    required this.idleSeconds,
    required this.offSeconds,
    required this.offlineSeconds,
  });

  final int arcSeconds;
  final int idleSeconds;
  final int offSeconds;
  final int offlineSeconds;

  int get machineOnSeconds => arcSeconds + idleSeconds;

  int get trackedSeconds =>
      arcSeconds + idleSeconds + offSeconds + offlineSeconds;
}
