import '../core/enums/feature_type.dart';

/// Represents a detected geographic feature and its computed distance/bearing.
class SpatialFeature {
  const SpatialFeature({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceMeters,
    required this.bearingDegrees,
    this.intensity = 1.0,
  });

  final String id;
  final String name;
  final FeatureType type;
  final double distanceMeters;
  final double bearingDegrees;
  final double intensity;

  /// Normalized proximity score from 0.0 (far) to 1.0 (right on top of the feature)
  double proximityScore(double maxRadius) {
    if (distanceMeters >= maxRadius) return 0.0;
    return (1.0 - (distanceMeters / maxRadius)).clamp(0.0, 1.0);
  }
}
