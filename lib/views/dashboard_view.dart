import 'package:flutter/material.dart';
import 'dart:math';
import '../models/distress.dart';
import '../models/segment.dart';
import '../services/db_service.dart';
import '../services/formulas/pci_calculator.dart';
import '../services/formulas/fdot_pcs_calc.dart';
import '../services/formulas/paser_calc.dart';
import '../services/ai_vision_service.dart';
import '../services/voice_assistant_service.dart';
import 'camera_inspection_view.dart';
import 'report_generator_view.dart';
import 'chatbot_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // State variables
  String _selectedState = 'FL'; // 'AL' = ALDOT, 'FL' = FDOT
  bool _isDriveMode = true; // true = Drive (PASER), false = Walk (PCI)
  String _searchQuery = '';
  bool _isVoiceListening = false;
  String _voiceStatus = 'Press mic to speak';
  
  RoadSegment? _activeSegment;
  List<RoadSegment> _segmentsList = [];
  bool _isScanning = false;
  int _mobileTabIndex = 0;
  bool _showSplash = true;
  bool _isChatOpen = true;

  // New segment form controllers
  final _roadController = TextEditingController(text: 'I-95 Northbound');
  final _startMileController = TextEditingController(text: '120.4');
  final _endMileController = TextEditingController(text: '120.5');

  PavementMaterial _pavMaterial = PavementMaterial.asphalt;
  ShoulderMaterial _shldMaterial = ShoulderMaterial.gravel;
  StripingMaterial _strpMaterial = StripingMaterial.thermoplastic;

  @override
  void initState() {
    super.initState();
    _loadSegments();

    // Auto-dismiss splash screen after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  void _loadSegments() {
    setState(() {
      _segmentsList = DbService.getAllSegments();
      if (_segmentsList.isNotEmpty && _activeSegment == null) {
        _activeSegment = _segmentsList.first;
      }
    });
  }

  void _createNewSegment() {
    final roadName = _roadController.text.trim();
    final startMP = double.tryParse(_startMileController.text) ?? 0.0;
    final endMP = double.tryParse(_endMileController.text) ?? 0.1;
    final length = (endMP - startMP).abs();

    final newSegment = RoadSegment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roadName: roadName.isNotEmpty ? roadName : 'Unnamed Route',
      startMilepost: startMP,
      endMilepost: endMP,
      lengthInMiles: length,
      state: _selectedState,
      pavementMaterial: _pavMaterial,
      shoulderMaterial: _shldMaterial,
      stripingMaterial: _strpMaterial,
      distresses: [],
      isSynced: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _activeSegment = newSegment;
      _isScanning = true; // immediately start scanning hud
    });
  }

  void _handleVisionDefectDetected(AiDetection detection) {
    if (_activeSegment == null) return;

    // Convert AI detection class to our model enums
    DistressCategory cat;
    String specType;
    String unit = 'ft';
    double quantity = 1.0;
    SeverityLevel severity = SeverityLevel.medium;

    if (detection.label.contains('Pothole')) {
      cat = DistressCategory.pavement;
      specType = PavementDistressType.pothole.name;
      unit = 'count';
      quantity = 1.0;
      severity = detection.confidence > 0.88 ? SeverityLevel.high : SeverityLevel.medium;
    } else if (detection.label == 'Alligator Cracking') {
      cat = DistressCategory.pavement;
      specType = PavementDistressType.alligatorCracking.name;
      unit = '%';
      quantity = (1 + Random().nextInt(5)).toDouble(); // small density increments
      severity = detection.confidence > 0.90 ? SeverityLevel.high : SeverityLevel.medium;
    } else if (detection.label == 'Shoulder Drop-off') {
      cat = DistressCategory.shoulder;
      specType = ShoulderDistressType.shoulderDropoff.name;
      unit = 'in';
      quantity = 2.0 + Random().nextDouble() * 3.0; // 2" to 5" depth
      severity = quantity > 4.0 ? SeverityLevel.high : SeverityLevel.medium;
    } else if (detection.label.contains('Faded')) {
      cat = DistressCategory.striping;
      specType = StripingDistressType.paintWear.name;
      unit = 'ft';
      quantity = 25.0 + Random().nextInt(50); // 25 to 75 ft wear
      severity = SeverityLevel.medium;
    } else {
      return;
    }

    final newDistress = DistressRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: cat,
      specificType: specType,
      severity: severity,
      quantity: quantity,
      unit: unit,
      latitude: 32.3182 + (Random().nextDouble() - 0.5) * 0.001,
      longitude: -86.9023 + (Random().nextDouble() - 0.5) * 0.001,
      timestamp: DateTime.now(),
    );

    setState(() {
      _activeSegment!.distresses.add(newDistress);
      
      // Recalculate scores dynamically
      _recalculateScores();
    });
  }

  void _recalculateScores() {
    if (_activeSegment == null) return;

    if (_isDriveMode) {
      // Simple dynamic PASER score based on distress counts
      int basePaser = 10;
      int distressCount = _activeSegment!.distresses.length;
      basePaser -= (distressCount ~/ 2);
      _activeSegment!.paserScore = basePaser.clamp(1, 10);
    } else {
      // Calculate PCI
      _activeSegment!.calculatedPci = PciCalculator.calculate(_activeSegment!.distresses);
    }

    // Calculate FDOT specific scores
    if (_activeSegment!.state == 'FL') {
      _activeSegment!.fdotCrackRating = FdotPcsCalculator.calculateCrackRating(_activeSegment!.distresses);
      _activeSegment!.fdotRutRating = FdotPcsCalculator.calculateRutRating(_activeSegment!.distresses);
      _activeSegment!.fdotRideRating = FdotPcsCalculator.calculateRideRating(
        _activeSegment!.distresses.any((d) => d.specificType == PavementDistressType.rutting.name) ? 95.0 : 65.0
      );
    }
  }

  void _stopInspection() async {
    if (_activeSegment == null) return;

    // Final calculations
    _recalculateScores();

    // Save locally
    await DbService.saveSegment(_activeSegment!);
    
    setState(() {
      _isScanning = false;
      _mobileTabIndex = 1;
      _loadSegments();
    });
  }

  void _toggleVoiceLogger() {
    if (_isVoiceListening) {
      VoiceAssistantService.stopRecognition();
      setState(() {
        _isVoiceListening = false;
        _voiceStatus = 'Voice logger stopped';
      });
    } else {
      if (_activeSegment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or start a route first to log defects by voice.')),
        );
        return;
      }
      
      setState(() {
        _isVoiceListening = true;
        _voiceStatus = 'Listening...';
      });

      VoiceAssistantService.startRecognition(
        onResult: (text) {
          final distress = VoiceAssistantService.parseSpeech(text, _selectedState);
          if (distress != null) {
            setState(() {
              _activeSegment!.distresses.add(distress);
              _recalculateScores();
              _voiceStatus = 'Logged: ${distress.specificType}';
            });
            DbService.saveSegment(_activeSegment!);
          } else {
            setState(() {
              _voiceStatus = 'Heard: "$text" (No match)';
            });
          }
        },
        onError: (err) {
          setState(() {
            _isVoiceListening = false;
            _voiceStatus = 'Error: $err';
          });
        },
        onEnd: () {
          setState(() {
            _isVoiceListening = false;
          });
        },
      );
    }
  }

  void _syncActiveSegment() async {
    if (_activeSegment == null) return;
    setState(() {
      _activeSegment!.isSynced = true;
    });
    await DbService.saveSegment(_activeSegment!);
    _loadSegments();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return Scaffold(
        backgroundColor: const Color(0xFF101828),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.95, end: 1.05),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/pavesync_logo.png'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'PAVESYNC AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Next-Gen Road Quality & Compliance Terminal',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.amber,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 64),
              Text(
                'by Staxify, LLC | GovTech & ConTech B2B',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    // Quick statistics
    final totalInspected = _segmentsList.length;
    final totalDefects = _segmentsList.fold<int>(0, (sum, seg) => sum + seg.distresses.length);
    final totalPending = _segmentsList.where((s) => !s.isSynced).length;

    // Filtered list
    final filteredSegments = _segmentsList
        .where((s) => s.roadName.toLowerCase().contains(_searchQuery))
        .toList();

    if (isMobile) {
      // Mobile Layout
      if (_isScanning) {
        // Full screen camera inspection view on mobile
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                CameraInspectionView(
                  isDriveMode: _isDriveMode,
                  onDefectDetected: _handleVisionDefectDetected,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _stopInspection,
                    backgroundColor: Colors.red,
                    icon: const Icon(Icons.stop, color: Colors.white),
                    label: const Text('STOP & REPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Tabbed workspace on mobile
      Widget activeMobileBody;
      if (_mobileTabIndex == 0) {
        // Show Sidebar / Builder
        activeMobileBody = _buildMobileSidebar(filteredSegments, totalInspected, totalDefects, totalPending);
      } else if (_mobileTabIndex == 1) {
        // Show Report
        activeMobileBody = _activeSegment == null
            ? const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No active report loaded. Select or start a route in Route Builder.', textAlign: TextAlign.center),
              ))
            : ReportGeneratorView(segment: _activeSegment!, onSyncPressed: _syncActiveSegment);
      } else {
        // Show Chatbot
        activeMobileBody = const ChatbotView();
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F4F7),
          title: const Text('PaveSync AI Mobile Terminal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _mobileTabIndex,
          selectedItemColor: Colors.amber[800],
          onTap: (index) {
            setState(() {
              _mobileTabIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Route Builder'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Active Report'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI Chatbot'),
          ],
        ),
        body: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F7FB), Color(0xFFE8EDF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: activeMobileBody,
          ),
        ),
      );
    }

    // Desktop Layout (Original)
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FB), Color(0xFFE8EDF6), Color(0xFFDEE5F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Left Sidebar Control Panel (Glassmorphic White)
            Container(
              width: 360,
              decoration: const BoxDecoration(
                color: Color(0xEDF3F5F9),
                border: Border(right: BorderSide(color: Colors.black12)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Profile Header Row
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundImage: AssetImage('assets/images/inspector_avatar.png'),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello 👋',
                                    style: TextStyle(color: Color(0xFF475467), fontSize: 10),
                                  ),
                                  Text(
                                    'Inspector Jackson',
                                    style: TextStyle(color: Color(0xFF101828), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.notifications_none, color: Color(0xFF475467), size: 20),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. Search Field
                          TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.toLowerCase().trim();
                              });
                            },
                            style: const TextStyle(color: Color(0xFF101828), fontSize: 12),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF475467)),
                              hintText: 'Search inspections...',
                              hintStyle: const TextStyle(color: Color(0xFF475467), fontSize: 12),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.amber, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.black12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Stats Grid Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatCard('$totalInspected', 'Inspected'),
                              const SizedBox(width: 8),
                              _buildStatCard('$totalDefects', 'Defects'),
                              const SizedBox(width: 8),
                              _buildStatCard('$totalPending', 'Pending'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 4. Active Project Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: Image.asset(
                                    'assets/images/site_project_view.png',
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _activeSegment != null
                                            ? _activeSegment!.roadName.toUpperCase()
                                            : 'ROUTE ACTIVE ANALYSIS',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF101828)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _activeSegment != null
                                            ? 'MP ${_activeSegment!.startMilepost.toStringAsFixed(2)} - ${_activeSegment!.endMilepost.toStringAsFixed(2)} (${_activeSegment!.state == "FL" ? "FDOT" : "ALDOT"})'
                                            : 'No active route loaded',
                                        style: const TextStyle(color: Color(0xFF475467), fontSize: 11),
                                      ),
                                      if (_activeSegment != null) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Estimated Repair status:',
                                              style: TextStyle(fontSize: 10, color: Color(0xFF475467)),
                                            ),
                                            Text(
                                              _activeSegment!.distresses.isEmpty
                                                  ? 'Compliant'
                                                  : 'Repairs Logged',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _activeSegment!.distresses.isEmpty ? Colors.green[700] : Colors.orange[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 5. Config toggles and New Route Form Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('STATE DOT RULESET', style: TextStyle(fontSize: 9, color: Color(0xFF475467), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildToggleOption('Florida (FDOT)', _selectedState == 'FL', () {
                                        setState(() => _selectedState = 'FL');
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildToggleOption('Alabama (ALDOT)', _selectedState == 'AL', () {
                                        setState(() => _selectedState = 'AL');
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                const Text('INSPECTION METHOD', style: TextStyle(fontSize: 9, color: Color(0xFF475467), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildToggleOption('Drive (PASER)', _isDriveMode, () {
                                        setState(() => _isDriveMode = true);
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildToggleOption('Walk (ASTM PCI)', !_isDriveMode, () {
                                        setState(() => _isDriveMode = false);
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                const Text('START NEW INSPECTION', style: TextStyle(fontSize: 9, color: Color(0xFF475467), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _roadController,
                                  style: const TextStyle(color: Color(0xFF101828), fontSize: 13),
                                  decoration: _buildInputDecoration('Roadway / Route ID'),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _startMileController,
                                        style: const TextStyle(color: Color(0xFF101828), fontSize: 13),
                                        decoration: _buildInputDecoration('Start MP'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _endMileController,
                                        style: const TextStyle(color: Color(0xFF101828), fontSize: 13),
                                        decoration: _buildInputDecoration('End MP'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Voice Logger Trigger Button (Agentic Speech Logger)
                                if (_activeSegment != null) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _isVoiceListening ? Colors.red[800] : Colors.amber[800],
                                        side: BorderSide(color: _isVoiceListening ? Colors.red : Colors.amber),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _toggleVoiceLogger,
                                      icon: Icon(_isVoiceListening ? Icons.mic : Icons.mic_none),
                                      label: Text(
                                        _isVoiceListening ? 'Listening...' : 'Log defect by voice',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      _voiceStatus,
                                      style: TextStyle(fontSize: 9, color: _isVoiceListening ? Colors.red[800] : const Color(0xFF475467), fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _createNewSegment,
                                    child: const Text('Start Live Scan HUD', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 6. Site road photos gallery
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SITE ROAD PHOTOS', style: TextStyle(fontSize: 10, color: Color(0xFF475467), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 60,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildGalleryPhoto('assets/images/pavement_scan_photo.png'),
                                    const SizedBox(width: 8),
                                    _buildGalleryPhoto('assets/images/site_project_view.png'),
                                    const SizedBox(width: 8),
                                    _buildGalleryPhoto('assets/images/inspector_avatar.png'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 7. Completed Inspections list Titled
                          const Text('COMPLETED INSPECTIONS', style: TextStyle(fontSize: 10, color: Color(0xFF475467), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          filteredSegments.isEmpty
                              ? const Center(
                                  child: Text('No reports match search.', style: TextStyle(color: Color(0xFF475467), fontSize: 11)),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredSegments.length,
                                  itemBuilder: (context, index) {
                                    final seg = filteredSegments[index];
                                    final isActive = _activeSegment?.id == seg.id;
                                    
                                    String scoreText = '';
                                    if (seg.paserScore != null) {
                                      scoreText = 'PASER: ${seg.paserScore}';
                                    } else if (seg.calculatedPci != null) {
                                      scoreText = 'PCI: ${seg.calculatedPci!.toStringAsFixed(0)}';
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFFFEF8E7) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isActive ? Colors.amber : Colors.black12,
                                          width: 1,
                                        ),
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.amber.withOpacity(0.15),
                                          child: const Icon(Icons.location_on, color: Colors.amber, size: 14),
                                        ),
                                        title: Text(
                                          seg.roadName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF101828), fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          'MP ${seg.startMilepost}-${seg.endMilepost} ($scoreText)',
                                          style: const TextStyle(color: Color(0xFF475467), fontSize: 11),
                                        ),
                                        trailing: Icon(
                                          seg.isSynced ? Icons.cloud_done : Icons.cloud_queue,
                                          color: seg.isSynced ? Colors.green[700] : Colors.orange[700],
                                          size: 14,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _activeSegment = seg;
                                            _isScanning = false;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Workspace Area (HUD / Reports)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PaveSync AI B2B Inspection Terminal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF101828)),
                            ),
                            Text(
                              _isScanning
                                  ? 'Executing live roadway distress object scan overlay...'
                                  : 'Analyzing and quantifying road segment quality...',
                              style: const TextStyle(color: Color(0xFF475467), fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(_isChatOpen ? Icons.chat_bubble : Icons.chat_bubble_outline, color: Colors.amber[800]),
                              tooltip: 'Toggle AI compliance chatbot',
                              onPressed: () {
                                setState(() {
                                  _isChatOpen = !_isChatOpen;
                                });
                              },
                            ),
                            if (_isScanning) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: _stopInspection,
                                icon: const Icon(Icons.stop),
                                label: const Text('STOP SCAN & BUILD REPORT'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Main Workspace Box
                    Expanded(
                      child: _activeSegment == null
                          ? const Center(
                              child: Text(
                                'Please select an inspected route or start a new inspection.',
                                style: TextStyle(color: Color(0xFF475467)),
                              ),
                            )
                          : _isScanning
                              ? CameraInspectionView(
                                  isDriveMode: _isDriveMode,
                                  onDefectDetected: _handleVisionDefectDetected,
                                )
                              : ReportGeneratorView(
                                  segment: _activeSegment!,
                                  onSyncPressed: _syncActiveSegment,
                                ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Sidebar Chatbot
            if (_isChatOpen) const ChatbotView(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSidebar(List<RoadSegment> filteredSegments, int totalInspected, int totalDefects, int totalPending) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Row
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/inspector_avatar.png'),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello 👋', style: TextStyle(color: Color(0xFF475467), fontSize: 10)),
                  Text('Inspector Jackson', style: TextStyle(color: Color(0xFF101828), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Color(0xFF475467), size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
            style: const TextStyle(color: Color(0xFF101828), fontSize: 12),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF475467)),
              hintText: 'Search inspections...',
              hintStyle: const TextStyle(color: Color(0xFF475467), fontSize: 12),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.amber, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.black12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stats Grid Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('$totalInspected', 'Inspected'),
              const SizedBox(width: 6),
              _buildStatCard('$totalDefects', 'Defects'),
              const SizedBox(width: 6),
              _buildStatCard('$totalPending', 'Pending'),
            ],
          ),
          const SizedBox(height: 12),

          // Config toggles and New Route Form Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STATE DOT RULESET', style: TextStyle(fontSize: 9, color: Color(0xFF475467), fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleOption('Florida (FDOT)', _selectedState == 'FL', () {
                        setState(() => _selectedState = 'FL');
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToggleOption('Alabama (ALDOT)', _selectedState == 'AL', () {
                        setState(() => _selectedState = 'AL');
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text('INSPECTION METHOD', style: TextStyle(fontSize: 9, color: Color(0xFF475467), fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleOption('Drive (PASER)', _isDriveMode, () {
                        setState(() => _isDriveMode = true);
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToggleOption('Walk (ASTM PCI)', !_isDriveMode, () {
                        setState(() => _isDriveMode = false);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text('START NEW INSPECTION', style: TextStyle(fontSize: 9, color: Color(0xFF475467), fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _roadController,
                  style: const TextStyle(color: Color(0xFF101828), fontSize: 13),
                  decoration: _buildInputDecoration('Roadway / Route ID'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startMileController,
                        style: const TextStyle(color: Color(0xFF101828), fontSize: 13),
                        decoration: _buildInputDecoration('Start MP'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _endMileController,
                        style: const TextStyle(color: Color(0xFF101828), fontSize: 13),
                        decoration: _buildInputDecoration('End MP'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Voice Logger Trigger
                if (_activeSegment != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isVoiceListening ? Colors.red[800] : Colors.amber[800],
                        side: BorderSide(color: _isVoiceListening ? Colors.red : Colors.amber),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _toggleVoiceLogger,
                      icon: Icon(_isVoiceListening ? Icons.mic : Icons.mic_none),
                      label: Text(
                        _isVoiceListening ? 'Listening...' : 'Log defect by voice',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _voiceStatus,
                      style: TextStyle(fontSize: 9, color: _isVoiceListening ? Colors.red[800] : const Color(0xFF475467), fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _createNewSegment,
                    child: const Text('Start Live Scan HUD', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Completed list
          const Text('COMPLETED INSPECTIONS', style: TextStyle(fontSize: 10, color: Color(0xFF475467), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          filteredSegments.isEmpty
              ? const Center(child: Text('No reports match search.', style: TextStyle(color: Color(0xFF475467), fontSize: 11)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSegments.length,
                  itemBuilder: (context, index) {
                    final seg = filteredSegments[index];
                    final isActive = _activeSegment?.id == seg.id;
                    
                    String scoreText = '';
                    if (seg.paserScore != null) {
                      scoreText = 'PASER: ${seg.paserScore}';
                    } else if (seg.calculatedPci != null) {
                      scoreText = 'PCI: ${seg.calculatedPci!.toStringAsFixed(0)}';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFFEF8E7) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive ? Colors.amber : Colors.black12,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.amber.withOpacity(0.15),
                          child: const Icon(Icons.location_on, color: Colors.amber, size: 14),
                        ),
                        title: Text(seg.roadName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF101828), fontSize: 13)),
                        subtitle: Text('MP ${seg.startMilepost}-${seg.endMilepost} ($scoreText)', style: const TextStyle(color: Color(0xFF475467), fontSize: 11)),
                        trailing: Icon(seg.isSynced ? Icons.cloud_done : Icons.cloud_queue, color: seg.isSynced ? Colors.green[700] : Colors.orange[700], size: 14),
                        onTap: () {
                          setState(() {
                            _activeSegment = seg;
                            _isScanning = false;
                            _mobileTabIndex = 1;
                          });
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.black12,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.amber[800] : const Color(0xFF475467),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF475467), fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.amber),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF101828)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF475467)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryPhoto(String assetPath) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
