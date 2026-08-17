import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/spatial_feature.dart';

/// Service managing Firebase Cloud Firestore synchronization for spatial soundscapes.
class FirebaseService {
  FirebaseService._internal();
  static final FirebaseService instance = FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseFirestore? _firestore;

  /// Initializes Firebase Core and Firestore instances.
  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        // Will initialize with default platform options if google-services.json / GoogleService-Info.plist are present
        await Firebase.initializeApp();
      }
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      developer.log('FirebaseService initialized successfully.', name: 'FirebaseService');
    } catch (e) {
      developer.log('Firebase not initialized with platform files (running in standalone offline mode): $e', name: 'FirebaseService');
      _isInitialized = false;
    }
  }

  /// Saves a spatial soundscape session snapshot to Firestore.
  Future<void> logSoundscapeSession({
    required double longitude,
    required double latitude,
    required double bpm,
    required String moodTitle,
    required List<SpatialFeature> activeFeatures,
  }) async {
    if (!_isInitialized || _firestore == null) return;

    try {
      await _firestore!.collection('soundscape_sessions').add({
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(latitude, longitude),
        'bpm': bpm,
        'moodTitle': moodTitle,
        'activeFeatures': activeFeatures.map((f) => {
          'id': f.id,
          'name': f.name,
          'type': f.type.name,
          'distance': f.distanceMeters,
        }).toList(),
      });
    } catch (e) {
      developer.log('Error logging session to Firestore: $e', name: 'FirebaseService');
    }
  }
}
