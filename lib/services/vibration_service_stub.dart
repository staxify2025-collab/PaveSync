class VibrationSensorService {
  static bool get isSupported => false;
  static void startListening({
    required Function(double magnitude) onSpike,
    required Function(String error) onError,
  }) {}
  static void stopListening() {}
}
