import '../../models/distress.dart';

class PciCalculator {
  /// Calculates the Pavement Condition Index (PCI) on a 0-100 scale
  /// based on ASTM D6433 / AASHTO guidelines.
  static double calculate(List<DistressRecord> distresses) {
    if (distresses.isEmpty) return 100.0;

    // Filter to only pavement distresses
    final pavementDistresses = distresses
        .where((d) => d.category == DistressCategory.pavement)
        .toList();

    if (pavementDistresses.isEmpty) return 100.0;

    List<double> deductValues = [];

    for (var distress in pavementDistresses) {
      double deduct = _getDeductValue(distress.specificType, distress.severity, distress.quantity);
      deductValues.add(deduct);
    }

    // Sort deduct values in descending order
    deductValues.sort((a, b) => b.compareTo(a));

    // Calculate Maximum Allowable Number of Deducts (m)
    // and compute corrected deduct value (CDV) using ASTM D6433 curves
    double totalDeduct = deductValues.fold(0.0, (sum, val) => sum + val);
    
    // Apply simplified ASTM correction factor for multiple distresses
    // to prevent PCI from dropping below 0
    double cdv = _applyCorrection(deductValues);
    
    double pci = 100.0 - cdv;
    if (pci < 0) pci = 0.0;
    if (pci > 100) pci = 100.0;

    return double.parse(pci.toStringAsFixed(1));
  }

  /// Estimates standard deduct values based on severity and quantity/density
  static double _getDeductValue(String specificType, SeverityLevel severity, double quantity) {
    // Basic base deduct factors depending on distress type severity
    double baseFactor = 1.0;
    
    if (specificType == PavementDistressType.pothole.name) {
      // Potholes have high deducts
      baseFactor = severity == SeverityLevel.high ? 45.0 : (severity == SeverityLevel.medium ? 25.0 : 10.0);
      return baseFactor * (quantity > 5 ? 1.5 : 1.0); // quantity represents count
    } else if (specificType == PavementDistressType.alligatorCracking.name) {
      // Alligator cracking is a major load-associated distress
      baseFactor = severity == SeverityLevel.high ? 35.0 : (severity == SeverityLevel.medium ? 20.0 : 8.0);
      // quantity represents percentage area affected
      double density = quantity.clamp(0.1, 100.0);
      return baseFactor + (density * 0.25);
    } else if (specificType == PavementDistressType.rutting.name) {
      // Rutting is a major structural defect
      baseFactor = severity == SeverityLevel.high ? 40.0 : (severity == SeverityLevel.medium ? 22.0 : 10.0);
      return baseFactor;
    } else if (specificType == PavementDistressType.blockCracking.name || 
               specificType == PavementDistressType.longitudinalTransverseCracking.name) {
      baseFactor = severity == SeverityLevel.high ? 20.0 : (severity == SeverityLevel.medium ? 10.0 : 4.0);
      return baseFactor;
    } else {
      // General distress deducts
      baseFactor = severity == SeverityLevel.high ? 15.0 : (severity == SeverityLevel.medium ? 8.0 : 3.0);
      return baseFactor;
    }
  }

  /// Correction curves for multiple distresses (ASTM D6433 Figure 4.14)
  static double _applyCorrection(List<double> deducts) {
    if (deducts.isEmpty) return 0.0;
    if (deducts.length == 1) return deducts[0];

    double sum = deducts.fold(0.0, (s, val) => s + val);
    int q = deducts.where((d) => d > 2.0).length; // Number of deducts > 2.0

    if (q <= 1) return sum;

    // Simplified ASTM D6433 correction function:
    // As the number of distresses (q) increases, the impact of their sum decreases
    double correctionFactor = 1.0;
    if (q == 2) {
      correctionFactor = 0.8;
    } else if (q == 3) {
      correctionFactor = 0.65;
    } else if (q == 4) {
      correctionFactor = 0.55;
    } else {
      correctionFactor = 0.45;
    }

    return sum * correctionFactor;
  }
}
