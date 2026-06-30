class PaserCalculator {
  /// Maps a PASER rating (1-10) to its standard descriptive condition
  /// and recommended treatment according to the PASER Manual.
  static String getCondition(int rating) {
    if (rating >= 9) return 'Excellent';
    if (rating >= 7) return 'Good';
    if (rating >= 5) return 'Fair';
    if (rating >= 3) return 'Poor';
    return 'Failed';
  }

  static String getRecommendedTreatment(int rating) {
    switch (rating) {
      case 10:
        return 'No maintenance required';
      case 9:
        return 'Recent construction. No maintenance required.';
      case 8:
        return 'Little or no maintenance. Routine maintenance.';
      case 7:
        return 'Crack sealing and minor patching.';
      case 6:
        return 'Sealcoat or non-structural overlay (thin overlay).';
      case 5:
        return 'Milling and overlay (1.5" to 2.0" thickness).';
      case 4:
        return 'Structural overlay (hot mix asphalt) or extensive patching.';
      case 3:
        return 'Structural overlay with base repair or recycling.';
      case 2:
        return 'Reconstruction with base repair / pulverization.';
      case 1:
        return 'Total reconstruction.';
      default:
        return 'Invalid Rating';
    }
  }

  /// Estimates the PASER rating based on a calculated ASTM PCI score.
  /// Standard correlation mapping (PCI to PASER).
  static int estimatePaserFromPci(double pci) {
    if (pci >= 95.0) return 10;
    if (pci >= 85.0) return 9;
    if (pci >= 75.0) return 8;
    if (pci >= 65.0) return 7;
    if (pci >= 55.0) return 6;
    if (pci >= 45.0) return 5;
    if (pci >= 35.0) return 4;
    if (pci >= 25.0) return 3;
    if (pci >= 10.0) return 2;
    return 1;
  }
}
