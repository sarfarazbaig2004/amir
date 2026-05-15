import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../services/machine_service.dart';
import '../widgets/dashboard_card.dart';

class MachineEngineeringPage extends StatefulWidget {
  const MachineEngineeringPage({super.key, this.machineId});

  final String? machineId;

  @override
  State<MachineEngineeringPage> createState() => _MachineEngineeringPageState();
}

class _MachineEngineeringPageState extends State<MachineEngineeringPage> {
  String get _activeMachineId => widget.machineId ?? AppConfig.defaultMachineId;

  final _acLow = TextEditingController();
  final _acLowLow = TextEditingController();
  final _acHigh = TextEditingController();
  final _acHighHigh = TextEditingController();

  final _temp1H = TextEditingController();
  final _temp1HH = TextEditingController();
  final _temp2H = TextEditingController();
  final _temp2HH = TextEditingController();
  final _temp3H = TextEditingController();
  final _temp3HH = TextEditingController();

  final _depositionCoefficient = TextEditingController();
  final _machineRatedCurrentLimit = TextEditingController();
  final _machineRatedCurrent = TextEditingController();

  final _normalFanPulsePerMin = TextEditingController();
  final _wireFeedPulseCount = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEngineeringSetpoints();
  }

  @override
  void dispose() {
    _acLow.dispose();
    _acLowLow.dispose();
    _acHigh.dispose();
    _acHighHigh.dispose();

    _temp1H.dispose();
    _temp1HH.dispose();
    _temp2H.dispose();
    _temp2HH.dispose();
    _temp3H.dispose();
    _temp3HH.dispose();

    _depositionCoefficient.dispose();
    _machineRatedCurrentLimit.dispose();
    _machineRatedCurrent.dispose();

    _normalFanPulsePerMin.dispose();
    _wireFeedPulseCount.dispose();

    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    );
  }

  num? _numberFrom(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return num.tryParse(text);
  }

  String _textFrom(dynamic value) {
    if (value == null) return '';
    return '$value';
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadEngineeringSetpoints() async {
    try {
      setState(() => _loading = true);

      final data = await MachineService.getEngineeringSetpoints(
        _activeMachineId,
      );

      _applySetpoints(data['setpoints']);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _readAllSetpoints() async {
    try {
      setState(() => _loading = true);

      final data = await MachineService.readAllEngineeringSetpoints(
        _activeMachineId,
      );

      _applySetpoints(data['setpoints']);
      _toast('Read all setpoints completed');
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySetpoints(dynamic rawSetpoints) {
    final setpoints = Map<String, dynamic>.from(rawSetpoints ?? {});

    final ac = Map<String, dynamic>.from(
      setpoints['acVoltageThresholds'] ?? {},
    );
    final temp = Map<String, dynamic>.from(
      setpoints['temperatureThresholds'] ?? {},
    );
    final parameter = Map<String, dynamic>.from(
      setpoints['parameterSettings'] ?? {},
    );
    final fan = Map<String, dynamic>.from(
      setpoints['fanAndWirefeed'] ?? {},
    );

    _acLow.text = _textFrom(ac['acLow']);
    _acLowLow.text = _textFrom(ac['acLowLow']);
    _acHigh.text = _textFrom(ac['acHigh']);
    _acHighHigh.text = _textFrom(ac['acHighHigh']);

    _temp1H.text = _textFrom(temp['temp1H']);
    _temp1HH.text = _textFrom(temp['temp1HH']);
    _temp2H.text = _textFrom(temp['temp2H']);
    _temp2HH.text = _textFrom(temp['temp2HH']);
    _temp3H.text = _textFrom(temp['temp3H']);
    _temp3HH.text = _textFrom(temp['temp3HH']);

    _depositionCoefficient.text =
        _textFrom(parameter['depositionCoefficient']);
    _machineRatedCurrentLimit.text =
        _textFrom(parameter['machineRatedCurrentLimit']);
    _machineRatedCurrent.text =
        _textFrom(parameter['machineRatedCurrent']);

    _normalFanPulsePerMin.text =
        _textFrom(fan['normalFanPulsePerMin']);
    _wireFeedPulseCount.text =
        _textFrom(fan['wireFeedPulseCount']);
  }

  Future<void> _saveEngineeringSetpoints({
    Map<String, dynamic>? acVoltageThresholds,
    Map<String, dynamic>? temperatureThresholds,
    Map<String, dynamic>? parameterSettings,
    Map<String, dynamic>? fanAndWirefeed,
    String successMessage = 'Setpoints saved',
  }) async {
    try {
      setState(() => _loading = true);

      final payload = <String, dynamic>{};

      if (acVoltageThresholds != null) {
        payload['acVoltageThresholds'] = acVoltageThresholds;
      }
      if (temperatureThresholds != null) {
        payload['temperatureThresholds'] = temperatureThresholds;
      }
      if (parameterSettings != null) {
        payload['parameterSettings'] = parameterSettings;
      }
      if (fanAndWirefeed != null) {
        payload['fanAndWirefeed'] = fanAndWirefeed;
      }

      final data = await MachineService.saveEngineeringSetpoints(
        machineId: _activeMachineId,
        payload: payload,
      );

      _applySetpoints(data['setpoints']);
      _toast(successMessage);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.clear();
    }
  }

  Widget _actionButtons({
    required VoidCallback onSubmit,
    required VoidCallback onClear,
  }) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _loading ? null : onSubmit,
          child: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('submit'),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: _loading ? null : onClear,
          child: const Text('clear'),
        ),
      ],
    );
  }

  Widget _numberField(
    String hint,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _fieldDecoration(hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Machine $_activeMachineId',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
                      TextField(decoration: _fieldDecoration('dd/mm/yyyy')),
                      const SizedBox(height: 12),
                      TextField(decoration: _fieldDecoration('--:--')),
                      const SizedBox(height: 16),
                      _actionButtons(
                        onSubmit: () => _toast(
                          'Date/time command will be connected in next phase',
                        ),
                        onClear: () {},
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _readAllSetpoints,
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
                      _numberField('AC Low', _acLow),
                      const SizedBox(height: 12),
                      _numberField('AC Low Low', _acLowLow),
                      const SizedBox(height: 12),
                      _numberField('AC High', _acHigh),
                      const SizedBox(height: 12),
                      _numberField('AC High High', _acHighHigh),
                      const SizedBox(height: 16),
                      _actionButtons(
                        onSubmit: () => _saveEngineeringSetpoints(
                          acVoltageThresholds: {
                            'acLow': _numberFrom(_acLow),
                            'acLowLow': _numberFrom(_acLowLow),
                            'acHigh': _numberFrom(_acHigh),
                            'acHighHigh': _numberFrom(_acHighHigh),
                          },
                          successMessage: 'AC voltage thresholds saved',
                        ),
                        onClear: () => _clearControllers([
                          _acLow,
                          _acLowLow,
                          _acHigh,
                          _acHighHigh,
                        ]),
                      ),
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
                      _numberField('Temp 1 H', _temp1H),
                      const SizedBox(height: 12),
                      _numberField('Temp 1 HH', _temp1HH),
                      const SizedBox(height: 12),
                      _numberField('Temp 2 H', _temp2H),
                      const SizedBox(height: 12),
                      _numberField('Temp 2 HH', _temp2HH),
                      const SizedBox(height: 12),
                      _numberField('Temp 3 H', _temp3H),
                      const SizedBox(height: 12),
                      _numberField('Temp 3 HH', _temp3HH),
                      const SizedBox(height: 16),
                      _actionButtons(
                        onSubmit: () => _saveEngineeringSetpoints(
                          temperatureThresholds: {
                            'temp1H': _numberFrom(_temp1H),
                            'temp1HH': _numberFrom(_temp1HH),
                            'temp2H': _numberFrom(_temp2H),
                            'temp2HH': _numberFrom(_temp2HH),
                            'temp3H': _numberFrom(_temp3H),
                            'temp3HH': _numberFrom(_temp3HH),
                          },
                          successMessage: 'Temperature thresholds saved',
                        ),
                        onClear: () => _clearControllers([
                          _temp1H,
                          _temp1HH,
                          _temp2H,
                          _temp2HH,
                          _temp3H,
                          _temp3HH,
                        ]),
                      ),
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
                          _numberField(
                            'Deposition Coefficient',
                            _depositionCoefficient,
                          ),
                          const SizedBox(height: 12),
                          _actionButtons(
                            onSubmit: () => _saveEngineeringSetpoints(
                              parameterSettings: {
                                'depositionCoefficient':
                                    _numberFrom(_depositionCoefficient),
                              },
                              successMessage:
                                  'Deposition coefficient saved',
                            ),
                            onClear: () => _clearControllers([
                              _depositionCoefficient,
                            ]),
                          ),
                          const SizedBox(height: 16),
                          _numberField(
                            'Machine rated Current Limit',
                            _machineRatedCurrentLimit,
                          ),
                          const SizedBox(height: 12),
                          _actionButtons(
                            onSubmit: () => _saveEngineeringSetpoints(
                              parameterSettings: {
                                'machineRatedCurrentLimit':
                                    _numberFrom(_machineRatedCurrentLimit),
                              },
                              successMessage:
                                  'Machine rated current limit saved',
                            ),
                            onClear: () => _clearControllers([
                              _machineRatedCurrentLimit,
                            ]),
                          ),
                          const SizedBox(height: 16),
                          _numberField(
                            'Machine Rated Current',
                            _machineRatedCurrent,
                          ),
                          const SizedBox(height: 12),
                          _actionButtons(
                            onSubmit: () => _saveEngineeringSetpoints(
                              parameterSettings: {
                                'machineRatedCurrent':
                                    _numberFrom(_machineRatedCurrent),
                              },
                              successMessage:
                                  'Machine rated current saved',
                            ),
                            onClear: () => _clearControllers([
                              _machineRatedCurrent,
                            ]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'Fan and Wirefeed',
                      child: Column(
                        children: [
                          _numberField(
                            'Normal Fan Pulse per min',
                            _normalFanPulsePerMin,
                          ),
                          const SizedBox(height: 12),
                          _numberField(
                            'Wire Feed Pulse Count',
                            _wireFeedPulseCount,
                          ),
                          const SizedBox(height: 16),
                          _actionButtons(
                            onSubmit: () => _saveEngineeringSetpoints(
                              fanAndWirefeed: {
                                'normalFanPulsePerMin':
                                    _numberFrom(_normalFanPulsePerMin),
                                'wireFeedPulseCount':
                                    _numberFrom(_wireFeedPulseCount),
                              },
                              successMessage:
                                  'Fan and wirefeed settings saved',
                            ),
                            onClear: () => _clearControllers([
                              _normalFanPulsePerMin,
                              _wireFeedPulseCount,
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}