import 'package:flutter_test/flutter_test.dart';
import 'package:pavesync_ai/models/distress.dart';
import 'package:pavesync_ai/services/formulas/pci_calculator.dart';
import 'package:pavesync_ai/services/formulas/fdot_pcs_calc.dart';

void main() {
  group('PaveSync AI Compliance Calculations', () {
    test('PCI is 100 for segment with no distresses', () {
      final pci = PciCalculator.calculate([]);
      expect(pci, 100.0);
    });

    test('PCI drops for segment with potholes', () {
      final potholeDistress = DistressRecord(
        id: '1',
        category: DistressCategory.pavement,
        specificType: PavementDistressType.pothole.name,
        severity: SeverityLevel.high,
        quantity: 2,
        unit: 'count',
        latitude: 32.0,
        longitude: -86.0,
        timestamp: DateTime.now(),
      );

      final pci = PciCalculator.calculate([potholeDistress]);
      // High severity pothole should deduct significant points
      expect(pci, lessThan(80.0));
    });

    test('FDOT Crack Rating starts at 10.0 and drops with alligator cracking', () {
      final crackDistress = DistressRecord(
        id: '2',
        category: DistressCategory.pavement,
        specificType: PavementDistressType.alligatorCracking.name,
        severity: SeverityLevel.medium,
        quantity: 15.0, // 15% area
        unit: '%',
        latitude: 32.0,
        longitude: -86.0,
        timestamp: DateTime.now(),
      );

      final crackRating = FdotPcsCalculator.calculateCrackRating([crackDistress]);
      // Deduct should be: 15% * 0.15 = 2.25. Score = 10.0 - 2.25 = 7.75 -> rounded to 7.8
      expect(crackRating, closeTo(7.8, 0.1));
    });

    test('FDOT Rut Rating drops as rut depth increases', () {
      final shallowRut = DistressRecord(
        id: '3',
        category: DistressCategory.pavement,
        specificType: PavementDistressType.rutting.name,
        severity: SeverityLevel.low,
        quantity: 0.2, // 0.2 inches
        unit: 'in',
        latitude: 32.0,
        longitude: -86.0,
        timestamp: DateTime.now(),
      );

      final deepRut = DistressRecord(
        id: '4',
        category: DistressCategory.pavement,
        specificType: PavementDistressType.rutting.name,
        severity: SeverityLevel.high,
        quantity: 0.7, // 0.7 inches
        unit: 'in',
        latitude: 32.0,
        longitude: -86.0,
        timestamp: DateTime.now(),
      );

      final rating1 = FdotPcsCalculator.calculateRutRating([shallowRut]);
      final rating2 = FdotPcsCalculator.calculateRutRating([deepRut]);

      expect(rating1, 10.0);
      expect(rating2, 4.0); // 0.7 inches is between 0.625" and 0.75" which maps to 4.0
    });
  });
}
