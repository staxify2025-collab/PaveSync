import 'package:hive/hive.dart';
import 'distress.dart';

part 'segment.g.dart';

@HiveType(typeId: 9)
class RoadSegment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String roadName;

  @HiveField(2)
  final double startMilepost;

  @HiveField(3)
  final double endMilepost;

  @HiveField(4)
  final double lengthInMiles;

  @HiveField(5)
  final String state; // 'AL' for ALDOT, 'FL' for FDOT

  @HiveField(6)
  final PavementMaterial pavementMaterial;

  @HiveField(7)
  final ShoulderMaterial shoulderMaterial;

  @HiveField(8)
  final StripingMaterial stripingMaterial;

  @HiveField(9)
  int? paserScore; // Drive mode (1-10 scale)

  @HiveField(10)
  double? calculatedPci; // Walk mode (0-100 scale)

  @HiveField(11)
  double? fdotCrackRating; // FDOT specific crack rating (0-10 scale)

  @HiveField(12)
  double? fdotRideRating; // FDOT specific ride rating (0-10 scale)

  @HiveField(13)
  double? fdotRutRating; // FDOT specific rut rating (0-10 scale)

  @HiveField(14)
  final List<DistressRecord> distresses;

  @HiveField(15)
  bool isSynced;

  @HiveField(16)
  final DateTime timestamp;

  RoadSegment({
    required this.id,
    required this.roadName,
    required this.startMilepost,
    required this.endMilepost,
    required this.lengthInMiles,
    required this.state,
    required this.pavementMaterial,
    required this.shoulderMaterial,
    required this.stripingMaterial,
    this.paserScore,
    this.calculatedPci,
    this.fdotCrackRating,
    this.fdotRideRating,
    this.fdotRutRating,
    required this.distresses,
    this.isSynced = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roadName': roadName,
      'startMilepost': startMilepost,
      'endMilepost': endMilepost,
      'lengthInMiles': lengthInMiles,
      'state': state,
      'pavementMaterial': pavementMaterial.name,
      'shoulderMaterial': shoulderMaterial.name,
      'stripingMaterial': stripingMaterial.name,
      'paserScore': paserScore,
      'calculatedPci': calculatedPci,
      'fdotCrackRating': fdotCrackRating,
      'fdotRideRating': fdotRideRating,
      'fdotRutRating': fdotRutRating,
      'distresses': distresses.map((d) => d.toJson()).toList(),
      'isSynced': isSynced,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RoadSegment.fromJson(Map<String, dynamic> json) {
    var distressListJson = json['distresses'] as List;
    List<DistressRecord> distressList = distressListJson
        .map((d) => DistressRecord.fromJson(Map<String, dynamic>.from(d)))
        .toList();

    return RoadSegment(
      id: json['id'],
      roadName: json['roadName'],
      startMilepost: (json['startMilepost'] as num).toDouble(),
      endMilepost: (json['endMilepost'] as num).toDouble(),
      lengthInMiles: (json['lengthInMiles'] as num).toDouble(),
      state: json['state'],
      pavementMaterial: PavementMaterial.values
          .firstWhere((e) => e.name == json['pavementMaterial']),
      shoulderMaterial: ShoulderMaterial.values
          .firstWhere((e) => e.name == json['shoulderMaterial']),
      stripingMaterial: StripingMaterial.values
          .firstWhere((e) => e.name == json['stripingMaterial']),
      paserScore: json['paserScore'],
      calculatedPci: json['calculatedPci'] != null
          ? (json['calculatedPci'] as num).toDouble()
          : null,
      fdotCrackRating: json['fdotCrackRating'] != null
          ? (json['fdotCrackRating'] as num).toDouble()
          : null,
      fdotRideRating: json['fdotRideRating'] != null
          ? (json['fdotRideRating'] as num).toDouble()
          : null,
      fdotRutRating: json['fdotRutRating'] != null
          ? (json['fdotRutRating'] as num).toDouble()
          : null,
      distresses: distressList,
      isSynced: json['isSynced'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
