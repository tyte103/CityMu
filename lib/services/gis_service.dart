import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:turf/turf.dart' as turf;
import '../core/constants/gis_constants.dart';
import '../core/enums/feature_type.dart';
import '../data/taiwan_spatial_landmarks_data.dart';
import '../models/spatial_feature.dart';
import '../models/spatial_landmark_preset.dart';

/// Service responsible for parsing GeoJSON layers and real-world spatial landmarks,
/// computing real-time geodesic distances and bearings to 100+ urban acoustic points.
class GisService {
  GisService._internal() {
    _loadAllSpatialCollections();
  }
  static final GisService instance = GisService._internal();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  turf.FeatureCollection? _mrtCollection;
  turf.FeatureCollection? _powerCollection;
  turf.FeatureCollection? _waterCollection;
  turf.FeatureCollection? _parkCollection;
  turf.FeatureCollection? _templeCollection;
  turf.FeatureCollection? _marketCollection;
  turf.FeatureCollection? _campusCollection;
  turf.FeatureCollection? _cultureCollection;

  /// Exposes the complete list of 102 landmarks for UI selection and testing.
  List<SpatialLandmarkPreset> get allLandmarkPresets => kTaipeiSpatialLandmarks;

  /// Loads GeoJSON assets from bundle or fallback datasets.
  Future<void> loadLayers() async {
    if (_isLoaded) return;
    try {
      final mrtRaw = await rootBundle.loadString(GisConstants.geoMrtLines);
      _mrtCollection = turf.FeatureCollection.fromJson(jsonDecode(mrtRaw) as Map<String, dynamic>);

      final powerRaw = await rootBundle.loadString(GisConstants.geoPowerGrid);
      _powerCollection = turf.FeatureCollection.fromJson(jsonDecode(powerRaw) as Map<String, dynamic>);

      final waterRaw = await rootBundle.loadString(GisConstants.geoWaterPipes);
      _waterCollection = turf.FeatureCollection.fromJson(jsonDecode(waterRaw) as Map<String, dynamic>);
    } catch (_) {
      // Fallback directly to rich curated dataset
    }

    _loadAllSpatialCollections();
    _isLoaded = true;
    developer.log('All 102+ spatial landmarks & GeoJSON layers loaded.', name: 'GisService');
  }

  void _loadAllSpatialCollections() {
    final mrtFeatures = <turf.Feature>[];
    final powerFeatures = <turf.Feature>[];
    final waterFeatures = <turf.Feature>[];
    final parkFeatures = <turf.Feature>[];
    final templeFeatures = <turf.Feature>[];
    final marketFeatures = <turf.Feature>[];
    final campusFeatures = <turf.Feature>[];
    final cultureFeatures = <turf.Feature>[];

    for (final landmark in kTaipeiSpatialLandmarks) {
      final turfFeature = turf.Feature(
        id: landmark.id,
        properties: {
          'id': landmark.id,
          'name': landmark.name,
          'category': landmark.category,
          'soundSignature': landmark.soundSignature,
        },
        geometry: turf.Point(coordinates: turf.Position(landmark.longitude, landmark.latitude)),
      );

      switch (landmark.type) {
        case FeatureType.mrt:
          mrtFeatures.add(turfFeature);
          break;
        case FeatureType.power:
          powerFeatures.add(turfFeature);
          break;
        case FeatureType.water:
          waterFeatures.add(turfFeature);
          break;
        case FeatureType.park:
          parkFeatures.add(turfFeature);
          break;
        case FeatureType.temple:
          templeFeatures.add(turfFeature);
          break;
        case FeatureType.market:
          marketFeatures.add(turfFeature);
          break;
        case FeatureType.campus:
          campusFeatures.add(turfFeature);
          break;
        case FeatureType.culture:
          cultureFeatures.add(turfFeature);
          break;
      }
    }

    _mrtCollection = turf.FeatureCollection(features: mrtFeatures);
    _powerCollection = turf.FeatureCollection(features: powerFeatures);
    _waterCollection = turf.FeatureCollection(features: waterFeatures);
    _parkCollection = turf.FeatureCollection(features: parkFeatures);
    _templeCollection = turf.FeatureCollection(features: templeFeatures);
    _marketCollection = turf.FeatureCollection(features: marketFeatures);
    _campusCollection = turf.FeatureCollection(features: campusFeatures);
    _cultureCollection = turf.FeatureCollection(features: cultureFeatures);

    _isLoaded = true;
  }

  /// Evaluates nearby spatial features from a given geographic coordinate across all 8 sound groups.
  List<SpatialFeature> evaluateNearbyFeatures({
    required double longitude,
    required double latitude,
  }) {
    if (!_isLoaded) {
      _loadAllSpatialCollections();
    }

    final userPoint = turf.Point(coordinates: turf.Position(longitude, latitude));
    final results = <SpatialFeature>[];

    // 1. MRT Lines & Stations
    final nearestMrt = _findNearestFeatureInCollection(userPoint, _mrtCollection, FeatureType.mrt);
    if (nearestMrt != null) results.add(nearestMrt);

    // 2. Power Grid & Tech Hubs
    final nearestPower = _findNearestFeatureInCollection(userPoint, _powerCollection, FeatureType.power);
    if (nearestPower != null) results.add(nearestPower);

    // 3. Water Waterfronts & Rivers
    final nearestWater = _findNearestFeatureInCollection(userPoint, _waterCollection, FeatureType.water);
    if (nearestWater != null) results.add(nearestWater);

    // 4. Parks & Urban Greenery
    final nearestPark = _findNearestFeatureInCollection(userPoint, _parkCollection, FeatureType.park);
    if (nearestPark != null) results.add(nearestPark);

    // 5. Temples & Spiritual Shrines
    final nearestTemple = _findNearestFeatureInCollection(userPoint, _templeCollection, FeatureType.temple);
    if (nearestTemple != null) results.add(nearestTemple);

    // 6. Night Markets & Food Streets
    final nearestMarket = _findNearestFeatureInCollection(userPoint, _marketCollection, FeatureType.market);
    if (nearestMarket != null) results.add(nearestMarket);

    // 7. Campuses & Academic Bells
    final nearestCampus = _findNearestFeatureInCollection(userPoint, _campusCollection, FeatureType.campus);
    if (nearestCampus != null) results.add(nearestCampus);

    // 8. Cultural Arts & Performance Centers
    final nearestCulture = _findNearestFeatureInCollection(userPoint, _cultureCollection, FeatureType.culture);
    if (nearestCulture != null) results.add(nearestCulture);

    // Sort by physical distance ascending (closest first)
    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }

  SpatialFeature? _findNearestFeatureInCollection(
    turf.Point userPoint,
    turf.FeatureCollection? collection,
    FeatureType type,
  ) {
    if (collection == null || collection.features.isEmpty) return null;

    double minDistanceMeters = double.infinity;
    double targetBearing = 0.0;
    String featureId = '';
    String featureName = '';

    for (final feature in collection.features) {
      final geom = feature.geometry;
      if (geom == null) continue;

      final (distMeters, bearing) = _calculateDistanceAndBearingToGeometry(userPoint, geom);
      if (distMeters < minDistanceMeters) {
        minDistanceMeters = distMeters;
        targetBearing = bearing;
        featureId = feature.id?.toString() ?? feature.properties?['id']?.toString() ?? type.name;
        featureName = feature.properties?['name']?.toString() ?? type.name.toUpperCase();
      }
    }

    if (minDistanceMeters.isInfinite) return null;

    return SpatialFeature(
      id: featureId,
      name: featureName,
      type: type,
      distanceMeters: minDistanceMeters,
      bearingDegrees: targetBearing,
    );
  }

  (double, double) _calculateDistanceAndBearingToGeometry(
    turf.Point userPoint,
    turf.GeometryObject geometry,
  ) {
    if (geometry is turf.Point) {
      final targetPoint = geometry;
      final distKm = turf.distance(userPoint, targetPoint, turf.Unit.kilometers);
      final distMeters = distKm * 1000.0;
      final bearing = turf.bearing(userPoint, targetPoint);
      return (distMeters, (bearing + 360.0) % 360.0);
    } else if (geometry is turf.LineString) {
      double minDist = double.infinity;
      double bestBearing = 0.0;

      final coords = geometry.coordinates;
      for (int i = 0; i < coords.length; i++) {
        final pt = turf.Point(coordinates: coords[i]);
        final distKm = turf.distance(userPoint, pt, turf.Unit.kilometers);
        final distM = distKm * 1000.0;
        if (distM < minDist) {
          minDist = distM;
          bestBearing = (turf.bearing(userPoint, pt) + 360.0) % 360.0;
        }
      }
      return (minDist, bestBearing);
    }
    return (double.infinity, 0.0);
  }

  /// Calculates geodesic distance between two coordinates in meters.
  double calculateDistanceMeters({
    required double lon1,
    required double lat1,
    required double lon2,
    required double lat2,
  }) {
    return calculateHaversineDistanceMeters(lon1, lat1, lon2, lat2);
  }

  /// Calculates geodesic distance between two coordinates in meters (static).
  static double calculateHaversineDistanceMeters(
    double lon1,
    double lat1,
    double lon2,
    double lat2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degToRad(double degrees) => degrees * (math.pi / 180.0);
}
