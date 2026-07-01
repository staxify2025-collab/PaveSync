import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:camera/camera.dart';
import '../services/ai_vision_service.dart';
import '../services/vibration_service.dart';
import '../services/vision_analyzer_service.dart';
import '../utils/platform_view_helper.dart';

class CameraInspectionView extends StatefulWidget {
  final Function(AiDetection) onDefectDetected;
  final bool isDriveMode; // true = PASER Drive HUD, false = Walk PCI Mode
  final String? videoUrl;

  const CameraInspectionView({
    super.key,
    required this.onDefectDetected,
    this.isDriveMode = true,
    this.videoUrl,
  });

  @override
  State<CameraInspectionView> createState() => _CameraInspectionViewState();
}

class _CameraInspectionViewState extends State<CameraInspectionView> with SingleTickerProviderStateMixin {
  late final AiVisionService _visionService;
  List<AiDetection> _currentDetections = [];
  bool _isScanning = false;
  late final AnimationController _animationController;
  
  // Real camera & sensor state
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String _vibrationStatus = '';

  // Simulated telemetry
  double _simulatedSpeed = 0.0;
  double _simulatedIri = 72.0;

  @override
  void initState() {
    super.initState();
    _isScanning = true; // Auto-start scanning on load!
    _simulatedSpeed = widget.isDriveMode ? 35.0 : 2.5;
    
    if (kIsWeb && widget.videoUrl != null) {
      registerVideoPlayerFactory(
        'video-player-${widget.videoUrl.hashCode}',
        widget.videoUrl!,
      );
    }
    
    _visionService = AiVisionService();
    _visionService.startLiveScanner(); // Start the AI service!
    
    _visionService.detectionStream.listen((detections) {
      if (mounted && _isScanning) {
        setState(() {
          _currentDetections = detections;
          // Trigger callbacks for new distress detections
          for (var det in detections) {
            widget.onDefectDetected(det);
          }
        });
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    if (widget.videoUrl == null) {
      _initCamera();
    }
    _startVibrationSensor();
    _startVisualRoadAnalyzer();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      CameraDescription? backCamera;
      for (var cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.back) {
          backCamera = cam;
          break;
        }
      }
      
      final cameraToUse = backCamera ?? cameras.first;
      
      _cameraController = CameraController(
        cameraToUse,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startVibrationSensor() {
    VibrationSensorService.startListening(
      onSpike: (magnitude) {
        if (mounted && _isScanning) {
          final spikeDetection = AiDetection(
            label: 'Pothole (Vibration Spike)',
            confidence: 0.99,
            x: 0.4,
            y: 0.7,
            width: 0.2,
            height: 0.15,
          );
          
          setState(() {
            _currentDetections = [spikeDetection, ..._currentDetections];
            _vibrationStatus = 'Vibration Spike: ${magnitude.toStringAsFixed(1)} m/s²!';
          });
          
          widget.onDefectDetected(spikeDetection);
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _vibrationStatus = '';
              });
            }
          });
        }
      },
      onError: (err) {
        debugPrint('Vibration sensor error: $err');
      },
    );
  }

  void _startVisualRoadAnalyzer() {
    VisionAnalyzerService.startAnalyzing(
      onDefectDetected: (defectLabel, confidence) {
        if (mounted && _isScanning) {
          // Calculate random bounding box positions to simulate detection locations in bottom half
          final randomX = 0.2 + (defectLabel.length % 5) * 0.1;
          final randomY = 0.5 + (defectLabel.length % 3) * 0.1;
          
          final visualDetection = AiDetection(
            label: defectLabel,
            confidence: confidence,
            x: randomX,
            y: randomY,
            width: 0.25,
            height: 0.18,
          );
          
          setState(() {
            // Keep at most 3 recent detections to prevent cluttering
            if (_currentDetections.length > 2) {
              _currentDetections.removeLast();
            }
            _currentDetections = [visualDetection, ..._currentDetections];
          });
          
          // Log distress in active report segment
          widget.onDefectDetected(visualDetection);
        }
      },
      onError: (err) {
        debugPrint('Visual frame analyzer error: $err');
      },
    );
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _visionService.startLiveScanner();
        _startVibrationSensor();
        _startVisualRoadAnalyzer();
        _simulatedSpeed = widget.isDriveMode ? 35.0 : 2.5;
      } else {
        _visionService.stopLiveScanner();
        VibrationSensorService.stopListening();
        VisionAnalyzerService.stopAnalyzing();
        _currentDetections = [];
        _simulatedSpeed = 0.0;
      }
    });
  }

  @override
  void dispose() {
    _visionService.dispose();
    _animationController.dispose();
    _cameraController?.dispose();
    VibrationSensorService.stopListening();
    VisionAnalyzerService.stopAnalyzing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Live physical camera feed with mock painter fallback
            Positioned.fill(
              child: widget.videoUrl != null
                  ? (kIsWeb
                      ? HtmlElementView(
                          viewType: 'video-player-${widget.videoUrl.hashCode}',
                        )
                      : Container(
                          color: Colors.black.withOpacity(0.85),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.movie, size: 48, color: Colors.amber),
                              const SizedBox(height: 12),
                              Text(
                                'Scanning Pre-recorded Video:\n${widget.videoUrl}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ))
                  : _isCameraInitialized && _cameraController != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: 100,
                            height: 100 * _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                      : CustomPaint(
                          painter: RoadSimulationPainter(
                            animationProgress: _animationController.value,
                            isScanning: _isScanning,
                          ),
                        ),
            ),

            // Live AI Bounding Box overlays
            if (_isScanning)
              ..._currentDetections.map((det) {
                return Positioned(
                  left: det.x * MediaQuery.of(context).size.width * 0.5,
                  top: det.y * 400.0,
                  width: det.width * MediaQuery.of(context).size.width * 0.5,
                  height: det.height * 400.0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _getLabelColor(det.label),
                        width: 2,
                      ),
                      color: _getLabelColor(det.label).withOpacity(0.12),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: _getLabelColor(det.label),
                        child: Text(
                          '${det.label} ${(det.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

            // HUD Top Telemetry Panel
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Telemetry
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAT: 32.3182° N | LON: 86.9023° W',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.greenAccent),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MODE: ${widget.isDriveMode ? "DRIVE (PASER)" : "WALK (PCI)"}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // Speed & IRI HUD
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            const Text('SPEED', style: TextStyle(fontSize: 8, color: Colors.grey)),
                            Text('${_simulatedSpeed.toStringAsFixed(1)} MPH',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          children: [
                            const Text('AVG IRI', style: TextStyle(fontSize: 8, color: Colors.grey)),
                            Text('${_simulatedIri.toStringAsFixed(0)} in/mi',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orangeAccent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scanning Status Indicator
            if (_isScanning)
              Positioned(
                top: 80,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                      SizedBox(width: 4),
                      Text(
                        'LIVE SCANNING',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isScanning && _vibrationStatus.isNotEmpty)
              Positioned(
                top: 115,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, color: Colors.white, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        _vibrationStatus,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

            // HUD Bottom Control Bar
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Last Detected item flash
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isScanning && _currentDetections.isNotEmpty
                          ? Row(
                              children: [
                                Icon(Icons.warning, color: _getLabelColor(_currentDetections.first.label), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Detected: ${_currentDetections.first.label} (${(_currentDetections.first.confidence * 100).toStringAsFixed(0)}% Conf)',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Text(
                                'Aim camera at road to inspect',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Start/Stop Toggle button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isScanning ? Colors.red : Colors.amber,
                      foregroundColor: _isScanning ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _toggleScanning,
                    icon: Icon(_isScanning ? Icons.stop : Icons.videocam),
                    label: Text(
                      _isScanning ? 'STOP' : 'START INSPECT',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLabelColor(String label) {
    if (label.contains('Pothole')) return Colors.red;
    if (label.contains('Cracking')) return Colors.orange;
    if (label.contains('Shoulder')) return Colors.cyan;
    if (label.contains('Faded')) return Colors.yellow;
    return Colors.amber;
  }
}

// Custom Painter to simulate driving down a highway
class RoadSimulationPainter extends CustomPainter {
  final double animationProgress;
  final bool isScanning;

  RoadSimulationPainter({required this.animationProgress, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1F29)
      ..style = PaintingStyle.fill;
    
    // Draw sky/horizon background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw road surface (polygon from horizon center to bottom corners)
    final roadPaint = Paint()
      ..color = const Color(0xFF2E2E3A)
      ..style = PaintingStyle.fill;
    
    final horizonY = size.height * 0.4;
    final path = Path()
      ..moveTo(size.width * 0.46, horizonY)
      ..lineTo(size.width * 0.54, horizonY)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, roadPaint);

    // Draw shoulders
    final shoulderPaint = Paint()
      ..color = const Color(0xFF4A483F) // Gravel/turf shoulder color
      ..style = PaintingStyle.fill;

    // Left shoulder
    final leftShoulderPath = Path()
      ..moveTo(0, horizonY)
      ..lineTo(size.width * 0.46, horizonY)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(leftShoulderPath, shoulderPaint);

    // Right shoulder
    final rightShoulderPath = Path()
      ..moveTo(size.width * 0.54, horizonY)
      ..lineTo(size.width, horizonY)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(rightShoulderPath, shoulderPaint);

    // Draw lane lines (yellow center, white edge)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Edge lines
    canvas.drawLine(Offset(size.width * 0.46, horizonY), Offset(0, size.height), linePaint);
    canvas.drawLine(Offset(size.width * 0.54, horizonY), Offset(size.width, size.height), linePaint);

    // Center broken dashed line (animated if scanning)
    final yellowPaint = Paint()
      ..color = Colors.amber.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    double progress = isScanning ? animationProgress : 0.0;
    
    // 3 animated segments of center line
    for (int i = 0; i < 4; i++) {
      double startPct = (i + progress) / 4.0;
      double endPct = (i + 0.5 + progress) / 4.0;
      
      if (startPct > 1.0) startPct -= 1.0;
      if (endPct > 1.0) endPct -= 1.0;
      if (startPct > endPct) continue;

      double startY = horizonY + (size.height - horizonY) * startPct;
      double endY = horizonY + (size.height - horizonY) * endPct;
      
      double startX = size.width * 0.5 + (0 - size.width * 0.5) * (startY - horizonY) / (size.height - horizonY) * 0.05; // slightly centered
      double endX = size.width * 0.5 + (0 - size.width * 0.5) * (endY - horizonY) / (size.height - horizonY) * 0.05;
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), yellowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RoadSimulationPainter oldDelegate) => true;
}
