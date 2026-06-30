import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/distress.dart';
import '../models/segment.dart';

class DbService {
  static const String _boxName = 'segments_box';
  static bool _initialized = false;

  /// Initializes local Hive database and registers all adapters
  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register Hive Adapters
    Hive.registerAdapter(SeverityLevelAdapter());
    Hive.registerAdapter(DistressCategoryAdapter());
    Hive.registerAdapter(PavementDistressTypeAdapter());
    Hive.registerAdapter(ShoulderDistressTypeAdapter());
    Hive.registerAdapter(StripingDistressTypeAdapter());
    Hive.registerAdapter(PavementMaterialAdapter());
    Hive.registerAdapter(ShoulderMaterialAdapter());
    Hive.registerAdapter(StripingMaterialAdapter());
    Hive.registerAdapter(DistressRecordAdapter());
    Hive.registerAdapter(RoadSegmentAdapter());

    // Open local box
    await Hive.openBox<RoadSegment>(_boxName);
    _initialized = true;
  }

  static Box<RoadSegment> get _box => Hive.box<RoadSegment>(_boxName);

  /// Saves a road segment locally (offline-first)
  static Future<void> saveSegment(RoadSegment segment) async {
    if (!_initialized) return;
    await _box.put(segment.id, segment);
    
    // Attempt background sync to Firebase Firestore
    await syncSegmentToCloud(segment);
  }

  /// Retrieves all local road segments
  static List<RoadSegment> getAllSegments() {
    if (!_initialized) return [];
    try {
      return _box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  /// Retrieves a specific segment
  static RoadSegment? getSegment(String id) {
    if (!_initialized) return null;
    return _box.get(id);
  }

  /// Deletes a road segment
  static Future<void> deleteSegment(String id) async {
    if (!_initialized) return;
    await _box.delete(id);
  }

  /// Gets all unsynced segments
  static List<RoadSegment> getUnsyncedSegments() {
    if (!_initialized) return [];
    return _box.values.where((s) => !s.isSynced).toList();
  }

  /// Synchronizes a specific segment to Firestore
  static Future<void> syncSegmentToCloud(RoadSegment segment) async {
    try {
      // Check if Firebase is initialized first (avoid crash if not setup yet)
      if (Firebase.apps.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('segments').doc(segment.id).set(segment.toJson());
        
        // Update sync status locally
        segment.isSynced = true;
        await segment.save();
      }
    } catch (e) {
      print('Firebase Sync failed, remaining offline: $e');
    }
  }

  /// Scans and syncs all unsynced local records to Firestore when online
  static Future<void> syncAllUnsynced() async {
    final unsynced = getUnsyncedSegments();
    for (var segment in unsynced) {
      await syncSegmentToCloud(segment);
    }
  }
}
