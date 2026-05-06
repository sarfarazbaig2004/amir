class CustomerAccount {
  const CustomerAccount({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'CUSTOMER',
    this.company = 'MEMCO',
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String company;
}

class CustomerAccess {
  const CustomerAccess({
    required this.customerId,
    required this.enabledModules,
    required this.allowedMachineCodes,
    this.allMachines = false,
    this.allowedMachineIds = const {},
    this.enabledFeatures = const {},
    this.enabledParameters = const {},
    this.enabledButtons = const {},
    this.enabledReports = const {},
    this.enabledPremiumFeatures = const {},
    this.machineFeatureConfig = const {},
  });

  final String customerId;
  final Set<String> enabledModules;
  final Set<String> allowedMachineCodes;
  final bool allMachines;
  final Set<int> allowedMachineIds;
  final Set<String> enabledFeatures;
  final Set<String> enabledParameters;
  final Set<String> enabledButtons;
  final Set<String> enabledReports;
  final Set<String> enabledPremiumFeatures;
  final Map<String, MachineFeatureConfig> machineFeatureConfig;

  bool hasModule(String moduleKey) => enabledModules.contains(moduleKey);

  bool hasFeature(String featureKey) => enabledFeatures.contains(featureKey);

  bool hasParameter(String parameterKey) {
    return enabledParameters.contains(parameterKey);
  }

  bool hasButton(String buttonKey) => enabledButtons.contains(buttonKey);

  bool hasReport(String reportKey) => enabledReports.contains(reportKey);

  bool hasPremiumFeature(String featureKey) {
    return enabledPremiumFeatures.contains(featureKey);
  }

  bool canViewMachine(String machineCode) {
    if (allMachines) {
      return true;
    }
    if (allowedMachineCodes.isEmpty) {
      return false;
    }
    return allowedMachineCodes.contains(machineCode);
  }

  CustomerAccess copyWith({
    Set<String>? enabledModules,
    Set<String>? allowedMachineCodes,
    bool? allMachines,
    Set<int>? allowedMachineIds,
    Set<String>? enabledFeatures,
    Set<String>? enabledParameters,
    Set<String>? enabledButtons,
    Set<String>? enabledReports,
    Set<String>? enabledPremiumFeatures,
    Map<String, MachineFeatureConfig>? machineFeatureConfig,
  }) {
    return CustomerAccess(
      customerId: customerId,
      enabledModules: enabledModules ?? this.enabledModules,
      allowedMachineCodes: allowedMachineCodes ?? this.allowedMachineCodes,
      allMachines: allMachines ?? this.allMachines,
      allowedMachineIds: allowedMachineIds ?? this.allowedMachineIds,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      enabledParameters: enabledParameters ?? this.enabledParameters,
      enabledButtons: enabledButtons ?? this.enabledButtons,
      enabledReports: enabledReports ?? this.enabledReports,
      enabledPremiumFeatures:
          enabledPremiumFeatures ?? this.enabledPremiumFeatures,
      machineFeatureConfig: machineFeatureConfig ?? this.machineFeatureConfig,
    );
  }
}

class CustomerModule {
  const CustomerModule({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;
}

enum MachineType { singlePhase, threePhase }

enum InputVoltageMode { single, threePhase, hidden }

class MachineFeatureConfig {
  const MachineFeatureConfig({
    this.machineType = MachineType.threePhase,
    this.inputVoltageMode = InputVoltageMode.threePhase,
    this.showPhaseVoltageR = true,
    this.showPhaseVoltageY = true,
    this.showPhaseVoltageB = true,
    this.showInputVoltageSingle = false,
  });

  final MachineType machineType;
  final InputVoltageMode inputVoltageMode;
  final bool showPhaseVoltageR;
  final bool showPhaseVoltageY;
  final bool showPhaseVoltageB;
  final bool showInputVoltageSingle;

  bool get showVoltageSection {
    return inputVoltageMode != InputVoltageMode.hidden;
  }

  bool get shouldShowSingleVoltage {
    return showVoltageSection &&
        showInputVoltageSingle &&
        inputVoltageMode == InputVoltageMode.single;
  }

  bool get shouldShowThreePhaseVoltage {
    return showVoltageSection &&
        inputVoltageMode == InputVoltageMode.threePhase &&
        (showPhaseVoltageR || showPhaseVoltageY || showPhaseVoltageB);
  }

  MachineFeatureConfig copyWith({
    MachineType? machineType,
    InputVoltageMode? inputVoltageMode,
    bool? showPhaseVoltageR,
    bool? showPhaseVoltageY,
    bool? showPhaseVoltageB,
    bool? showInputVoltageSingle,
  }) {
    return MachineFeatureConfig(
      machineType: machineType ?? this.machineType,
      inputVoltageMode: inputVoltageMode ?? this.inputVoltageMode,
      showPhaseVoltageR: showPhaseVoltageR ?? this.showPhaseVoltageR,
      showPhaseVoltageY: showPhaseVoltageY ?? this.showPhaseVoltageY,
      showPhaseVoltageB: showPhaseVoltageB ?? this.showPhaseVoltageB,
      showInputVoltageSingle:
          showInputVoltageSingle ?? this.showInputVoltageSingle,
    );
  }
}
