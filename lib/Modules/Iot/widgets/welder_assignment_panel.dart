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
  final _welderNameController = TextEditingController();
  final _employeeCodeController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _activeAssignment;

  @override
  void initState() {
    super.initState();
    _loadActiveAssignment();
  }

  @override
  void dispose() {
    _welderNameController.dispose();
    _employeeCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveAssignment() async {
    try {
      setState(() => _isLoading = true);

      final dynamic response = await MachineService.getActiveWelderAssignments(
        machineId: widget.machineId,
      );

      if (!mounted) return;

      List<dynamic> rows = [];
      if (response is List) {
        rows = response;
      } else if (response is Map && response['data'] is List) {
        rows = response['data'] as List<dynamic>;
      }

      setState(() {
        if (rows.isNotEmpty && rows.first is Map) {
          _activeAssignment = Map<String, dynamic>.from(rows.first as Map);
        } else {
          _activeAssignment = null;
        }
      });
    } catch (e) {
      debugPrint('WelderAssignmentPanel Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startShift() async {
    final name = _welderNameController.text.trim();
    final code = _employeeCodeController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      _toast('Enter welder name and employee code');
      return;
    }

    try {
      setState(() => _isLoading = true);

      await MachineService.startManualWelderAssignment(
        machineId: widget.machineId,
        welderName: name,
        employeeCode: code,
      );

      _toast('Welder shift started');
      _welderNameController.clear();
      _employeeCodeController.clear();
      
      await _loadActiveAssignment();
    } catch (e) {
      _toast('Error starting shift: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _endShift() async {
    final id = _activeAssignment?['id'];
    if (id == null) return;

    try {
      setState(() => _isLoading = true);

      await MachineService.endWelderAssignment(
        assignmentId: '$id',
      );

      _toast('Welder shift ended');

      if (!mounted) return;
      setState(() => _activeAssignment = null);
    } catch (e) {
      _toast('Error ending shift: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _displayValue(dynamic value) {
    if (value == null || '$value'.trim().isEmpty) return '-';
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Welder Assignment',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isLoading && _activeAssignment == null
            ? const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
            : (_activeAssignment == null
                ? _buildStartForm()
                : _buildActiveCard(_activeAssignment!)),
      ),
    );
  }

  Widget _buildStartForm() {
    return Column(
      key: const ValueKey('start_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Machine ID: ${widget.machineId}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _welderNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Welder Name',
            border: OutlineInputBorder(),
            isDense: true,
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _employeeCodeController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _isLoading ? null : _startShift(),
          decoration: const InputDecoration(
            labelText: 'Employee Code',
            border: OutlineInputBorder(),
            isDense: true,
            prefixIcon: Icon(Icons.badge_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _startShift,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start Shift'),
        ),
      ],
    );
  }

  Widget _buildActiveCard(Map<String, dynamic> active) {
    return Column(
      key: const ValueKey('active_card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Machine: ${widget.machineId}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Current Welder:',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Text(
          '${_displayValue(active['welderName'])} (${_displayValue(active['employeeCode'])})',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Divider(height: 24),
        _buildInfoRow('Shift Started', _displayValue(active['startedAt'])),
        const SizedBox(height: 6),
        _buildInfoRow('Tracking Mode', _displayValue(active['trackingMode'])),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _isLoading ? null : _endShift,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.red.shade300),
            foregroundColor: Colors.red[700],
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                )
              : const Text('End Shift'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}
