import 'dart:math';
import '../models/distress.dart';

class VoiceAssistantService {
  static bool get isSupported => false;
  
  static void startRecognition({
    required Function(String text) onResult,
    required Function(String error) onError,
    required Function() onEnd,
  }) {
    onError("Speech recognition not supported on this platform.");
  }
  
  static void stopRecognition() {}
  
  static DistressRecord? parseSpeech(String text, String state) {
    final lowercase = text.toLowerCase().trim();
    
    // Try parsing category
    DistressCategory category = DistressCategory.pavement;
    String specificType = PavementDistressType.pothole.name;
    String unit = 'count';
    double quantity = 1.0;
    SeverityLevel severity = SeverityLevel.medium;
    
    // Keyword matches
    if (lowercase.contains('pothole')) {
      category = DistressCategory.pavement;
      specificType = PavementDistressType.pothole.name;
      unit = 'count';
    } else if (lowercase.contains('alligator') || lowercase.contains('fatigue')) {
      category = DistressCategory.pavement;
      specificType = PavementDistressType.alligatorCracking.name;
      unit = '%';
    } else if (lowercase.contains('shoulder') || lowercase.contains('drop-off') || lowercase.contains('dropoff')) {
      category = DistressCategory.shoulder;
      specificType = ShoulderDistressType.shoulderDropoff.name;
      unit = 'in';
    } else if (lowercase.contains('striping') || lowercase.contains('paint') || lowercase.contains('marking') || lowercase.contains('legend')) {
      category = DistressCategory.striping;
      specificType = StripingDistressType.paintWear.name;
      unit = 'ft';
    } else if (lowercase.contains('rpm') || lowercase.contains('marker')) {
      category = DistressCategory.striping;
      specificType = StripingDistressType.missingRPMs.name;
      unit = 'count';
    } else {
      // Default fallback or no match
      return null;
    }
    
    // Severity parsing
    if (lowercase.contains('high') || lowercase.contains('severe') || lowercase.contains('critical')) {
      severity = SeverityLevel.high;
    } else if (lowercase.contains('low') || lowercase.contains('minor')) {
      severity = SeverityLevel.low;
    } else {
      severity = SeverityLevel.medium;
    }
    
    // Quantity parsing (extract numbers)
    final numberRegExp = RegExp(r'\d+(\.\d+)?');
    final match = numberRegExp.firstMatch(lowercase);
    if (match != null) {
      quantity = double.tryParse(match.group(0)!) ?? 1.0;
    } else {
      // Check word numbers
      if (lowercase.contains('one')) quantity = 1.0;
      else if (lowercase.contains('two') || lowercase.contains('to')) quantity = 2.0;
      else if (lowercase.contains('three')) quantity = 3.0;
      else if (lowercase.contains('four') || lowercase.contains('for')) quantity = 4.0;
      else if (lowercase.contains('five')) quantity = 5.0;
      else if (lowercase.contains('ten')) quantity = 10.0;
    }
    
    return DistressRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: category,
      specificType: specificType,
      severity: severity,
      quantity: quantity,
      unit: unit,
      latitude: 32.3182 + (Random().nextDouble() - 0.5) * 0.001,
      longitude: -86.9023 + (Random().nextDouble() - 0.5) * 0.001,
      timestamp: DateTime.now(),
    );
  }
}
