import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class AiDetection {
  final String label;
  final double confidence;
  final double x; // normalized 0.0 to 1.0
  final double y;
  final double width;
  final double height;

  AiDetection({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class AiVisionService {
  final _random = Random();
  Timer? _analysisTimer;
  final _detectionController = StreamController<List<AiDetection>>.broadcast();

  Stream<List<AiDetection>> get detectionStream => _detectionController.stream;

  /// Starts simulating live camera frame analysis
  void startLiveScanner() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_detectionController.isClosed) return;

      // 65% chance of detecting something on the road frame
      if (_random.nextDouble() < 0.65) {
        final detections = _generateMockDetections();
        _detectionController.add(detections);
      } else {
        _detectionController.add([]);
      }
    });
  }

  /// Stops the live camera scanner
  void stopLiveScanner() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
  }

  /// Disposes resources
  void dispose() {
    stopLiveScanner();
    _detectionController.close();
  }

  List<AiDetection> _generateMockDetections() {
    final defectTypes = [
      'Pothole',
      'Alligator Cracking',
      'Longitudinal Crack',
      'Shoulder Drop-off',
      'Faded Center Line',
      'Faded Stop Bar',
      'Missing Reflector (RPM)'
    ];

    int numDetections = _random.nextInt(3) + 1; // 1 to 3 defects
    List<AiDetection> list = [];

    for (int i = 0; i < numDetections; i++) {
      final label = defectTypes[_random.nextInt(defectTypes.length)];
      final confidence = 0.72 + _random.nextDouble() * 0.25; // 72% to 97%
      
      // Generate box coordinates centered more towards middle-bottom (representing road in windshield view)
      final width = 0.15 + _random.nextDouble() * 0.25;
      final height = 0.10 + _random.nextDouble() * 0.15;
      final x = 0.1 + _random.nextDouble() * 0.6;
      final y = 0.4 + _random.nextDouble() * 0.4;

      list.add(AiDetection(
        label: label,
        confidence: double.parse(confidence.toStringAsFixed(2)),
        x: double.parse(x.toStringAsFixed(2)),
        y: double.parse(y.toStringAsFixed(2)),
        width: double.parse(width.toStringAsFixed(2)),
        height: double.parse(height.toStringAsFixed(2)),
      ));
    }

    return list;
  }
}
