import 'package:flutter/material.dart';

import '../services/machine_service.dart';
import 'dashboard_card.dart';

class WelderAssignmentPanel extends StatefulWidget {
  const WelderAssignmentPanel({
    super.key,
    required this.machineId,
  });

  final String machineId;

  @override
  State<WelderAssignmentPanel> createState() => _WelderAssignmentPanelState();
}

class _WelderAssignmentPanelState extends State<WelderAssignmentPanel> {
  final _welderName = TextEditingController();
  final _employeeCode = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _activeAssignment;

  @override
  void initState() {
    super.initState();
    _loadActiveAssignment();
  }

  @override
  void dispose() {
    _welderName.dispose();
    _employeeCode.dispose();
    super.dispose();
  }

  Future<void> _loadActiveAssignment() async {
    try {
      setState(() => _loading = true);

      final rows = await MachineService.getActiveWelderAssignments(
        machineId: widget.machineId,
      );

      if (!mounted) return;

      setState(() {
        _activeAssignment = rows.isNotEmpty && rows.first is Map
            ? Map<String, dynamic>.from(rows.first as Map)
            : null;
      });
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startShift() async {
    if (_welderName.text.trim().isEmpty ||
        _employeeCode.text.trim().isEmpty) {
      _toast('Enter welder name and employee code');
      return;
    }

    try {
      setState(() => _loading = true);

      await MachineService.startManualWelderAssignment(
        machineId: widget.machineId,
        welderName: _welderName.text.trim(),
        employeeCode: _employeeCode.text.trim(),
      );

      _toast('Welder shift started');
      await _loadActiveAssignment();
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _endShift() async {
    final id = _activeAssignment?['id'];
    if (id == null) return;

    try {
      setState(() => _loading = true);

      await MachineService.endWelderAssignment(
        assignmentId: '$id',
      );

      _toast('Welder shift ended');

      if (!mounted) return;
      setState(() => _activeAssignment = null);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _value(dynamic value) {
    if (value == null) return '-';
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeAssignment;

    return DashboardCard(
      title: 'Welder Assignment',
      child: active == null ? _buildStartForm() : _buildActiveCard(active),
    );
  }

  Widget _buildStartForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Machine: ${widget.machineId}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _welderName,
          decoration: const InputDecoration(
            labelText: 'Welder Name',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _employeeCode,
          decoration: const InputDecoration(
            labelText: 'Employee Code',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading ? null : _startShift,
          child: Text(_loading ? 'Please wait...' : 'Start Shift'),
        ),
      ],
    );
  }

  Widget _buildActiveCard(Map<String, dynamic> active) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Machine: ${widget.machineId}'),
        const SizedBox(height: 8),
        Text(
          'Current Welder: ${_value(active['welderName'])} (${_value(active['employeeCode'])})',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text('Shift Started: ${_value(active['startedAt'])}'),
        const SizedBox(height: 8),
        Text('Tracking Mode: ${_value(active['trackingMode'])}'),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _loading ? null : _endShift,
          child: Text(_loading ? 'Please wait...' : 'End Shift'),
        ),
      ],
    );
  }
}
