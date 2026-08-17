import 'package:citymu/core/enums/feature_type.dart';
import 'package:citymu/services/gis_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GIS & Spatial Geometry Tests', () {
    test('Haversine Geodesic Distance Calculation', () {
      // Distance between Taipei Main Station (121.5170, 25.0478) and Zhongshan Station (~121.5205, 25.0530)
      final dist = GisService.calculateHaversineDistanceMeters(
        121.5170, 25.0478,
        121.5205, 25.0530,
      );

      // Expected approx 670m - 700m
      expect(dist, greaterThan(600.0));
      expect(dist, lessThan(800.0));
    });

    test('Evaluate Nearby Features from Fallback Layers', () {
      final gis = GisService.instance;

      // Evaluate near Taipei Main Station
      final features = gis.evaluateNearbyFeatures(
        longitude: 121.5170,
        latitude: 25.0478,
      );

      expect(features, isNotEmpty);
      final mrtFeature = features.firstWhere((f) => f.type == FeatureType.mrt);
      expect(mrtFeature.id, equals('mrt_taipei_main'));
      expect(mrtFeature.distanceMeters, closeTo(0.0, 5.0)); // User is on the coordinate
    });
  });
}
