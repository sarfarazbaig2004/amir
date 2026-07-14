import 'package:flutter_test/flutter_test.dart';
import 'package:memco_iot_app/Modules/Iot/services/machine_service.dart';

void main() {
  group('MachineService simulator compatibility', () {
    test('normalizes simulator production aliases without losing values', () {
      final normalized = MachineService.normalizeMachineOverviewResponse({
        'machineCode': 'WM-001',
        'outputCurrent': 142.5,
        'outputVoltage': 24.8,
        'runningJob': {
          'arcTime': '0:12:16',
          'idleTime': '0:00:42',
          'arcCount': 9,
          'dcEnergy': 1.75,
          'deposition': 0.22,
        },
        'lifetime': {
          'arcTime': '12:00:00',
          'idleTime': '3:00:00',
          'arcCount': 120,
        },
      });

      expect(normalized['weldingCurrent'], 142.5);
      expect(normalized['weldingVoltage'], 24.8);
      expect(normalized['outputCurrent'], 142.5);
      expect(normalized['outputVoltage'], 24.8);
      expect(normalized['runningJob']['arcingTime'], '0:12:16');
      expect(normalized['runningJob']['arcCount'], 9);
      expect(normalized['machineLifetime']['arcingTime'], '12:00:00');
      expect(normalized['machineLifetime']['arcCount'], 120);
    });

    test(
      'preserves canonical fields when the backend already supplies them',
      () {
        final normalized = MachineService.normalizeMachineOverviewResponse({
          'weldingCurrent': 150,
          'weldingVoltage': 26,
          'outputCurrent': 140,
          'outputVoltage': 24,
          'runningJob': {'arcingTime': '0:00:10', 'arcTime': '0:00:09'},
          'machineLifetime': {'arcingTime': '1:00:00'},
          'lifetime': {'arcTime': '0:30:00'},
        });

        expect(normalized['weldingCurrent'], 150);
        expect(normalized['weldingVoltage'], 26);
        expect(normalized['runningJob']['arcingTime'], '0:00:10');
        expect(normalized['machineLifetime']['arcingTime'], '1:00:00');
      },
    );
  });
}
