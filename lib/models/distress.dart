import 'package:hive/hive.dart';

part 'distress.g.dart';

@HiveType(typeId: 0)
enum SeverityLevel {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 1)
enum DistressCategory {
  @HiveField(0)
  pavement,
  @HiveField(1)
  shoulder,
  @HiveField(2)
  striping,
}

@HiveType(typeId: 2)
enum PavementDistressType {
  @HiveField(0)
  alligatorCracking,
  @HiveField(1)
  bleeding,
  @HiveField(2)
  blockCracking,
  @HiveField(3)
  corrugation,
  @HiveField(4)
  depression,
  @HiveField(5)
  edgeCracking,
  @HiveField(6)
  longitudinalTransverseCracking,
  @HiveField(7)
  patching,
  @HiveField(8)
  polishedAggregate,
  @HiveField(9)
  pothole,
  @HiveField(10)
  rutting,
  @HiveField(11)
  shoving,
  @HiveField(12)
  slippageCracking,
  @HiveField(13)
  swell,
  @HiveField(14)
  weatheringRaveling,
}

@HiveType(typeId: 3)
enum ShoulderDistressType {
  @HiveField(0)
  shoulderDropoff, // measured in inches depth
  @HiveField(1)
  shoulderErosion, // measured in linear feet
  @HiveField(2)
  shoulderCracking, // paved shoulder distress
  @HiveField(3)
  vegetationEncroachment,
}

@HiveType(typeId: 4)
enum StripingDistressType {
  @HiveField(0)
  paintWear, // measured in percentage (0-100%)
  @HiveField(1)
  legendWear, // measured in percentage (0-100%)
  @HiveField(2)
  retroreflectivityLoss, // visual score (0-5 scale)
  @HiveField(3)
  missingRPMs, // count of missing reflectors
}

@HiveType(typeId: 5)
enum PavementMaterial {
  @HiveField(0)
  asphalt,
  @HiveField(1)
  concrete,
  @HiveField(2)
  composite,
}

@HiveType(typeId: 6)
enum ShoulderMaterial {
  @HiveField(0)
  asphalt,
  @HiveField(1)
  concrete,
  @HiveField(2)
  gravel,
  @HiveField(3)
  turf,
  @HiveField(4)
  soil,
}

@HiveType(typeId: 7)
enum StripingMaterial {
  @HiveField(0)
  paint,
  @HiveField(1)
  thermoplastic,
  @HiveField(2)
  preformedTape,
  @HiveField(3)
  epoxy,
  @HiveField(4)
  rpm,
}

@HiveType(typeId: 8)
class DistressRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DistressCategory category;

  // Store the enum names as strings or use specific fields
  @HiveField(2)
  final String specificType; // e.g. PavementDistressType.pothole.name

  @HiveField(3)
  final SeverityLevel severity;

  @HiveField(4)
  final double quantity; // linear feet, square feet, depth in inches, count, or %

  @HiveField(5)
  final String unit; // 'in', 'ft', 'sqft', '%', 'count'

  @HiveField(6)
  final double latitude;

  @HiveField(7)
  final double longitude;

  @HiveField(8)
  final DateTime timestamp;

  @HiveField(9)
  final String notes;

  @HiveField(10)
  final String? photoPath; // offline file path

  DistressRecord({
    required this.id,
    required this.category,
    required this.specificType,
    required this.severity,
    required this.quantity,
    required this.unit,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.notes = '',
    this.photoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'specificType': specificType,
      'severity': severity.name,
      'quantity': quantity,
      'unit': unit,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'photoPath': photoPath,
    };
  }

  factory DistressRecord.fromJson(Map<String, dynamic> json) {
    return DistressRecord(
      id: json['id'],
      category: DistressCategory.values.firstWhere((e) => e.name == json['category']),
      specificType: json['specificType'],
      severity: SeverityLevel.values.firstWhere((e) => e.name == json['severity']),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'] ?? '',
      photoPath: json['photoPath'],
    );
  }
}
