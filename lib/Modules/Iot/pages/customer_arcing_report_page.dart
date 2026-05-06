import 'dart:async';

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
      debugPrint(
        '[reports] report filtered machine IDs: ${filteredSessions.map(_sessionMachineId).whereType<int>().toSet()}',
      );
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
    if (allowedMachineCodes == null) {
      return true;
    }

    if (allowedMachineCodes.isEmpty) {
      return false;
    }

    if (session is! Map) {
      return false;
    }

    final machine = session['machine'];
    if (machine is! Map) {
      return false;
    }

    final allowedMachineIds = widget.allowedMachineIds;
    final rawId = machine['id'] ?? machine['machineId'];
    final machineId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');
    if (allowedMachineIds != null &&
        allowedMachineIds.isNotEmpty &&
        machineId != null) {
      return allowedMachineIds.contains(machineId);
    }

    final code = (machine['machineCode'] ?? machine['code'] ?? '').toString();
    return allowedMachineCodes.contains(code);
  }

  int? _sessionMachineId(dynamic session) {
    if (session is! Map) return null;
    final machine = session['machine'];
    if (machine is! Map) return null;
    final rawId = machine['id'] ?? machine['machineId'];
    return rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
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
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: const Column(
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
                  'Only machine, welder, and live arcing time are shown.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Machine')),
          DataColumn(label: Text('Serial Number')),
          DataColumn(label: Text('Welder')),
          DataColumn(label: Text('Arcing Time')),
          DataColumn(label: Text('Status')),
        ],
        rows: _sessions.map((session) {
          final row = Map<String, dynamic>.from(session as Map);
          final machine = _safeMap(row['machine']);
          final welder = _safeMap(row['welder']);

          return DataRow(
            cells: [
              DataCell(Text((machine['machineCode'] ?? '-').toString())),
              DataCell(Text((machine['serialNumber'] ?? '-').toString())),
              DataCell(Text((welder['name'] ?? '-').toString())),
              DataCell(Text((row['arcingTime'] ?? '0:00:00').toString())),
              DataCell(Text((row['status'] ?? '-').toString())),
            ],
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }
}
