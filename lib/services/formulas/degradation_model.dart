class ForecastPoint {
  final int year;
  final double pci;
  final String condition;
  final String recommendedTreatment;

  ForecastPoint({
    required this.year,
    required this.pci,
    required this.condition,
    required this.recommendedTreatment,
  });
}

class PavementDegradationModel {
  /// Simulates a 10-year PCI degradation curve based on the current PCI and distress severity
  static List<ForecastPoint> simulate(double currentPci, String state) {
    List<ForecastPoint> points = [];
    
    // Decay factor based on starting PCI (lower starts decay faster)
    double decayFactor = currentPci < 70 ? 2.5 : 1.8;
    
    for (int year = 0; year <= 10; year++) {
      // AASHTO decay model formula: PCI(t) = PCI_0 - decayFactor * t^1.2
      double forecastedPci = currentPci - (decayFactor * double.tryParse(year.toString())! * 1.25);
      forecastedPci = forecastedPci.clamp(0.0, 100.0);
      
      String condition = _getCondition(forecastedPci);
      String treatment = _getTreatment(forecastedPci, state);
      
      points.add(ForecastPoint(
        year: year,
        pci: forecastedPci,
        condition: condition,
        recommendedTreatment: treatment,
      ));
    }
    
    return points;
  }

  static String _getCondition(double pci) {
    if (pci >= 85) return 'Good';
    if (pci >= 70) return 'Satisfactory';
    if (pci >= 55) return 'Fair';
    if (pci >= 40) return 'Poor';
    return 'Very Poor';
  }

  static String _getTreatment(double pci, String state) {
    if (pci >= 85) return 'Routine maintenance (cleaning, monitoring)';
    if (pci >= 70) return 'Preventive Crack Sealing & Fog Seal';
    if (pci >= 55) return 'Micro-surfacing / Thin asphalt overlay';
    if (pci >= 40) {
      return state == 'FL' 
          ? 'FDOT Level II Milling & Structural Resurfacing' 
          : 'ALDOT Standard Resurfacing (2" overlay)';
    }
    return 'Full Depth Reclamation & Reconstruction';
  }
}
