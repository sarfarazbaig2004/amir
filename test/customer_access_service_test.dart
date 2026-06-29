import 'package:flutter_test/flutter_test.dart';
import 'package:memco_iot_app/Modules/Iot/models/customer_access.dart';
import 'package:memco_iot_app/Modules/Iot/services/customer_access_service.dart';

void main() {
  group('CustomerAccessService.accessFromBackend', () {
    test('partitions flattened allowedFeatures into known categories', () {
      final access = CustomerAccessService.accessFromBackend(
        email: 'customer@example.com',
        accessJson: {
          'allowedFeatures': [
            'weldingCurrent',
            'futureRegularFeature',
            'liveLocation',
            'setCurrent',
            'downloadableReports',
          ],
        },
      );

      expect(access?.enabledFeatures, {
        'weldingCurrent',
        'futureRegularFeature',
      });
      expect(access?.enabledPremiumFeatures, {'liveLocation'});
      expect(access?.enabledButtons, {'setCurrent'});
      expect(access?.enabledReports, {'downloadableReports'});
    });

    test('prefers explicit category arrays, including empty arrays', () {
      final access = CustomerAccessService.accessFromBackend(
        email: 'customer@example.com',
        accessJson: {
          'allowedFeatures': [
            'temperature',
            'liveLocation',
            'setCurrent',
            'downloadableReports',
          ],
          'premiumFeatures': ['geoFencing'],
          'buttons': <String>[],
          'reports': ['liveWelderReports'],
        },
      );

      expect(access?.enabledFeatures, {'temperature'});
      expect(access?.enabledPremiumFeatures, {'geoFencing'});
      expect(access?.enabledButtons, isEmpty);
      expect(access?.enabledReports, {'liveWelderReports'});
    });

    test('restores every selection after save, reload, and reopen', () {
      const draft = CustomerAccess(
        customerId: '42',
        enabledModules: {'overview', 'reports'},
        allowedMachineCodes: {'WM-001'},
        allowedMachineIds: {2},
        enabledFeatures: {'weldingCurrent', 'warnings'},
        enabledParameters: {'fanSpeed'},
        enabledPremiumFeatures: {'liveLocation', 'geoFencing'},
        enabledButtons: {'setCurrent', 'assignRFID'},
        enabledReports: {'downloadableReports', 'liveWelderReports'},
      );
      final backendReload = {
        'allowedModules': draft.enabledModules.toList(),
        'allowedMachines': draft.allowedMachineCodes.toList(),
        'machineIds': draft.allowedMachineIds.toList(),
        'allowedFeatures': [
          ...draft.enabledFeatures,
          ...draft.enabledPremiumFeatures,
          ...draft.enabledButtons,
          ...draft.enabledReports,
        ],
        'allowedParameters': draft.enabledParameters.toList(),
      };

      final reloaded = CustomerAccessService.accessFromBackend(
        email: 'customer@example.com',
        customerId: draft.customerId,
        accessJson: backendReload,
      )!;
      final reopened = CustomerAccessService.accessFromBackend(
        email: 'customer@example.com',
        customerId: draft.customerId,
        accessJson: CustomerAccessService.accessToBackendJson(reloaded),
      )!;

      for (final restored in [reloaded, reopened]) {
        expect(restored.enabledModules, draft.enabledModules);
        expect(restored.allowedMachineCodes, draft.allowedMachineCodes);
        expect(restored.allowedMachineIds, draft.allowedMachineIds);
        expect(restored.enabledFeatures, draft.enabledFeatures);
        expect(restored.enabledParameters, draft.enabledParameters);
        expect(restored.enabledPremiumFeatures, draft.enabledPremiumFeatures);
        expect(restored.enabledButtons, draft.enabledButtons);
        expect(restored.enabledReports, draft.enabledReports);
      }
    });
  });
}
