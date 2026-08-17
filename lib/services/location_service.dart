import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import '../core/constants/gis_constants.dart';

/// Service managing GPS coordinates, permission checks, and simulator location injection.
class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  final _locationController = StreamController<(double lon, double lat)>.broadcast();
  Stream<(double lon, double lat)> get locationStream => _locationController.stream;

  StreamSubscription<Position>? _positionSubscription;
  bool _isMockMode = false;
  bool get isMockMode => _isMockMode;

  double _currentLon = GisConstants.defaultLongitude;
  double _currentLat = GisConstants.defaultLatitude;
  (double lon, double lat) get currentLocation => (_currentLon, _currentLat);

  /// Initializes location services and requests permissions if needed.
  Future<bool> init() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Location services are disabled, using default/mock coordinates.', name: 'LocationService');
        _isMockMode = true;
        _emitLocation(_currentLon, _currentLat);
        return false;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          developer.log('Location permission denied, using mock coordinates.', name: 'LocationService');
          _isMockMode = true;
          _emitLocation(_currentLon, _currentLat);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log('Location permission permanently denied.', name: 'LocationService');
        _isMockMode = true;
        _emitLocation(_currentLon, _currentLat);
        return false;
      }

      _startRealLocationStream();
      return true;
    } catch (e) {
      developer.log('LocationService init exception: $e', name: 'LocationService');
      _isMockMode = true;
      _emitLocation(_currentLon, _currentLat);
      return false;
    }
  }

  void _startRealLocationStream() {
    _positionSubscription?.cancel();
    _isMockMode = false;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // Update every 2 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentLon = position.longitude;
      _currentLat = position.latitude;
      _emitLocation(_currentLon, _currentLat);
    }, onError: (dynamic error) {
      developer.log('Position stream error: $error', name: 'LocationService');
    });
  }

  /// Sets simulation/mock mode with specific coordinates.
  void setMockLocation(double longitude, double latitude) {
    _isMockMode = true;
    _positionSubscription?.cancel();
    _currentLon = longitude;
    _currentLat = latitude;
    _emitLocation(_currentLon, _currentLat);
  }

  /// Restores live GPS tracking.
  void resumeLiveGps() {
    _startRealLocationStream();
  }

  void _emitLocation(double lon, double lat) {
    if (!_locationController.isClosed) {
      _locationController.add((lon, lat));
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
  }
}
