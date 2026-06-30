import 'dart:js' as js;

class VibrationSensorService {
  static bool get isSupported => true;

  static void startListening({
    required Function(double magnitude) onSpike,
    required Function(String error) onError,
  }) {
    try {
      js.context.callMethod('startVibrationSensor', [
        (magnitude) {
          onSpike((magnitude as num).toDouble());
        },
        (error) {
          onError(error.toString());
        }
      ]);
    } catch (e) {
      onError(e.toString());
    }
  }

  static void stopListening() {
    try {
      js.context.callMethod('stopVibrationSensor');
    } catch (_) {}
  }
}
