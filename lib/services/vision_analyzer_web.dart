import 'dart:js' as js;

class VisionAnalyzerService {
  static bool get isSupported => true;

  static void startAnalyzing({
    required Function(String defectLabel, double confidence) onDefectDetected,
    required Function(String error) onError,
  }) {
    try {
      js.context.callMethod('startVisualRoadAnalyzer', [
        (defectLabel, confidence) {
          onDefectDetected(
            defectLabel.toString(),
            (confidence as num).toDouble(),
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
