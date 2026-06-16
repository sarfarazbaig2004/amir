import 'package:flutter/material.dart';

import '../models/customer_access.dart';
import '../services/customer_access_service.dart';
import '../services/machine_service.dart';

class CustomerAccessControlPage extends StatefulWidget {
  const CustomerAccessControlPage({super.key});

  @override
  State<CustomerAccessControlPage> createState() =>
      _CustomerAccessControlPageState();
}

class _CustomerAccessControlPageState extends State<CustomerAccessControlPage> {
  List<CustomerAccount> _customers = [];
  final Map<String, CustomerAccess> _accessByUserId = {};
  CustomerAccount? _selectedCustomer;
  CustomerAccess _draftAccess = const CustomerAccess(
    customerId: '',
    enabledModules: {},
    allowedMachineCodes: {},
  );
  List<Map<String, dynamic>> _machines = [];
  bool _isLoadingCustomers = true;
  bool _isLoadingMachines = true;
  bool _isLoadingAccess = false;
  bool _isSavingAccess = false;
  bool _isCreatingCustomer = false;
  int _accessLoadGeneration = 0;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadMachines();
  }

  Future<void> _loadCustomers() async {
    try {
      final data = await MachineService.getAdminCustomers();
      debugPrint('[access] reload payload: $data');
      final customers = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where(_isBackendCustomerRecord)
          .map(_customerFromBackend)
          .toList();

      if (!mounted) return;

      setState(() {
        _customers = customers;
        _accessByUserId.clear();
        _selectedCustomer = null;
        _draftAccess = const CustomerAccess(
          customerId: '',
          enabledModules: {},
          allowedMachineCodes: {},
        );
        _isLoadingCustomers = false;
      });

      if (customers.isNotEmpty) {
        _selectCustomer(customers.first);
      }
    } on MachineServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _customers = [];
        _accessByUserId.clear();
        _selectedCustomer = null;
        _draftAccess = const CustomerAccess(
          customerId: '',
          enabledModules: {},
          allowedMachineCodes: {},
        );
        _isLoadingCustomers = false;
      });
    }
  }

  Future<void> _loadMachines() async {
    try {
      final data = await MachineService.getFleetOverview();
      if (!mounted) return;
      setState(() {
        _machines = data
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList();

debugPrint('[access] fleet machines loaded: ${_machines.length}');
        _hydrateAccessMachineCodes();
        _isLoadingMachines = false;
      });
    } on MachineServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _isLoadingMachines = false;
      });
    }
  }

  Future<void> _selectCustomer(CustomerAccount customer) async {
    debugPrint('[access] selected customer email: ${customer.email}');
    final loadGeneration = ++_accessLoadGeneration;

    setState(() {
      _selectedCustomer = customer;
      _draftAccess = _emptyAccessForCustomer(customer);
      _isLoadingAccess = true;
      _message = 'Loading persisted access for ${customer.email}...';
    });

    try {
      final response = await MachineService.getAdminCustomerAccessByEmail(
        customer.email,
      );
      if (!mounted || loadGeneration != _accessLoadGeneration) return;

      final access = _hydrateAccessMachineCodesForAccess(
        _accessFromBackendUser(response, customer),
      );

      setState(() {
        _accessByUserId[customer.id] = access;
        _draftAccess = access;
        _isLoadingAccess = false;
        _message = '';
      });
    } on MachineServiceException catch (error) {
      if (!mounted || loadGeneration != _accessLoadGeneration) return;

      setState(() {
        _accessByUserId.remove(customer.id);
        _draftAccess = _emptyAccessForCustomer(customer);
        _isLoadingAccess = false;
        _message = error.message;
      });
    }
  }

  void _toggleModule(String moduleKey, bool enabled) {
    final modules = Set<String>.from(_draftAccess.enabledModules);
    if (enabled) {
      modules.add(moduleKey);
    } else {
      modules.remove(moduleKey);
    }

    setState(() {
      _draftAccess = _draftAccess.copyWith(enabledModules: modules);
    });
  }

  void _toggleMachine(String machineCode, bool enabled) {
    final machines = Set<String>.from(_draftAccess.allowedMachineCodes);
    final machineIds = Set<int>.from(_draftAccess.allowedMachineIds);
    final machineId = _machineIdForCode(machineCode);
    if (enabled) {
      machines.add(machineCode);
      if (machineId != null) {
        machineIds.add(machineId);
      }
    } else {
      machines.remove(machineCode);
      if (machineId != null) {
        machineIds.remove(machineId);
      }
    }

    setState(() {
      _draftAccess = _draftAccess.copyWith(
        allowedMachineCodes: machines,
        allowedMachineIds: machineIds,
      );
    });
  }

  void _toggleAccessSet(
    Set<String> currentValues,
    String key,
    bool enabled,
    CustomerAccess Function(Set<String> values) updateAccess,
  ) {
    final values = Set<String>.from(currentValues);
    if (enabled) {
      values.add(key);
    } else {
      values.remove(key);
    }

    setState(() {
      _draftAccess = updateAccess(values);
    });
  }

  void _replaceAccessSet(
    Set<String> values,
    CustomerAccess Function(Set<String> values) updateAccess,
  ) {
    setState(() {
      _draftAccess = updateAccess(values);
    });
  }

  void _setMachineConfig(String machineCode, MachineFeatureConfig config) {
    final configs = Map<String, MachineFeatureConfig>.from(
      _draftAccess.machineFeatureConfig,
    );
    configs[machineCode] = config;

    setState(() {
      _draftAccess = _draftAccess.copyWith(machineFeatureConfig: configs);
    });
  }

  Future<void> _saveAccess() async {
    final selectedCustomer = _selectedCustomer;
    if (selectedCustomer == null) return;

    final machineIds = _machineIdsForAccess(_draftAccess);

    debugPrint('[access] selected customer email: ${selectedCustomer.email}');
    debugPrint('[access] saved modules: ${_draftAccess.enabledModules}');
    debugPrint(
      '[access] saved machine codes: ${_draftAccess.allowedMachineCodes}',
    );
    debugPrint('[access] saved machine ids: $machineIds');

    setState(() {
      _isSavingAccess = true;
      _message = '';
    });

    try {
      final response = await MachineService.saveAdminCustomerAccessByEmail(
        email: selectedCustomer.email,
        modules: _draftAccess.enabledModules,
        machineCodes: _draftAccess.allowedMachineCodes,
        machineIds: machineIds,
        features: {
          ..._draftAccess.enabledFeatures,
          ..._draftAccess.enabledPremiumFeatures,
          ..._draftAccess.enabledButtons,
          ..._draftAccess.enabledReports,
        },
        parameters: _draftAccess.enabledParameters,
        premiumFeatures: _draftAccess.enabledPremiumFeatures,
        buttons: _draftAccess.enabledButtons,
        reports: _draftAccess.enabledReports,
      );
      if (!mounted) return;
      debugPrint('[access] save parsed response payload: $response');
      final reloadResponse = await MachineService.getAdminCustomerAccessByEmail(
        selectedCustomer.email,
      );
      if (!mounted) return;
      debugPrint('[access] post-save reload payload: $reloadResponse');
      final access = _hydrateAccessMachineCodesForAccess(
        _accessFromBackendUser(reloadResponse, selectedCustomer),
      );
      final verified = _accessMatchesDraft(
        savedAccess: access,
        draftAccess: _draftAccess,
        draftMachineIds: machineIds,
      );

      setState(() {
        _accessByUserId[selectedCustomer.id] = access;
        _draftAccess = access;
        _isSavingAccess = false;
        _message = verified
            ? 'Access saved for ${selectedCustomer.name}. Reload verified from backend.'
            : 'Access saved, but backend reload did not match the selected access.';
      });
    } on MachineServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _isSavingAccess = false;
      });
    }
  }

  Future<void> _createCustomer({
    required String name,
    required String email,
    required String password,
  }) async {
    setState(() {
      _isCreatingCustomer = true;
      _message = '';
    });

    try {
      await MachineService.createAdminCustomer(
        name: name,
        email: email,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _message = 'Customer created. Reloading backend customers.';
      });
      await _loadCustomers();
    } on MachineServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingCustomer = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 330, child: _buildCustomerList()),
              const SizedBox(width: 22),
              Expanded(child: _buildAccessPanel()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
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
            'Customer Access Control',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Choose what each customer can see: modules, reports, and specific machines.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Customers',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCreatingCustomer
                    ? null
                    : _showCreateCustomerDialog,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: Text(
                  _isCreatingCustomer ? 'Creating...' : 'Create Customer',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (_isLoadingCustomers)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (_customers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'No backend customer users found.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            for (final customer in _customers) _buildCustomerButton(customer),
        ],
      ),
    );
  }

  Widget _buildCustomerButton(CustomerAccount customer) {
    final selected = customer.id == _selectedCustomer?.id;
    final access = selected
        ? _draftAccess
        : _accessByUserId[customer.id] ??
              CustomerAccess(
                customerId: customer.id,
                enabledModules: const {},
                allowedMachineCodes: const {},
              );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _selectCustomer(customer),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.business_outlined,
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${access.enabledModules.length} modules · ${access.allowedMachineCodes.length} machines',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateCustomerDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final values =
          await showDialog<({String name, String email, String password})>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Create Customer'),
                content: Form(
                  key: formKey,
                  child: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Customer name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Customer name is required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return 'Email is required';
                            if (!text.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Password is required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) return;
                      Navigator.of(dialogContext).pop((
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                      ));
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          );

      if (values == null) return;
      await _createCustomer(
        name: values.name,
        email: values.email,
        password: values.password,
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Widget _buildAccessPanel() {
    final selectedCustomer = _selectedCustomer;
    if (_isLoadingCustomers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (selectedCustomer == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: const Text(
          'No backend customer selected.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCustomer.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCustomer.email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: (_isSavingAccess || _isLoadingAccess)
                    ? null
                    : _saveAccess,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  _isSavingAccess
                      ? 'Saving...'
                      : _isLoadingAccess
                      ? 'Loading...'
                      : 'Save Access',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _message,
              style: TextStyle(
                color: _message.startsWith('Access saved for')
                    ? const Color(0xFF047857)
                    : const Color(0xFFB91C1C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 24),
          DefaultTabController(
            length: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Modules'),
                    Tab(text: 'Machines'),
                    Tab(text: 'Feature'),
                    Tab(text: 'Parameter'),
                    Tab(text: 'Voltage Display'),
                    Tab(text: 'Premium Features'),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 620,
                  child: TabBarView(
                    children: [
                      _buildOptionTab(
                        title: 'Module Access',
                        options: CustomerAccessService.modules,
                        selected: _draftAccess.enabledModules,
                        onChanged: _toggleModule,
                        onSelectAll: () => _replaceAccessSet(
                          CustomerAccessService.modules
                              .map((item) => item.key)
                              .toSet(),
                          (values) =>
                              _draftAccess.copyWith(enabledModules: values),
                        ),
                        onClearAll: () => _replaceAccessSet(
                          const {'reports'},
                          (values) =>
                              _draftAccess.copyWith(enabledModules: values),
                        ),
                      ),
                      _buildMachinesTab(),
                      _buildOptionTab(
                        title: 'Feature Access',
                        options: CustomerAccessService.features,
                        selected: _draftAccess.enabledFeatures,
                        onChanged: (key, enabled) => _toggleAccessSet(
                          _draftAccess.enabledFeatures,
                          key,
                          enabled,
                          (values) =>
                              _draftAccess.copyWith(enabledFeatures: values),
                        ),
                        onSelectAll: () => _replaceAccessSet(
                          CustomerAccessService.features
                              .map((item) => item.key)
                              .toSet(),
                          (values) =>
                              _draftAccess.copyWith(enabledFeatures: values),
                        ),
                        onClearAll: () => _replaceAccessSet(
                          const {},
                          (values) =>
                              _draftAccess.copyWith(enabledFeatures: values),
                        ),
                      ),
                      _buildOptionTab(
                        title: 'Parameter Access',
                        options: CustomerAccessService.parameters,
                        selected: _draftAccess.enabledParameters,
                        onChanged: (key, enabled) => _toggleAccessSet(
                          _draftAccess.enabledParameters,
                          key,
                          enabled,
                          (values) =>
                              _draftAccess.copyWith(enabledParameters: values),
                        ),
                        onSelectAll: () => _replaceAccessSet(
                          CustomerAccessService.parameters
                              .map((item) => item.key)
                              .toSet(),
                          (values) =>
                              _draftAccess.copyWith(enabledParameters: values),
                        ),
                        onClearAll: () => _replaceAccessSet(
                          const {},
                          (values) =>
                              _draftAccess.copyWith(enabledParameters: values),
                        ),
                      ),
                      _buildVoltageDisplayTab(),
                      _buildOptionTab(
                        title: 'Premium Features',
                        options: [
                          ...CustomerAccessService.premiumFeatures,
                          ...CustomerAccessService.buttons,
                          ...CustomerAccessService.reports,
                        ],
                        selected: {
                          ..._draftAccess.enabledPremiumFeatures,
                          ..._draftAccess.enabledButtons,
                          ..._draftAccess.enabledReports,
                        },
                        onChanged: _togglePremiumOption,
                        onSelectAll: _selectAllPremiumOptions,
                        onClearAll: _clearAllPremiumOptions,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTab({
    required String title,
    required List<CustomerModule> options,
    required Set<String> selected,
    required void Function(String key, bool enabled) onChanged,
    required VoidCallback onSelectAll,
    required VoidCallback onClearAll,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader(title, onSelectAll, onClearAll),
          const SizedBox(height: 12),
          for (final option in options)
            _buildAccessToggle(
              option,
              selected.contains(option.key),
              (enabled) => onChanged(option.key, enabled),
            ),
        ],
      ),
    );
  }

  Widget _buildTabHeader(
    String title,
    VoidCallback onSelectAll,
    VoidCallback onClearAll,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        OutlinedButton(onPressed: onSelectAll, child: const Text('Select All')),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onClearAll, child: const Text('Clear All')),
      ],
    );
  }

  Widget _buildMachinesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader(
            'Machine Access',
            () => _replaceAccessSet(
              _machines
                  .map(_machineCode)
                  .where((code) => code.isNotEmpty)
                  .toSet(),
              (values) => _draftAccess.copyWith(allowedMachineCodes: values),
            ),
            () => _replaceAccessSet(
              const {},
              (values) => _draftAccess.copyWith(allowedMachineCodes: values),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingMachines)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else
            _buildMachineSelector(),
        ],
      ),
    );
  }

  Widget _buildVoltageDisplayTab() {
    if (_isLoadingMachines) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleMachines = _machines
        .where(
          (machine) =>
              _draftAccess.allowedMachineCodes.contains(_machineCode(machine)),
        )
        .toList();

    if (visibleMachines.isEmpty) {
      return const Center(
        child: Text(
          'Select machines before configuring voltage display.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader(
            'Voltage Display',
            () {
              final features = {
                ..._draftAccess.enabledFeatures,
                ...CustomerAccessService.voltageFeatureKeys,
              };
              setState(() {
                _draftAccess = _draftAccess.copyWith(enabledFeatures: features);
              });
            },
            () {
              final features = Set<String>.from(_draftAccess.enabledFeatures)
                ..removeAll(CustomerAccessService.voltageFeatureKeys);
              setState(() {
                _draftAccess = _draftAccess.copyWith(enabledFeatures: features);
              });
            },
          ),
          const SizedBox(height: 12),
          for (final machine in visibleMachines)
            _buildVoltageMachineConfig(_machineCode(machine), machine),
        ],
      ),
    );
  }

  Widget _buildVoltageMachineConfig(
    String machineCode,
    Map<String, dynamic> machine,
  ) {
    final config =
        _draftAccess.machineFeatureConfig[machineCode] ??
        const MachineFeatureConfig();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            machineCode,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildDropdown<MachineType>(
                label: 'Machine type',
                value: config.machineType,
                values: MachineType.values,
                labelFor: _machineTypeLabel,
                onChanged: (value) {
                  if (value == null) return;
                  _setMachineConfig(
                    machineCode,
                    config.copyWith(machineType: value),
                  );
                },
              ),
              _buildDropdown<InputVoltageMode>(
                label: 'Input voltage mode',
                value: config.inputVoltageMode,
                values: InputVoltageMode.values,
                labelFor: _inputVoltageModeLabel,
                onChanged: (value) {
                  if (value == null) return;
                  _setMachineConfig(
                    machineCode,
                    config.copyWith(inputVoltageMode: value),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildConfigSwitch(
                'Show single input',
                config.showInputVoltageSingle,
                (value) => _setMachineConfig(
                  machineCode,
                  config.copyWith(showInputVoltageSingle: value),
                ),
              ),
              _buildConfigSwitch(
                'Show R',
                config.showPhaseVoltageR,
                (value) => _setMachineConfig(
                  machineCode,
                  config.copyWith(showPhaseVoltageR: value),
                ),
              ),
              _buildConfigSwitch(
                'Show Y',
                config.showPhaseVoltageY,
                (value) => _setMachineConfig(
                  machineCode,
                  config.copyWith(showPhaseVoltageY: value),
                ),
              ),
              _buildConfigSwitch(
                'Show B',
                config.showPhaseVoltageB,
                (value) => _setMachineConfig(
                  machineCode,
                  config.copyWith(showPhaseVoltageB: value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T value) labelFor,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        items: values
            .map(
              (item) =>
                  DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildConfigSwitch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SizedBox(
      width: 180,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  String _machineTypeLabel(MachineType value) {
    switch (value) {
      case MachineType.singlePhase:
        return 'SINGLE_PHASE';
      case MachineType.threePhase:
        return 'THREE_PHASE';
    }
  }

  String _inputVoltageModeLabel(InputVoltageMode value) {
    switch (value) {
      case InputVoltageMode.single:
        return 'SINGLE';
      case InputVoltageMode.threePhase:
        return 'THREE_PHASE';
      case InputVoltageMode.hidden:
        return 'HIDDEN';
    }
  }

  void _togglePremiumOption(String key, bool enabled) {
    final premiumKeys = CustomerAccessService.premiumFeatures
        .map((item) => item.key)
        .toSet();
    final buttonKeys = CustomerAccessService.buttons
        .map((item) => item.key)
        .toSet();
    final reportKeys = CustomerAccessService.reports
        .map((item) => item.key)
        .toSet();

    if (premiumKeys.contains(key)) {
      _toggleAccessSet(
        _draftAccess.enabledPremiumFeatures,
        key,
        enabled,
        (values) => _draftAccess.copyWith(enabledPremiumFeatures: values),
      );
    } else if (buttonKeys.contains(key)) {
      _toggleAccessSet(
        _draftAccess.enabledButtons,
        key,
        enabled,
        (values) => _draftAccess.copyWith(enabledButtons: values),
      );
    } else if (reportKeys.contains(key)) {
      _toggleAccessSet(
        _draftAccess.enabledReports,
        key,
        enabled,
        (values) => _draftAccess.copyWith(enabledReports: values),
      );
    }
  }

  void _selectAllPremiumOptions() {
    setState(() {
      _draftAccess = _draftAccess.copyWith(
        enabledPremiumFeatures: CustomerAccessService.premiumFeatures
            .map((item) => item.key)
            .toSet(),
        enabledButtons: CustomerAccessService.buttons
            .map((item) => item.key)
            .toSet(),
        enabledReports: CustomerAccessService.reports
            .map((item) => item.key)
            .toSet(),
      );
    });
  }

  void _clearAllPremiumOptions() {
    setState(() {
      _draftAccess = _draftAccess.copyWith(
        enabledPremiumFeatures: const {},
        enabledButtons: const {},
        enabledReports: const {},
      );
    });
  }

  Widget _buildAccessToggle(
    CustomerModule option,
    bool enabled,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune_outlined,
              color: enabled
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.description,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineSelector() {
    if (_machines.isEmpty) {
      return const Text(
        'No machines found from fleet API.',
        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _machines.map((machine) {
        final code = _machineCode(machine);
        final serial = (machine['serialNumber'] ?? '-').toString();
        final selected = _draftAccess.allowedMachineCodes.contains(code);

        return SizedBox(
          width: 260,
          child: CheckboxListTile(
            value: selected,
            onChanged: (value) => _toggleMachine(code, value ?? false),
            title: Text(
              code,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              serial,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            tileColor: selected
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF8FAFC),
          ),
        );
      }).toList(),
    );
  }

  String _machineCode(Map<String, dynamic> machine) {
    return (machine['code'] ?? machine['machineCode'] ?? '').toString();
  }

  int? _machineIdForCode(String machineCode) {
    for (final machine in _machines) {
      if (_machineCode(machine) != machineCode) continue;
      final id = machine['id'] ?? machine['machineId'];
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? '');
    }
    return null;
  }

  String? _machineCodeForId(int machineId) {
    for (final machine in _machines) {
      final id = machine['id'] ?? machine['machineId'];
      final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
      if (parsedId == machineId) {
        final code = _machineCode(machine).trim();
        return code.isEmpty ? null : code;
      }
    }
    return null;
  }

  CustomerAccess _hydrateAccessMachineCodesForAccess(CustomerAccess access) {
    final machineCodes = Set<String>.from(access.allowedMachineCodes);

    for (final machineId in access.allowedMachineIds) {
      final code = _machineCodeForId(machineId);
      if (code != null) {
        machineCodes.add(code);
      }
    }

    if (machineCodes.length == access.allowedMachineCodes.length) {
      return access;
    }

    return access.copyWith(allowedMachineCodes: machineCodes);
  }

  void _hydrateAccessMachineCodes() {
    if (_machines.isEmpty) return;

    _accessByUserId.updateAll(
      (_, access) => _hydrateAccessMachineCodesForAccess(access),
    );

    _draftAccess = _hydrateAccessMachineCodesForAccess(_draftAccess);
  }

  Set<int> _machineIdsForAccess(CustomerAccess access) {
    final machineIds = Set<int>.from(access.allowedMachineIds);

    for (final machineCode in access.allowedMachineCodes) {
      final machineId = _machineIdForCode(machineCode);
      if (machineId != null) {
        machineIds.add(machineId);
      }
    }

    return machineIds;
  }

  bool _accessMatchesDraft({
    required CustomerAccess savedAccess,
    required CustomerAccess draftAccess,
    required Set<int> draftMachineIds,
  }) {
    return _setEquals(savedAccess.enabledModules, draftAccess.enabledModules) &&
        _setEquals(
          savedAccess.allowedMachineCodes,
          draftAccess.allowedMachineCodes,
        ) &&
        _setEquals(savedAccess.allowedMachineIds, draftMachineIds) &&
        _setEquals(savedAccess.enabledFeatures, draftAccess.enabledFeatures) &&
        _setEquals(
          savedAccess.enabledParameters,
          draftAccess.enabledParameters,
        ) &&
        _setEquals(
          savedAccess.enabledPremiumFeatures,
          draftAccess.enabledPremiumFeatures,
        ) &&
        _setEquals(savedAccess.enabledButtons, draftAccess.enabledButtons) &&
        _setEquals(savedAccess.enabledReports, draftAccess.enabledReports);
  }

  bool _setEquals<T>(Set<T> left, Set<T> right) {
    if (left.length != right.length) return false;
    return left.containsAll(right);
  }

  CustomerAccess _emptyAccessForCustomer(CustomerAccount customer) {
    return CustomerAccess(
      customerId: customer.id,
      enabledModules: const {},
      allowedMachineCodes: const {},
      allowedMachineIds: const {},
    );
  }

  CustomerAccount _customerFromBackend(Map<String, dynamic> user) {
    final nestedUser = user['user'] is Map
        ? Map<String, dynamic>.from(user['user'] as Map)
        : const <String, dynamic>{};
    final id =
        user['id']?.toString() ??
        user['customerId']?.toString() ??
        nestedUser['customerId']?.toString() ??
        nestedUser['id']?.toString() ??
        '';
    final email =
        user['email']?.toString() ?? nestedUser['email']?.toString() ?? '';
    return CustomerAccount(
      id: id,
      name: user['name']?.toString() ?? nestedUser['name']?.toString() ?? email,
      email: email,
      role:
          user['role']?.toString() ??
          nestedUser['role']?.toString() ??
          'CUSTOMER',
    );
  }

  bool _isBackendCustomerRecord(Map<String, dynamic> item) {
    final nestedUser = item['user'] is Map
        ? Map<String, dynamic>.from(item['user'] as Map)
        : const <String, dynamic>{};
    final role = (item['role'] ?? nestedUser['role'] ?? 'CUSTOMER')
        .toString()
        .toUpperCase();
    final email = (item['email'] ?? nestedUser['email'] ?? '').toString();

    if (email.trim().isEmpty) {
      return false;
    }

    return role == 'CUSTOMER';
  }

  CustomerAccess _accessFromBackendUser(
    Map<String, dynamic> data,
    CustomerAccount customer,
  ) {
    final accessJson = _accessJsonFromBackend(data);
    debugPrint(
      '[access] parsed reload payload for ${customer.email}: $accessJson',
    );
    final access = CustomerAccessService.accessFromBackend(
      email: customer.email,
      customerId: customer.id,
      accessJson: accessJson,
    );

    return access ??
        CustomerAccess(
          customerId: customer.id,
          enabledModules: const {},
          allowedMachineCodes: const {},
        );
  }

  Map<String, dynamic> _accessJsonFromBackend(Map<String, dynamic> data) {
    if (data['access'] is Map) {
      return Map<String, dynamic>.from(data['access'] as Map);
    }

    return {
      'modules':
          data['modules'] ?? data['allowedModules'] ?? data['moduleAccess'],
      'machines':
          data['machines'] ?? data['allowedMachines'] ?? data['machineAccess'],
      'machineIds':
          data['machineIds'] ??
          data['allowedMachineIds'] ??
          data['machineIdAccess'] ??
          data['machineAccess'],
      'allMachines': data['allMachines'],
      'features':
          data['features'] ?? data['allowedFeatures'] ?? data['featureAccess'],
      'parameters':
          data['parameters'] ??
          data['allowedParameters'] ??
          data['parameterAccess'],
      'premiumFeatures':
          data['premiumFeatures'] ?? data['allowedPremiumFeatures'],
      'buttons': data['buttons'] ?? data['allowedButtons'],
      'reports': data['reports'] ?? data['allowedReports'],
    };
  }
}
