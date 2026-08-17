import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import '../core/constants/audio_constants.dart';

/// Service responsible for reading 3-axis accelerometer data, calculating
/// de-gravity motion intensity (M), and driving dynamic BPM.
class SensorService {
  SensorService._internal();
  static final SensorService instance = SensorService._internal();

  final _motionController = StreamController<double>.broadcast();
  Stream<double> get motionStream => _motionController.stream;

  StreamSubscription<UserAccelerometerEvent>? _userAccelSubscription;
  StreamSubscription<AccelerometerEvent>? _rawAccelSubscription;

  bool _isMockMode = false;
  bool get isMockMode => _isMockMode;

  double _smoothedIntensity = 0.0;
  double get currentIntensity => _smoothedIntensity;

  double _currentBpm = AudioConstants.minBpm;
  double get currentBpm => _currentBpm;

  bool get isWalking => _smoothedIntensity >= AudioConstants.motionStationaryThreshold;

  /// Starts listening to device accelerometer sensors.
  void init() {
    try {
      // Prefer UserAccelerometer (already filters out static 9.8m/s^2 gravity)
      _userAccelSubscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          if (_isMockMode) return;
          final rawMagnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          _processMagnitude(rawMagnitude);
        },
        onError: (dynamic error) {
          developer.log('UserAccelerometer error, falling back to raw accelerometer: $error', name: 'SensorService');
          _fallbackToRawAccelerometer();
        },
      );
    } catch (e) {
      developer.log('SensorService userAccelerometer unavailable: $e', name: 'SensorService');
      _fallbackToRawAccelerometer();
    }
  }

  void _fallbackToRawAccelerometer() {
    try {
      _rawAccelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (_isMockMode) return;
        final totalMag = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        final deGravMag = math.max(0.0, totalMag - AudioConstants.standardGravity);
        _processMagnitude(deGravMag);
      });
    } catch (e) {
      developer.log('SensorService raw accelerometer unavailable: $e', name: 'SensorService');
    }
  }

  void _processMagnitude(double magnitude) {
    // Low-pass filter: smooth = alpha * new + (1 - alpha) * old
    const alpha = 0.25;
    _smoothedIntensity = (alpha * magnitude) + ((1.0 - alpha) * _smoothedIntensity);

    // Calculate dynamic BPM
    _currentBpm = (AudioConstants.minBpm + (_smoothedIntensity * AudioConstants.bpmMultiplier))
        .clamp(AudioConstants.minBpm, AudioConstants.maxBpm);

    if (!_motionController.isClosed) {
      _motionController.add(_smoothedIntensity);
    }
  }

  /// Sets simulated motion intensity (m/s^2) for manual testing in emulator.
  void setMockIntensity(double intensity) {
    _isMockMode = true;
    _smoothedIntensity = intensity;
    _currentBpm = (AudioConstants.minBpm + (_smoothedIntensity * AudioConstants.bpmMultiplier))
        .clamp(AudioConstants.minBpm, AudioConstants.maxBpm);

    if (!_motionController.isClosed) {
      _motionController.add(_smoothedIntensity);
    }
  }

  /// Resumes hardware sensor reading.
  void resumeHardwareSensors() {
    _isMockMode = false;
  }

  void dispose() {
    _userAccelSubscription?.cancel();
    _rawAccelSubscription?.cancel();
    _motionController.close();
  }
}
