import 'dart:js' as js;

class VisionAnalyzerService {
  static bool get isSupported => true;

  static void startAnalyzing({
    required Function(String defectLabel, double confidence, double x, double y, double w, double h) onDefectDetected,
    required Function(String error) onError,
  }) {
    try {
      js.context.callMethod('startVisualRoadAnalyzer', [
        (defectLabel, confidence, x, y, w, h) {
          onDefectDetected(
            defectLabel.toString(),
            (confidence as num).toDouble(),
            (x as num).toDouble(),
            (y as num).toDouble(),
            (w as num).toDouble(),
            (h as num).toDouble(),
          );
        },
        (error) {
          onError(error.toString());
        }
      ]);
    } catch (e) {
      onError(e.toString());
    }
  }

  static void stopAnalyzing() {
    try {
      js.context.callMethod('stopVisualRoadAnalyzer');
    } catch (_) {}
  }
}
