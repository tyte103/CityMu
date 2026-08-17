import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/gis_constants.dart';
import '../../core/enums/feature_type.dart';
import '../../core/theme/app_theme.dart';
import '../../models/spatial_feature.dart';

/// Minimalist Map and Spatial Radar Component.
/// Provides a fluid Canvas vector radar view by default for crisp aesthetic rendering across Web and Native.
class MinimalMapView extends StatefulWidget {
  const MinimalMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.nearbyFeatures,
    this.height = 220,
  });

  final double latitude;
  final double longitude;
  final List<SpatialFeature> nearbyFeatures;
  final double height;

  @override
  State<MinimalMapView> createState() => _MinimalMapViewState();
}

class _MinimalMapViewState extends State<MinimalMapView> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  final bool _useGoogleMapsLayer = !kIsWeb;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  Set<Circle> _buildProximityCircles() {
    final circles = <Circle>{};
    final userPos = LatLng(widget.latitude, widget.longitude);

    circles.add(Circle(
      circleId: const CircleId('mrt_zone'),
      center: userPos,
      radius: GisConstants.mrtSubBassRadius,
      fillColor: AppTheme.mrtZoneBlue.withValues(alpha: 0.08),
      strokeColor: AppTheme.mrtZoneBlue.withValues(alpha: 0.3),
      strokeWidth: 1,
    ));

    circles.add(Circle(
      circleId: const CircleId('park_zone'),
      center: userPos,
      radius: GisConstants.parkAcousticRadius,
      fillColor: AppTheme.parkZoneGreen.withValues(alpha: 0.08),
      strokeColor: AppTheme.parkZoneGreen.withValues(alpha: 0.3),
      strokeWidth: 1,
    ));

    circles.add(Circle(
      circleId: const CircleId('water_zone'),
      center: userPos,
      radius: GisConstants.waterTextureRadius,
      fillColor: AppTheme.waterZoneCyan.withValues(alpha: 0.10),
      strokeColor: AppTheme.waterZoneCyan.withValues(alpha: 0.4),
      strokeWidth: 1,
    ));

    return circles;
  }

  Set<Marker> _buildFeatureMarkers() {
    return {
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(widget.latitude, widget.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorderLight,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Google Maps Layer (Native mobile or enabled)
          if (_useGoogleMapsLayer)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 16.5,
              ),
              circles: _buildProximityCircles(),
              markers: _buildFeatureMarkers(),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),

          // Minimalist Spatial Vector Radar Canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RadarOverlayPainter(
                    rippleValue: _rippleController.value,
                    features: widget.nearbyFeatures,
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                  ),
                );
              },
            ),
          ),

          // Top Right Feature Counter Badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.cardBorderLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.nearbyFeatures.length} 個空間地標',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Left Coordinates Tag
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.cardBorderLight,
                  width: 0.8,
                ),
              ),
              child: Text(
                '台北座標: ${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}',
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarOverlayPainter extends CustomPainter {
  _RadarOverlayPainter({
    required this.rippleValue,
    required this.features,
    required this.latitude,
    required this.longitude,
  });

  final double rippleValue;
  final List<SpatialFeature> features;
  final double latitude;
  final double longitude;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final maxRadius = math.min(size.width, size.height) * 0.44;

    // Background radial zone guides (50m, 100m, 150m)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 50m Water Zone ring
    ringPaint.color = AppTheme.waterZoneCyan.withValues(alpha: 0.25);
    canvas.drawCircle(center, maxRadius * (50.0 / 150.0), ringPaint);

    // 100m Power / Park Zone ring
    ringPaint.color = AppTheme.parkZoneGreen.withValues(alpha: 0.25);
    canvas.drawCircle(center, maxRadius * (100.0 / 150.0), ringPaint);

    // 150m MRT Zone ring
    ringPaint.color = AppTheme.mrtZoneBlue.withValues(alpha: 0.25);
    canvas.drawCircle(center, maxRadius, ringPaint);

    // Crosshair axis
    final axisPaint = Paint()
      ..color = AppTheme.textTertiary.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), axisPaint);
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), axisPaint);

    // Dynamic Pulsing Sensor Ripple
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppTheme.primaryBlue.withValues(alpha: (1.0 - rippleValue) * 0.35);
    canvas.drawCircle(center, maxRadius * rippleValue, ripplePaint);

    // Center Genesis Node
    final centerGlow = Paint()..color = AppTheme.primaryBlue.withValues(alpha: 0.2);
    canvas.drawCircle(center, 7.0, centerGlow);
    final centerDot = Paint()..color = AppTheme.primaryBlue;
    canvas.drawCircle(center, 3.5, centerDot);

    // Draw active spatial feature nodes
    for (final f in features) {
      final rad = (f.bearingDegrees - 90.0) * (math.pi / 180.0);
      final distRatio = (f.distanceMeters / 150.0).clamp(0.15, 0.95);
      final targetX = center.dx + math.cos(rad) * (maxRadius * distRatio);
      final targetY = center.dy + math.sin(rad) * (maxRadius * distRatio);

      Color dotColor = AppTheme.mrtZoneBlue;
      if (f.type == FeatureType.water) dotColor = AppTheme.waterZoneCyan;
      if (f.type == FeatureType.power) dotColor = AppTheme.techZoneAmber;
      if (f.type == FeatureType.park) dotColor = AppTheme.parkZoneGreen;

      // Glow halo
      final haloPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = dotColor.withValues(alpha: 0.25);
      canvas.drawCircle(Offset(targetX, targetY), 8.0, haloPaint);

      // Core dot
      final dotPaint = Paint()..color = dotColor;
      canvas.drawCircle(Offset(targetX, targetY), 3.5, dotPaint);

      // Connection ray to center
      final rayPaint = Paint()
        ..color = dotColor.withValues(alpha: 0.12)
        ..strokeWidth = 1.0;
      canvas.drawLine(center, Offset(targetX, targetY), rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarOverlayPainter oldDelegate) {
    return oldDelegate.rippleValue != rippleValue ||
        oldDelegate.features != features ||
        oldDelegate.latitude != latitude ||
        oldDelegate.longitude != longitude;
  }
}
