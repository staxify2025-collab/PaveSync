class VisionAnalyzerService {
  static bool get isSupported => false;
  static void startAnalyzing({
    required Function(String defectLabel, double confidence, double x, double y, double w, double h) onDefectDetected,
    required Function(String error) onError,
  }) {}
  static void stopAnalyzing() {}
}
