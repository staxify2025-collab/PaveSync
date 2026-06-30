import '../../models/distress.dart';

class FdotPcsCalculator {
  /// Calculates the FDOT Crack Rating (0 to 10 scale)
  /// 10.0 represents no cracking.
  static double calculateCrackRating(List<DistressRecord> distresses) {
    double deduct = 0.0;

    final crackingList = distresses.where((d) =>
        d.specificType == PavementDistressType.alligatorCracking.name ||
        d.specificType == PavementDistressType.blockCracking.name ||
        d.specificType == PavementDistressType.edgeCracking.name ||
        d.specificType == PavementDistressType.longitudinalTransverseCracking.name);

    for (var distress in crackingList) {
      double factor = 0.05; // Class 1B / Low severity
      if (distress.severity == SeverityLevel.medium) {
        factor = 0.15; // Class II / Medium severity
      } else if (distress.severity == SeverityLevel.high) {
        factor = 0.35; // Class III / High severity
      }

      // Quantity represents percentage area affected or linear feet
      double quantityVal = distress.quantity;
      if (distress.unit == 'ft') {
        // Convert linear feet to estimated percentage for a 100m (328ft) segment
        quantityVal = (distress.quantity / 328.0) * 100.0;
      }
      
      deduct += (quantityVal.clamp(0.0, 100.0) * factor);
    }

    double score = 10.0 - deduct;
    if (score < 0.0) score = 0.0;
    if (score > 10.0) score = 10.0;

    return double.parse(score.toStringAsFixed(1));
  }

  /// Calculates the FDOT Rut Rating (0 to 10 scale)
  /// Quantity represents average rut depth in inches.
  static double calculateRutRating(List<DistressRecord> distresses) {
    final rutting = distresses.where((d) => d.specificType == PavementDistressType.rutting.name);
    if (rutting.isEmpty) return 10.0;

    double maxDepth = 0.0;
    for (var r in rutting) {
      if (r.quantity > maxDepth) {
        maxDepth = r.quantity;
      }
    }

    double rating = 10.0;
    if (maxDepth <= 0.25) {
      rating = 10.0;
    } else if (maxDepth <= 0.375) {
      rating = 9.0;
    } else if (maxDepth <= 0.5) {
      rating = 8.0;
    } else if (maxDepth <= 0.625) {
      rating = 6.0;
    } else if (maxDepth <= 0.75) {
      rating = 4.0;
    } else {
      rating = 2.0;
    }

    return rating;
  }

  /// Calculates the FDOT Ride Rating (0 to 10 scale) based on IRI (inches/mile)
  /// Quantity represents IRI value.
  static double calculateRideRating(double? iriValue) {
    if (iriValue == null) return 10.0;

    // Standard FDOT Ride Rating from IRI:
    // Ride = 10.0 - (IRI * 0.04) clamped
    double score = 10.0 - (iriValue * 0.04);
    if (score < 0.0) score = 0.0;
    if (score > 10.0) score = 10.0;

    return double.parse(score.toStringAsFixed(1));
  }
}
