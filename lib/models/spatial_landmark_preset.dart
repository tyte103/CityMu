import '../core/enums/feature_type.dart';

/// Represents a curated real-world landmark preset in Taiwan.
class SpatialLandmarkPreset {
  const SpatialLandmarkPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.longitude,
    required this.latitude,
    required this.description,
    required this.soundSignature,
    required this.icon,
  });

  final String id;
  final String name;
  final String category;
  final FeatureType type;
  final double longitude;
  final double latitude;
  final String description;
  final String soundSignature;
  final String icon;
}
