import 'package:flutter_test/flutter_test.dart';
import 'package:citymu/core/enums/feature_type.dart';
import 'package:citymu/data/taiwan_spatial_landmarks_data.dart';
import 'package:citymu/services/gis_service.dart';

void main() {
  group('Taipei 102 Spatial Landmarks & 8 Acoustic Groups Tests', () {
    test('Dataset contains exactly 102 curated landmarks across 8 categories', () {
      expect(kTaipeiSpatialLandmarks.length, 102);

      final categories = kTaipeiSpatialLandmarks.map((e) => e.category).toSet();
      expect(categories.length, 8);

      final types = kTaipeiSpatialLandmarks.map((e) => e.type).toSet();
      expect(types.length, 8);
      expect(types.contains(FeatureType.mrt), isTrue);
      expect(types.contains(FeatureType.park), isTrue);
      expect(types.contains(FeatureType.water), isTrue);
      expect(types.contains(FeatureType.power), isTrue);
      expect(types.contains(FeatureType.temple), isTrue);
      expect(types.contains(FeatureType.market), isTrue);
      expect(types.contains(FeatureType.campus), isTrue);
      expect(types.contains(FeatureType.culture), isTrue);
    });

    test('All landmarks have valid GPS coordinates in Greater Taipei area', () {
      for (final landmark in kTaipeiSpatialLandmarks) {
        expect(landmark.longitude, greaterThanOrEqualTo(121.30));
        expect(landmark.longitude, lessThanOrEqualTo(121.80));
        expect(landmark.latitude, greaterThanOrEqualTo(24.90));
        expect(landmark.latitude, lessThanOrEqualTo(25.30));
        expect(landmark.name.isNotEmpty, isTrue);
        expect(landmark.soundSignature.isNotEmpty, isTrue);
      }
    });

    test('GisService evaluates nearby features correctly across 8 categories', () {
      final gis = GisService.instance;
      // Evaluate at Taipei Main Station (121.5170, 25.0478)
      final features = gis.evaluateNearbyFeatures(longitude: 121.5170, latitude: 25.0478);

      expect(features.isNotEmpty, isTrue);
      expect(features.length, 8);

      final mrtFeature = features.firstWhere((f) => f.type == FeatureType.mrt);
      expect(mrtFeature.id, 'mrt_taipei_main');
      expect(mrtFeature.distanceMeters, lessThan(10.0)); // Exactly at Taipei Main Station
    });
  });
}
