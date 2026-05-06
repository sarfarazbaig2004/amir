import 'package:flutter/foundation.dart';

import '../models/customer_access.dart';

class CustomerAccessService {
  static final Map<String, CustomerAccess> _runtimeAccessByEmail = {};
  static final Map<String, CustomerAccess> _accessByCustomerId = {};

  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static const Set<String> voltageFeatureKeys = {
    'inputVoltageSingle',
    'inputVoltageR',
    'inputVoltageY',
    'inputVoltageB',
    'inputVoltageSection',
    'acVoltageTrend',
    'phaseVoltageCards',
  };

  static const List<CustomerModule> modules = [
    CustomerModule(
      key: 'reports',
      label: 'Reports',
      description: 'Customer arcing report and live welder summary.',
    ),
    CustomerModule(
      key: 'fleet',
      label: 'Fleet',
      description: 'Allowed machine cards and status.',
    ),
    CustomerModule(
      key: 'overview',
      label: 'Overview',
      description: 'Machine details, welding data, voltage, and temperature.',
    ),
    CustomerModule(
      key: 'production',
      label: 'Production',
      description: 'Running job, lifetime, and production values.',
    ),
  ];

  static const List<CustomerModule> features = [
    CustomerModule(
      key: 'inputVoltageSection',
      label: 'Input voltage section',
      description: 'Allows input voltage data to be displayed.',
    ),
    CustomerModule(
      key: 'inputVoltageSingle',
      label: 'Single input voltage',
      description: 'Shows one input voltage value for single-phase machines.',
    ),
    CustomerModule(
      key: 'inputVoltageR',
      label: 'R phase voltage',
      description: 'Shows R phase input voltage.',
    ),
    CustomerModule(
      key: 'inputVoltageY',
      label: 'Y phase voltage',
      description: 'Shows Y phase input voltage.',
    ),
    CustomerModule(
      key: 'inputVoltageB',
      label: 'B phase voltage',
      description: 'Shows B phase input voltage.',
    ),
    CustomerModule(
      key: 'acVoltageTrend',
      label: 'AC voltage trend',
      description: 'Shows AC voltage chart section.',
    ),
    CustomerModule(
      key: 'phaseVoltageCards',
      label: 'Phase voltage cards',
      description: 'Shows compact voltage cards above the chart.',
    ),
    CustomerModule(
      key: 'weldingCurrent',
      label: 'Welding current',
      description: 'Shows live welding current.',
    ),
    CustomerModule(
      key: 'weldingVoltage',
      label: 'Welding voltage',
      description: 'Shows live welding voltage.',
    ),
    CustomerModule(
      key: 'temperature',
      label: 'Temperature',
      description: 'Shows temperature section.',
    ),
    CustomerModule(
      key: 'alarms',
      label: 'Alarms',
      description: 'Shows alarm section and alarm data.',
    ),
    CustomerModule(
      key: 'warnings',
      label: 'Warnings',
      description: 'Shows warning section and warning data.',
    ),
    CustomerModule(
      key: 'productionTimeline',
      label: 'Production timeline',
      description: 'Shows production timeline events.',
    ),
    CustomerModule(
      key: 'utilizationPercent',
      label: 'Utilization %',
      description: 'Shows utilization percentage.',
    ),
  ];

  static const List<CustomerModule> parameters = [
    CustomerModule(
      key: 'trafoCoreTemperature',
      label: 'Trafo core temperature',
      description: 'Allows trafo core temperature value.',
    ),
    CustomerModule(
      key: 'igbtTemperature',
      label: 'IGBT temperature',
      description: 'Allows IGBT temperature value.',
    ),
    CustomerModule(
      key: 'heatSyncTemperature',
      label: 'Heat sync temperature',
      description: 'Allows heat sync temperature value.',
    ),
    CustomerModule(
      key: 'fanSpeed',
      label: 'Fan speed',
      description: 'Allows fan speed value.',
    ),
    CustomerModule(
      key: 'arcTime',
      label: 'Arc time',
      description: 'Allows arc time production metric.',
    ),
    CustomerModule(
      key: 'machineOnTime',
      label: 'Machine ON time',
      description: 'Allows machine on time production metric.',
    ),
    CustomerModule(
      key: 'idleTime',
      label: 'Idle time',
      description: 'Allows idle time production metric.',
    ),
    CustomerModule(
      key: 'offlineTime',
      label: 'Offline time',
      description: 'Allows offline production metric.',
    ),
    CustomerModule(
      key: 'arcEfficiencyPercent',
      label: 'Arc efficiency %',
      description: 'Allows arc efficiency percentage.',
    ),
  ];

  static const List<CustomerModule> buttons = [
    CustomerModule(
      key: 'setCurrent',
      label: 'Set current',
      description: 'Allows current setpoint action.',
    ),
    CustomerModule(
      key: 'setTemperature',
      label: 'Set temperature',
      description: 'Allows temperature setpoint action.',
    ),
    CustomerModule(
      key: 'assignRFID',
      label: 'Assign RFID',
      description: 'Allows welder RFID assignment.',
    ),
  ];

  static const List<CustomerModule> reports = [
    CustomerModule(
      key: 'downloadableReports',
      label: 'Downloadable reports',
      description: 'Allows report downloads.',
    ),
    CustomerModule(
      key: 'liveWelderReports',
      label: 'Live welder reports',
      description: 'Allows live welder report data.',
    ),
  ];

  static const List<CustomerModule> premiumFeatures = [
    CustomerModule(
      key: 'liveLocation',
      label: 'Live location',
      description: 'Shows live machine location.',
    ),
    CustomerModule(
      key: 'geoFencing',
      label: 'Geo fencing',
      description: 'Enables geo fencing controls.',
    ),
    CustomerModule(
      key: 'rfidWelderIdentification',
      label: 'RFID welder identification',
      description: 'Shows welder RFID section.',
    ),
    CustomerModule(
      key: 'engineeringSetpoints',
      label: 'Engineering setpoints',
      description: 'Allows engineering setpoint module.',
    ),
    CustomerModule(
      key: 'calibrationAccess',
      label: 'Calibration access',
      description: 'Allows logger calibration module.',
    ),
    CustomerModule(
      key: 'remoteParameterSetting',
      label: 'Remote parameter setting',
      description: 'Allows remote parameter changes.',
    ),
  ];

  static const Set<String> allFeatureKeys = {
    'inputVoltageSingle',
    'inputVoltageR',
    'inputVoltageY',
    'inputVoltageB',
    'inputVoltageSection',
    'acVoltageTrend',
    'phaseVoltageCards',
    'liveLocation',
    'geoFencing',
    'rfidWelderIdentification',
    'weldingCurrent',
    'weldingVoltage',
    'arcTime',
    'machineOnTime',
    'idleTime',
    'offlineTime',
    'productionTimeline',
    'utilizationPercent',
    'arcEfficiencyPercent',
    'alarms',
    'warnings',
    'fanSpeed',
    'temperature',
    'trafoCoreTemperature',
    'igbtTemperature',
    'heatSyncTemperature',
    'engineeringSetpoints',
    'calibrationAccess',
    'remoteParameterSetting',
    'downloadableReports',
  };

  static CustomerAccess accessForCustomerId(String customerId) {
    return _accessByCustomerId[customerId] ??
        CustomerAccess(
          customerId: customerId,
          enabledModules: const {},
          allowedMachineCodes: const {},
          allowedMachineIds: const {},
        );
  }

  static CustomerAccess accessForEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();

    final runtimeAccess = _runtimeAccessByEmail[normalizedEmail];
    if (runtimeAccess != null) {
      return runtimeAccess;
    }

    return CustomerAccess(
      customerId: normalizedEmail,
      enabledModules: const {},
      allowedMachineCodes: const {},
      allowedMachineIds: const {},
    );
  }

  static CustomerAccess? accessFromBackend({
    required String email,
    required Map<String, dynamic>? accessJson,
    String? customerId,
  }) {
    if (accessJson == null) return null;

    final normalizedEmail = email.trim().toLowerCase();
    final machineCodesJson =
        accessJson['machines'] ?? accessJson['allowedMachines'];
    final machineIdsJson =
        accessJson['machineIds'] ??
        accessJson['allowedMachineIds'] ??
        machineCodesJson;

    return CustomerAccess(
      customerId: customerId ?? normalizedEmail,
      enabledModules: _stringSet(
        accessJson['modules'] ?? accessJson['allowedModules'],
      ),
      allowedMachineCodes: _machineCodeSet(machineCodesJson),
      allowedMachineIds: _machineIdSet(machineIdsJson),
      allMachines: accessJson['allMachines'] == true,
      enabledFeatures: _stringSet(
        accessJson['features'] ?? accessJson['allowedFeatures'],
      ),
      enabledParameters: _stringSet(
        accessJson['parameters'] ?? accessJson['allowedParameters'],
      ),
      enabledPremiumFeatures: _stringSet(
        accessJson['premiumFeatures'] ?? accessJson['allowedPremiumFeatures'],
      ),
      enabledButtons: _stringSet(
        accessJson['buttons'] ?? accessJson['allowedButtons'],
      ),
      enabledReports: _stringSet(
        accessJson['reports'] ?? accessJson['allowedReports'],
      ),
    );
  }

  static Map<String, dynamic> accessToBackendJson(CustomerAccess access) {
    return {
      'modules': access.enabledModules.toList()..sort(),
      'machines': access.allowedMachineCodes.toList()..sort(),
      'machineIds': access.allowedMachineIds.toList()..sort(),
      'allMachines': access.allMachines,
      'features': access.enabledFeatures.toList()..sort(),
      'parameters': access.enabledParameters.toList()..sort(),
      'premiumFeatures': access.enabledPremiumFeatures.toList()..sort(),
      'buttons': access.enabledButtons.toList()..sort(),
      'reports': access.enabledReports.toList()..sort(),
    };
  }

  static void overwriteAccessForEmail(String email, CustomerAccess access) {
    _runtimeAccessByEmail[email.trim().toLowerCase()] = access;
    version.value++;
  }

  static void clearRuntimeAccess() {
    _runtimeAccessByEmail.clear();
    version.value++;
  }

  static void saveAccess(CustomerAccess access) {
    _accessByCustomerId[access.customerId] = access;
    version.value++;
  }

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) return const {};

    return value
        .map((item) {
          if (item is Map) {
            return (item['moduleKey'] ??
                    item['featureKey'] ??
                    item['parameterKey'] ??
                    item['premiumFeatureKey'] ??
                    item['buttonKey'] ??
                    item['reportKey'] ??
                    item['key'] ??
                    item['id'] ??
                    '')
                .toString()
                .trim();
          }

          return item.toString().trim();
        })
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  static Set<String> _machineCodeSet(dynamic value) {
    if (value is! List) return const {};

    return value
        .map((item) {
          if (item is Map) {
            final machine = item['machine'] ?? item['Machine'];

            if (machine is Map) {
              return (machine['machineCode'] ?? machine['code'] ?? '')
                  .toString()
                  .trim();
            }

            return (item['machineCode'] ?? item['code'] ?? '')
                .toString()
                .trim();
          }

          final raw = item.toString().trim();

          if (int.tryParse(raw) != null) {
            return '';
          }

          return raw;
        })
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  static Set<int> _machineIdSet(dynamic value) {
    if (value is! List) return const {};

    return value
        .map((item) {
          if (item is Map) {
            final machine = item['machine'] ?? item['Machine'];

            if (machine is Map) {
              final id = machine['id'] ?? machine['machineId'];
              if (id is int) return id;
              return int.tryParse(id?.toString() ?? '');
            }

            final id = item['id'] ?? item['machineId'];
            if (id is int) return id;
            return int.tryParse(id?.toString() ?? '');
          }

          return int.tryParse(item.toString());
        })
        .whereType<int>()
        .toSet();
  }
}
