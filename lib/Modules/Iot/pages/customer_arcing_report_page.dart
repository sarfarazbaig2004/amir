import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../services/machine_service.dart';

class CustomerArcingReportPage extends StatefulWidget {
  const CustomerArcingReportPage({
    super.key,
    required this.allowedMachineCodes,
    required this.allowedMachineIds,
  });

  final Set<String>? allowedMachineCodes;
  final Set<int>? allowedMachineIds;

  @override
  State<CustomerArcingReportPage> createState() =>
      _CustomerArcingReportPageState();
}

class _CustomerArcingReportPageState extends State<CustomerArcingReportPage> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadReport();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadReport(showLoader: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _exportCsv() {
    final date = DateTime.now().toIso8601String().split('T').first;
    final url =
        'https://api.iot.memcoin.com/api/reports/welder-arc-events.csv?date=$date';

    html.AnchorElement(href: url)
      ..setAttribute('download', 'welder-arc-report.csv')
      ..click();
  }

  void _exportPdf() {
    final date = DateTime.now().toIso8601String().split('T').first;
    final url =
        'https://api.iot.memcoin.com/api/reports/welder-arc-events.pdf?date=$date';

    html.AnchorElement(href: url)
      ..setAttribute('download', 'welder-arc-report.pdf')
      ..click();
  }

  Future<void> _loadReport({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final sessions = await MachineService.getLiveWelderSessions();
      final filteredSessions = sessions.where(_isSessionAllowed).toList();

      if (!mounted) return;

      setState(() {
        _sessions = filteredSessions;
        _isLoading = false;
        _errorMessage = '';
      });
    } on MachineServiceException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  bool _isSessionAllowed(dynamic session) {
    final allowedMachineCodes = widget.allowedMachineCodes;
    final allowedMachineIds = widget.allowedMachineIds;

    if (allowedMachineCodes == null && allowedMachineIds == null) {
      return true;
    }

    if ((allowedMachineCodes?.isEmpty ?? true) &&
        (allowedMachineIds?.isEmpty ?? true)) {
      return false;
    }

    if (session is! Map) return false;

    final machine = session['machine'];
    if (machine is! Map) return false;

    final rawId = machine['id'] ?? machine['machineId'];
    final machineId =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    if (allowedMachineIds != null &&
        allowedMachineIds.isNotEmpty &&
        machineId != null) {
      return allowedMachineIds.contains(machineId);
    }

    final code = (machine['machineCode'] ?? machine['code'] ?? '').toString();
    return allowedMachineCodes?.contains(code) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 18),
          _buildSummaryCards(),
          const SizedBox(height: 18),
          if (_errorMessage.isNotEmpty)
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            _buildReportTable(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Arcing Time Report',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Live welding sessions with current, voltage, and arcing time.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final activeWelders = _sessions.length;

    final totalArcSeconds = _sessions.fold<int>(0, (sum, session) {
      final row = _safeMap(session);
      return sum + _parseDurationToSeconds(row['arcingTime']);
    });

    final avgCurrent = _sessions.isEmpty
        ? 0
        : _sessions.fold<num>(0, (sum, session) {
              final row = _safeMap(session);
              return sum + _toNum(row['current']);
            }) /
            _sessions.length;

    final avgVoltage = _sessions.isEmpty
        ? 0
        : _sessions.fold<num>(0, (sum, session) {
              final row = _safeMap(session);
              return sum + _toNum(row['voltage']);
            }) /
            _sessions.length;

    return Row(
      children: [
        _summaryCard('Active Welders', activeWelders.toString()),
        const SizedBox(width: 14),
        _summaryCard('Total Arc Time', _formatSeconds(totalArcSeconds)),
        const SizedBox(width: 14),
        _summaryCard('Average Current', '${avgCurrent.toStringAsFixed(0)} A'),
        const SizedBox(width: 14),
        _summaryCard('Average Voltage', '${avgVoltage.toStringAsFixed(0)} V'),
      ],
    );
  }

  Widget _summaryCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTable() {
    if (_sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: const Text(
          'No active welder sessions for the machines enabled for this customer.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Machine')),
            DataColumn(label: Text('Serial Number')),
            DataColumn(label: Text('Welder')),
            DataColumn(label: Text('Arc Start')),
            DataColumn(label: Text('Live Arc Time')),
            DataColumn(label: Text('Current')),
            DataColumn(label: Text('Voltage')),
            DataColumn(label: Text('Status')),
          ],
          rows: _sessions.map((session) {
            final row = _safeMap(session);
            final machine = _safeMap(row['machine']);
            final welder = _safeMap(row['welder']);

            final current = _toNum(row['current']);
            final voltage = _toNum(row['voltage']);

            return DataRow(
              cells: [
                DataCell(Text((machine['machineCode'] ?? '-').toString())),
                DataCell(Text((machine['serialNumber'] ?? '-').toString())),
                DataCell(Text((welder['name'] ?? '-').toString())),
                DataCell(Text(_formatDateTime(row['startedAt']))),
                DataCell(Text((row['arcingTime'] ?? '0:00:00').toString())),
                DataCell(Text('${current.toStringAsFixed(0)} A')),
                DataCell(Text('${voltage.toStringAsFixed(0)} V')),
                DataCell(_statusBadge((row['status'] ?? '-').toString())),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalizedStatus = status.toUpperCase();

    Color backgroundColor = const Color(0xFFE5E7EB);
    Color textColor = const Color(0xFF374151);

    if (normalizedStatus == 'ACTIVE' || normalizedStatus == 'WELDING') {
      backgroundColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
    } else if (normalizedStatus == 'IDLE') {
      backgroundColor = const Color(0xFFDBEAFE);
      textColor = const Color(0xFF1D4ED8);
    } else if (normalizedStatus == 'OFFLINE') {
      backgroundColor = const Color(0xFFE5E7EB);
      textColor = const Color(0xFF4B5563);
    } else if (normalizedStatus == 'OVERHEAT' || normalizedStatus == 'CRITICAL') {
      backgroundColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF991B1B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalizedStatus,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
  }

  num _toNum(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '-';

    final dateTime = DateTime.tryParse(value.toString());
    if (dateTime == null) return value.toString();

    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }

  int _parseDurationToSeconds(dynamic value) {
    final text = value?.toString() ?? '0:00:00';
    final parts = text.split(':');

    if (parts.length != 3) return 0;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    return (hours * 3600) + (minutes * 60) + seconds;
  }

  String _formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}