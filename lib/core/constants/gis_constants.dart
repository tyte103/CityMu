/// Constants for GIS layers, spatial sensing thresholds, and influence radii.
abstract final class GisConstants {
  /// Maximum radius (meters) where MRT subway stations influence Sub-Bass volume and jingle.
  static const double mrtSubBassRadius = 150.0;

  /// Maximum radius (meters) where waterfronts influence Vinyl trickle texture & arpeggios.
  static const double waterTextureRadius = 80.0;

  /// Maximum radius (meters) where power grid & tech nodes influence spark hi-hat brilliance & YouBike bells.
  static const double powerGridRadius = 100.0;

  /// Maximum radius (meters) where park greenery influences acoustic birds and wind chimes.
  static const double parkAcousticRadius = 250.0;

  /// Maximum radius (meters) where temples & spiritual heritage influence resonant bells & singing bowls.
  static const double templeAcousticRadius = 150.0;

  /// Maximum radius (meters) where night markets & street alleys influence lively acoustic shakers.
  static const double marketAcousticRadius = 150.0;

  /// Maximum radius (meters) where university campuses influence Fu Bell Westminster harmonic chimes.
  static const double campusAcousticRadius = 200.0;

  /// Maximum radius (meters) where arts & cultural parks influence acoustic woodwind/cello warmth.
  static const double cultureAcousticRadius = 200.0;

  /// GeoJSON layer asset paths.
  static const String geoMrtLines = 'assets/geo/mrt_lines.geojson';
  static const String geoPowerGrid = 'assets/geo/power_grid.geojson';
  static const String geoWaterPipes = 'assets/geo/water_pipes.geojson';

  /// Default demo coordinate (Taipei Main Station area).
  static const double defaultLongitude = 121.5170;
  static const double defaultLatitude = 25.0478;
}
