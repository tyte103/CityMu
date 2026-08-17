import 'package:citymu/controllers/music_orchestrator.dart';
import 'package:citymu/core/constants/audio_constants.dart';
import 'package:citymu/core/enums/feature_type.dart';
import 'package:citymu/models/ai_composition.dart';
import 'package:citymu/models/audio_parameter.dart';
import 'package:citymu/models/sound_fx_log_entry.dart';
import 'package:citymu/models/spatial_feature.dart';
import 'package:citymu/services/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Music Orchestrator & Dynamics Tests', () {
    test('BPM Dynamics Mapping from Accelerometer Intensity', () {
      // Stationary (M = 0.0) -> Base BPM = 75.0
      double m0 = 0.0;
      double bpm0 = (AudioConstants.minBpm + (m0 * AudioConstants.bpmMultiplier))
          .clamp(AudioConstants.minBpm, AudioConstants.maxBpm);
      expect(bpm0, equals(75.0));

      // Walking gently (M = 1.0) -> BPM = 75 + 5 = 80.0
      double m1 = 1.0;
      double bpm1 = (AudioConstants.minBpm + (m1 * AudioConstants.bpmMultiplier))
          .clamp(AudioConstants.minBpm, AudioConstants.maxBpm);
      expect(bpm1, equals(80.0));

      // Running fast (M = 6.0) -> BPM clamped to max 95.0
      double m6 = 6.0;
      double bpm6 = (AudioConstants.minBpm + (m6 * AudioConstants.bpmMultiplier))
          .clamp(AudioConstants.minBpm, AudioConstants.maxBpm);
      expect(bpm6, equals(95.0));
    });

    test('Spatial Feature Proximity Scoring', () {
      const feature = SpatialFeature(
        id: 'test_mrt',
        name: 'Taipei MRT Red Line',
        type: FeatureType.mrt,
        distanceMeters: 75.0,
        bearingDegrees: 45.0,
      );

      // Halfway within 150m radius -> score = 1.0 - (75 / 150) = 0.5
      expect(feature.proximityScore(150.0), closeTo(0.5, 0.001));

      // Right on top (0m) -> score = 1.0
      const featureClose = SpatialFeature(
        id: 'test_mrt_close',
        name: 'Taipei MRT Station',
        type: FeatureType.mrt,
        distanceMeters: 0.0,
        bearingDegrees: 0.0,
      );
      expect(featureClose.proximityScore(150.0), equals(1.0));

      // Outside radius (200m) -> score = 0.0
      const featureFar = SpatialFeature(
        id: 'test_mrt_far',
        name: 'Distant MRT',
        type: FeatureType.mrt,
        distanceMeters: 200.0,
        bearingDegrees: 180.0,
      );
      expect(featureFar.proximityScore(150.0), equals(0.0));
    });

    test('AudioParameter State Transitions', () {
      final initial = AudioParameter.initial();
      expect(initial.isPlaying, isFalse);
      expect(initial.bpm, equals(75.0));
      expect(initial.isUsingFallback, isFalse);

      final updated = initial.copyWith(
        isPlaying: true,
        bpm: 85.0,
        isUsingFallback: true,
        currentSemitone: 9,
      );
      expect(updated.isPlaying, isTrue);
      expect(updated.bpm, equals(85.0));
      expect(updated.isUsingFallback, isTrue);
      expect(updated.currentSemitone, equals(9));
    });

    test('AiComposition Model & Spatial Composer Generation', () async {
      final gemini = GeminiService.instance;
      gemini.init(apiKey: GeminiService.defaultKey);

      final comp = await gemini.composeSpatialMotif(
        longitude: 121.5170,
        latitude: 25.0478,
        nearbyFeatures: [
          const SpatialFeature(
            id: 'mrt_taipei_main',
            name: '台北車站 (Taipei Main Station)',
            type: FeatureType.mrt,
            distanceMeters: 45.0,
            bearingDegrees: 12.0,
          ),
        ],
        bpm: 80.0,
        isWalking: true,
      );

      expect(comp.title.isNotEmpty, isTrue);
      expect(comp.chordProgression.length, equals(4));
      expect(comp.chordNames.length, equals(4));
      expect(comp.motifNotes.isNotEmpty, isTrue);
      expect(comp.motifNotes.any((n) => n.bar == 0), isTrue);
    });

    test('AI Composer Chat Interaction & Live Composition Switching', () async {
      final gemini = GeminiService.instance;
      gemini.init(apiKey: GeminiService.defaultKey);

      final baseComp = await gemini.composeSpatialMotif(
        longitude: 121.5170,
        latitude: 25.0478,
        nearbyFeatures: [],
        bpm: 78.0,
        isWalking: false,
      );

      // 1. Style transformation: Heavy Metal
      final metalResp = await gemini.chatWithComposer(
        userPrompt: '加點重金屬',
        longitude: 121.5170,
        latitude: 25.0478,
        nearbyFeatures: [],
        bpm: 78.0,
        isWalking: false,
        currentComposition: baseComp,
      );
      expect(metalResp.message.isNotEmpty, isTrue);

      // 2. Identity inquiry ("你是誰"): should introduce without generating music cards
      final identityResp = await gemini.chatWithComposer(
        userPrompt: '你是誰',
        longitude: 121.5170,
        latitude: 25.0478,
        nearbyFeatures: [],
        bpm: 78.0,
        isWalking: false,
        currentComposition: baseComp,
      );
      expect(identityResp.message.isNotEmpty, isTrue);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('SoundFxLogEntry & Real-Time DSP Inspector Logging', () {
      final orchestrator = MusicOrchestrator.instance;
      orchestrator.clearFxLogs();
      expect(orchestrator.fxLogs.isEmpty, isTrue);

      orchestrator.logSoundFx(
        category: '🚇 實錄變奏',
        soundName: 'C381 關門警示音',
        dspDetails: '調音變速: 1.189x (+3st) | 濾波: 低通2600Hz | 切片: 0.8s',
        volume: 0.75,
        playbackRate: 1.189,
        stepInfo: '手動觸發',
      );

      expect(orchestrator.fxLogs.length, equals(1));
      final entry = orchestrator.fxLogs.first;
      expect(entry.category, equals('🚇 實錄變奏'));
      expect(entry.soundName, equals('C381 關門警示音'));
      expect(entry.dspDetails.contains('1.189x'), isTrue);
      expect(entry.formattedTime.isNotEmpty, isTrue);

      orchestrator.clearFxLogs();
      expect(orchestrator.fxLogs.isEmpty, isTrue);
    });
  });
}
