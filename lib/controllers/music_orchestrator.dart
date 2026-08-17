import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/audio_constants.dart';
import '../core/constants/gis_constants.dart';
import '../core/enums/feature_type.dart';
import '../models/ai_composition.dart';
import '../models/ambient_mood.dart';
import '../models/audio_parameter.dart';
import '../models/sound_fx_log_entry.dart';
import '../models/spatial_feature.dart';
import '../services/audio_engine_service.dart';
import '../services/foreground_service.dart';
import '../services/gemini_service.dart';
import '../services/gis_service.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';

/// Item descriptor for real field recording MRT sounds with pitch tuning and slice metadata.
class RealMrtItem {
  final String key;
  final String title;
  final String model;
  final String description;
  final String assetPath;
  final int baseSemitone;
  final double sliceOffset;
  final double sliceDuration;
  final bool isVoice;

  const RealMrtItem({
    required this.key,
    required this.title,
    required this.model,
    required this.description,
    required this.assetPath,
    this.baseSemitone = 0,
    this.sliceOffset = 0.1,
    this.sliceDuration = 1.2,
    this.isVoice = false,
  });
}

/// Central Controller orchestrating location, sensors, Google Gemini Spatial AI, and Lo-Fi audio engine.
class MusicOrchestrator extends ChangeNotifier {
  MusicOrchestrator._internal();
  static final MusicOrchestrator instance = MusicOrchestrator._internal();

  final AudioEngineService _audioEngine = AudioEngineService.instance;
  final GisService _gisService = GisService.instance;
  final LocationService _locationService = LocationService.instance;
  final SensorService _sensorService = SensorService.instance;
  final GeminiService _geminiService = GeminiService.instance;
  final ForegroundService _foregroundService = ForegroundService.instance;

  AudioParameter _state = AudioParameter.initial();
  AudioParameter get state => _state;

  List<SpatialFeature> _nearbyFeatures = [];
  List<SpatialFeature> get nearbyFeatures => _nearbyFeatures;

  AmbientMood _currentMood = AmbientMood.defaultMood();
  AmbientMood get currentMood => _currentMood;

  // Real-Time Gemini AI Spatial Composition State
  AiComposition _currentComposition = AiComposition.defaultTaipeiStation(121.5170, 25.0478);
  AiComposition get currentComposition => _currentComposition;

  bool _isComposingAi = false;
  bool get isComposingAi => _isComposingAi;

  (double, double)? _lastComposedLocation;
  static const double locationRegenerationThresholdMeters = 150.0;

  // Live Sound FX & DSP Inspector Log Stream (Latest 80 events)
  final List<SoundFxLogEntry> _fxLogs = [];
  List<SoundFxLogEntry> get fxLogs => List.unmodifiable(_fxLogs);

  void logSoundFx({
    required String category,
    required String soundName,
    required String dspDetails,
    required double volume,
    double? playbackRate,
    int? semitone,
    String? chord,
    String? stepInfo,
  }) {
    _fxLogs.insert(
      0,
      SoundFxLogEntry(
        timestamp: DateTime.now(),
        category: category,
        soundName: soundName,
        dspDetails: dspDetails,
        volume: volume,
        playbackRate: playbackRate,
        semitone: semitone,
        chord: chord,
        stepInfo: stepInfo,
      ),
    );
    if (_fxLogs.length > 80) {
      _fxLogs.removeLast();
    }
    notifyListeners();
  }

  void clearFxLogs() {
    _fxLogs.clear();
    notifyListeners();
  }

  Timer? _stepTimer;
  int _currentStep = 0;
  int _barIndex = 0;
  int _totalBarCount = 0;
  int _lastSemitone = 0;
  int _mrtCycleIndex = 0;
  final math.Random _random = math.Random();

  // Spatial Proximity Flags (Across 100+ Real Urban Landmarks)
  bool isMrtInRange = true;
  bool isWaterInRange = false;
  bool isPowerInRange = false;
  bool isParkInRange = false;
  bool isYouBikeInRange = false;
  bool isTempleInRange = false;
  bool isMarketInRange = false;
  bool isCampusInRange = false;
  bool isCultureInRange = false;

  // Track Mute Controls
  bool isPadMuted = false;
  bool isMelodyMuted = false;
  bool isDrumsMuted = false;
  bool isFoleyMuted = false;

  // Real MRT Recording Focus Mode
  bool _mrtSoundscapeEnabled = true;
  bool get mrtSoundscapeEnabled => _mrtSoundscapeEnabled;

  void toggleMrtSoundscape() {
    _mrtSoundscapeEnabled = !_mrtSoundscapeEnabled;
    notifyListeners();
  }

  void toggleTrackMute(String track) {
    switch (track) {
      case 'pad':
        isPadMuted = !isPadMuted;
        break;
      case 'melody':
        isMelodyMuted = !isMelodyMuted;
        break;
      case 'drums':
        isDrumsMuted = !isDrumsMuted;
        break;
      case 'foley':
        isFoleyMuted = !isFoleyMuted;
        break;
    }
    notifyListeners();
  }

  /// 10 Real Taipei MRT Field Recordings with harmonic tuning and slice windows
  static const List<RealMrtItem> realMrtCollection = [
    RealMrtItem(
      key: 'c301_closing',
      title: 'C301 關門警示音',
      model: 'URC / 川崎重工 C301',
      description: '淡水信義線經典高運量列車關門動機',
      assetPath: AudioConstants.realMrtC301DoorClosing,
      baseSemitone: 5,
      sliceOffset: 0.12,
      sliceDuration: 1.1,
    ),
    RealMrtItem(
      key: 'c321_closing',
      title: 'C321 關門警示音',
      model: '西門子 Siemens C321',
      description: '板南線高運量主力列車關門聲',
      assetPath: AudioConstants.realMrtC321DoorClosing,
      baseSemitone: 7,
      sliceOffset: 0.08,
      sliceDuration: 1.0,
    ),
    RealMrtItem(
      key: 'c341_closing',
      title: 'C341 關門警示音',
      model: '西門子 Siemens C341',
      description: '板南線改進型列車關門提示音',
      assetPath: AudioConstants.realMrtC341DoorClosing,
      baseSemitone: 7,
      sliceOffset: 0.08,
      sliceDuration: 1.0,
    ),
    RealMrtItem(
      key: 'c371_opening',
      title: 'C371 開門提示音',
      model: '川崎重工 / 台灣車輛 C371',
      description: '松山新店/中和新蘆線進站開門提示',
      assetPath: AudioConstants.realMrtC371DoorOpening,
      baseSemitone: 2,
      sliceOffset: 0.15,
      sliceDuration: 0.95,
    ),
    RealMrtItem(
      key: 'c371_closing',
      title: 'C371 關門警示音',
      model: '川崎重工 / 台灣車輛 C371',
      description: '松山新店/中和新蘆線關門聲響',
      assetPath: AudioConstants.realMrtC371DoorClosing,
      baseSemitone: 2,
      sliceOffset: 0.12,
      sliceDuration: 1.1,
    ),
    RealMrtItem(
      key: 'c381_opening',
      title: 'C381 開門提示音',
      model: '川崎重工 / 台灣車輛 C381',
      description: '信義線/松山線最新主力車型開門音',
      assetPath: AudioConstants.realMrtC381DoorOpening,
      baseSemitone: 0,
      sliceOffset: 0.10,
      sliceDuration: 0.9,
    ),
    RealMrtItem(
      key: 'c381_closing',
      title: 'C381 關門警示音',
      model: '川崎重工 / 台灣車輛 C381',
      description: '信義線/松山線最新主力車型關門音',
      assetPath: AudioConstants.realMrtC381DoorClosing,
      baseSemitone: 0,
      sliceOffset: 0.10,
      sliceDuration: 1.0,
    ),
    RealMrtItem(
      key: 'circular_arrival',
      title: '環狀線 到站廣播',
      model: '日立軌道 Hitachi 環狀線',
      description: '環狀線無人駕駛列車到站語音',
      assetPath: AudioConstants.realMrtCircularArrival,
      baseSemitone: 0,
      sliceOffset: 0.05,
      sliceDuration: 2.2,
      isVoice: true,
    ),
    RealMrtItem(
      key: 'circular_closing',
      title: '環狀線 關門連鎖音',
      model: '日立軌道 Hitachi 環狀線',
      description: '環狀線特色關門音階連鎖聲響',
      assetPath: AudioConstants.realMrtCircularClosing,
      baseSemitone: 4,
      sliceOffset: 0.15,
      sliceDuration: 1.2,
    ),
    RealMrtItem(
      key: 'doors_closing_voice',
      title: '車門即將關閉 語音',
      model: '台北捷運全線廣播語音',
      description: '溫潤女聲「車門即將關閉」廣播',
      assetPath: AudioConstants.realMrtClosingVoice,
      baseSemitone: 0,
      sliceOffset: 0.05,
      sliceDuration: 1.6,
      isVoice: true,
    ),
  ];

  StreamSubscription? _locationSub;
  StreamSubscription? _sensorSub;

  /// Initializes all underlying services and sets up Gemini AI.
  Future<void> init({String? geminiApiKey}) async {
    await _audioEngine.init();
    await _gisService.loadLayers();
    await _locationService.init();
    _sensorService.init();
    _geminiService.init(apiKey: geminiApiKey);
    _foregroundService.init();

    _locationSub = _locationService.locationStream.listen((loc) {
      _handleLocationUpdate(loc.$1, loc.$2);
    });

    _sensorSub = _sensorService.motionStream.listen((intensity) {
      _handleMotionUpdate(intensity);
    });

    final initialLoc = _locationService.currentLocation;
    _handleLocationUpdate(initialLoc.$1, initialLoc.$2, forceRecompose: true);
  }

  /// Manually test-plays a specific real MRT field recording sample.
  Future<void> testPlayRealMrtSample(RealMrtItem item) async {
    _state = _state.copyWith(
      activeSoundSource: '🚇 [試聽] ${item.title}',
    );
    notifyListeners();
    await _audioEngine.triggerRealMrtSample(
      item.assetPath,
      volume: 0.75,
      playbackRate: 1.0,
      lowpassFreq: 4000.0,
      offsetSeconds: item.sliceOffset,
      durationSeconds: item.sliceDuration,
    );
  }

  /// Toggles master playback state.
  Future<void> togglePlay() async {
    if (_state.isPlaying) {
      await stop();
    } else {
      await start();
    }
  }

  /// Starts the Lo-Fi musical engine and sequencer clock.
  Future<void> start() async {
    if (_state.isPlaying) return;

    _state = _state.copyWith(
      isPlaying: true,
      activeSoundSource: '演奏中 · ${_currentComposition.title}',
    );
    notifyListeners();

    _audioEngine.setSubBassVolume(_state.subBassVolume);
    _audioEngine.setVinylVolume(_state.vinylVolume);

    await _foregroundService.startService(
      statusText: '${_currentComposition.title} · ${_state.bpm.toStringAsFixed(0)} BPM',
    );

    _scheduleNextStep();
  }

  /// Stops playback and mutes all active tracks.
  Future<void> stop() async {
    _stepTimer?.cancel();
    _stepTimer = null;
    _currentStep = 0;
    _barIndex = 0;
    _totalBarCount = 0;
    _lastSemitone = 0;

    await _audioEngine.stopAll();
    await _foregroundService.stopService();

    _state = _state.copyWith(
      isPlaying: false,
      subBassVolume: 0.0,
      vinylVolume: 0.0,
      sparkVolume: 0.0,
      stepIndex: 0,
      barIndex: 0,
      currentChordName: _currentComposition.chordNames[0],
      activeSoundSource: '待機中',
      isKickActive: false,
      isSnareActive: false,
      isHiHatActive: false,
      isPadActive: false,
    );
    notifyListeners();
  }

  void _scheduleNextStep() {
    if (!_state.isPlaying) return;

    final baseStepMs = (60000.0 / _state.bpm) / 4.0;
    final swingOffset = (_currentStep % 2 == 1) ? (baseStepMs * 0.06) : 0.0;
    final stepDurationMs = baseStepMs + swingOffset;

    _stepTimer = Timer(Duration(milliseconds: math.max(20, stepDurationMs.round())), () {
      _executeStep();
      _scheduleNextStep();
    });
  }

  Future<void> _executeStep() async {
    if (!_state.isPlaying) return;

    final step = _currentStep;
    final bar = _barIndex % 4;
    final isWalking = _sensorService.isWalking;
    final humanVelocity = (0.94 + (_random.nextDouble() * 0.12)).clamp(0.85, 1.15);

    final chord = _currentComposition.chordProgression[bar];
    final chordName = _currentComposition.chordNames[bar];
    final rootSemitone = _currentComposition.rootSemitones[bar];

    int semitone = _lastSemitone;
    bool isKick = false;
    bool isSnare = false;
    bool isHiHat = false;
    bool isPad = false;
    String activeSound = _currentComposition.title;

    // 1. Lush Warm Rhodes Chord Pad & Dynamic Lo-Fi Bass on Step 0 / 8 (if not muted)
    if (!isPadMuted) {
      if (step == 0) {
        isPad = true;
        activeSound = '$chordName 暖陽和弦 Pad';
        final padVol = 0.62 * _currentComposition.melodyWeight * humanVelocity;
        await _audioEngine.playPad(
          semitones: chord,
          volume: padVol,
          durationSeconds: 3.2,
        );
        logSoundFx(
          category: '🎹 和弦 Pad',
          soundName: '$chordName 暖音合成器',
          dspDetails: '半音: ${chord.join(", ")} | 延音: 3.2s | 力度: ${(humanVelocity * 100).toInt()}%',
          volume: padVol,
          chord: chordName,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );

        // Deep Root Bass Note on Downbeat
        final bassVol = 0.75 * _currentComposition.bassWeight * humanVelocity;
        await _audioEngine.playBassNote(
          semitones: rootSemitone,
          volume: bassVol,
          durationSeconds: 0.9,
        );
        logSoundFx(
          category: '🎸 Lo-Fi 貝斯',
          soundName: '${_noteName(rootSemitone)} 正弦低音',
          dspDetails: '根音半音: $rootSemitone | 截止低通: 450Hz | 延音: 0.9s',
          volume: bassVol,
          semitone: rootSemitone,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      } else if (step == 8 || (step == 10 && _random.nextDouble() < 0.5)) {
        // Groovy Passing Bass Note (Fifth or Root)
        final bassTone = (step == 8) ? (rootSemitone + 7) : rootSemitone;
        final bassVol = 0.60 * _currentComposition.bassWeight * humanVelocity;
        await _audioEngine.playBassNote(
          semitones: bassTone,
          volume: bassVol,
          durationSeconds: 0.5,
        );
        logSoundFx(
          category: '🎸 Lo-Fi 貝斯',
          soundName: '${_noteName(bassTone)} 過渡低音',
          dspDetails: '五音半音: $bassTone | 延音: 0.5s | 音量: ${(bassVol * 100).toInt()}%',
          volume: bassVol,
          semitone: bassTone,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      }
    }

    // 2. Pure Lo-Fi Recurring AI-Composed Motif Melody Execution (if not muted)
    if (!isMelodyMuted) {
      final matchedNotes = _currentComposition.motifNotes.where((m) => m.bar == bar && m.step == step);
      if (matchedNotes.isNotEmpty) {
        final note = matchedNotes.first;
        semitone = note.semitone;
        activeSound = '${_noteName(semitone)} 空間專屬 AI 動機';
        final melodyVol = 0.76 * note.velocity * _currentComposition.melodyWeight * humanVelocity;

        // Jazz Grace Note (微裝飾音)
        if (note.hasGraceNote) {
          _audioEngine.playMelodyNote(
            semitones: semitone - 1,
            volume: 0.35 * humanVelocity,
          );
          await Future.delayed(const Duration(milliseconds: 28));
        }

        await _audioEngine.playMelodyNote(
          semitones: semitone,
          volume: melodyVol,
        );

        logSoundFx(
          category: '✨ 主奏旋律',
          soundName: '${_noteName(semitone)} 空間專屬 AI 動機',
          dspDetails: '音高: $semitone | 裝飾音: ${note.hasGraceNote ? "微裝飾(-1)" : "無"} | 力度: ${(note.velocity * 100).toInt()}%',
          volume: melodyVol,
          semitone: semitone,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      }
    }

    // 3. Harmonic MRT Soundscape Integration (Sliced, Tuned & Non-Intrusive)
    if (!isFoleyMuted && isMrtInRange && _mrtSoundscapeEnabled) {
      if (step == 6 && (_random.nextDouble() < 0.40)) {
        // 🚇 Tuned 5-Note Jingle Motif
        activeSound = '🚇 捷運進站五音動機';
        final vol = 0.65 * _currentComposition.melodyWeight * humanVelocity;
        await _audioEngine.triggerMrtJingle(volume: vol);
        logSoundFx(
          category: '🚇 捷運聲景',
          soundName: '台北捷運進站五音 Jingle',
          dspDetails: '音調對齊: D5-G5-A5-B5-D6 | 泛音濾波: 2800Hz | 音量: ${(vol * 100).toInt()}%',
          volume: vol,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      } else if (step == 14 && (_random.nextDouble() < 0.35)) {
        // 🚇 Crisp Card Tap Triplet Accent
        activeSound = '🚇 捷運刷卡三連音';
        final vol = 0.60 * humanVelocity;
        await _audioEngine.triggerMrtCardTap(volume: vol);
        logSoundFx(
          category: '🚇 捷運聲景',
          soundName: '捷運閘門感應三連音',
          dspDetails: '高通濾波: 1200Hz | 三連音切片: 0.08s | 音量: ${(vol * 100).toInt()}%',
          volume: vol,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      } else if (step == 0 && (_barIndex % 2 == 0) && (_random.nextDouble() < 0.35)) {
        // 🚇 Tuned Sliced Real Train Door Chime
        final mrtItem = realMrtCollection[_mrtCycleIndex % realMrtCollection.length];
        activeSound = '🚇 [實錄變奏] ${mrtItem.title}';

        double playbackRate = 1.0;
        int semitoneDelta = 0;
        if (!mrtItem.isVoice) {
          semitoneDelta = (rootSemitone - mrtItem.baseSemitone) % 12;
          final normalizedDelta = semitoneDelta > 6 ? (semitoneDelta - 12) : semitoneDelta;
          playbackRate = math.pow(2.0, normalizedDelta / 12.0).toDouble();
        }

        final vol = 0.32 * humanVelocity;
        await _audioEngine.triggerRealMrtSample(
          mrtItem.assetPath,
          volume: vol,
          playbackRate: playbackRate,
          lowpassFreq: 2600.0,
          offsetSeconds: mrtItem.sliceOffset,
          durationSeconds: mrtItem.sliceDuration,
        );
        logSoundFx(
          category: '🚇 實錄變奏',
          soundName: mrtItem.title,
          dspDetails: '調音變速: ${playbackRate.toStringAsFixed(3)}x (${semitoneDelta >= 0 ? "+$semitoneDelta" : semitoneDelta}st) | 濾波: 低通2600Hz | 切片: ${mrtItem.sliceDuration}s',
          volume: vol,
          playbackRate: playbackRate,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
        _mrtCycleIndex++;
      }
    }

    // 4. Spatial Environmental Accents (Evaluated purely by distance across 100+ landmarks)
    if (!isFoleyMuted) {
      if (isParkInRange && step == 10 && _random.nextDouble() < 0.45) {
        final r = _random.nextDouble();
        if (r < 0.33) {
          activeSound = '🍃 大安/陽明山盛夏蟬鳴';
          final vol = 0.50 * humanVelocity;
          await _audioEngine.triggerCicadas(volume: vol);
          logSoundFx(
            category: '🍃 自然生態',
            soundName: '陽明山/大安森林公園 盛夏蟬鳴',
            dspDetails: '帶通濾波: 4.2kHz ~ 7.8kHz | 殘響長度: 4.0s | 音量: ${(vol * 100).toInt()}%',
            volume: vol,
            stepInfo: 'Bar ${bar + 1}, Step $step',
          );
        } else if (r < 0.66) {
          activeSound = '🐸 象山/富陽原生樹蛙夜鳴';
          final vol = 0.52 * humanVelocity;
          await _audioEngine.triggerTreeFrogs(volume: vol);
          logSoundFx(
            category: '🍃 自然生態',
            soundName: '象山/富陽自然公園 台灣原生樹蛙',
            dspDetails: '共振峰: 1.8kHz | 空間立體聲調製 | 音量: ${(vol * 100).toInt()}%',
            volume: vol,
            stepInfo: 'Bar ${bar + 1}, Step $step',
          );
        } else {
          activeSound = '🚦 行人號誌布穀鳥 (E5→C5)';
          final vol = 0.55 * humanVelocity;
          await _audioEngine.triggerPedestrianBird(isTweet: false, volume: vol);
          logSoundFx(
            category: '🚦 空間號誌',
            soundName: '台北斑馬線行人號誌布穀鳥',
            dspDetails: '雙音頻率: E5(659Hz) → C5(523Hz) | 音量: ${(vol * 100).toInt()}%',
            volume: vol,
            stepInfo: 'Bar ${bar + 1}, Step $step',
          );
        }
      } else if (isWaterInRange && step == 8 && _random.nextDouble() < 0.45) {
        activeSound = '🌊 水岸流水微風';
        final vol = 0.45 * _currentComposition.textureWeight;
        await _audioEngine.playArpeggio(
          semitones: chord.take(3).toList(),
          volume: vol,
        );
        logSoundFx(
          category: '🌊 水岸紋理',
          soundName: '水岸琵音弦音',
          dspDetails: '琵音音符: ${chord.take(3).join(", ")} | 間隔: 0.06s | 音量: ${(vol * 100).toInt()}%',
          volume: vol,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      } else if (isTempleInRange && step == 4 && _random.nextDouble() < 0.40) {
        final useFish = _random.nextDouble() < 0.5;
        activeSound = useFish ? '🏮 傳統廟宇誦經木魚' : '🏮 龍山寺/行天宮青銅梵鐘';
        final vol = 0.55 * humanVelocity;
        await _audioEngine.triggerTempleBell(volume: vol, useWoodenFish: useFish);
        logSoundFx(
          category: '🏮 廟宇聲景',
          soundName: useFish ? '艋舺龍山寺 傳統誦經木魚' : '行天宮/龍山寺 沉穩青銅梵鐘',
          dspDetails: useFish ? '木質共振: 392Hz (G4) | 殘響: 2.4s' : '青銅金屬諧波: 293Hz (D4) | 殘響: 5.0s',
          volume: vol,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      } else if (isCampusInRange && step == 2 && _random.nextDouble() < 0.45) {
        activeSound = '🏫 台大傅鐘 21 響 [Ab4-C5-Bb4-Eb4]';
        final vol = 0.58 * humanVelocity;
        await _audioEngine.triggerCampusBell(volume: vol);
        logSoundFx(
          category: '🏫 校園聲景',
          soundName: '台大傅鐘 21 響悠揚鐘聲',
          dspDetails: '和聲西敏寺動機: Ab4-C5-Bb4-Eb4 | 殘響: 4.0s | 音量: ${(vol * 100).toInt()}%',
          volume: vol,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      } else if (isMarketInRange && step == 12 && _random.nextDouble() < 0.45) {
        final isPinball = _random.nextDouble() < 0.5;
        activeSound = isPinball ? '🍜 夜市傳統彈珠台鋼珠聲' : '🍜 士林/饒河夜市鐵板熱炒滋滋聲';
        final vol = 0.48 * humanVelocity;
        await _audioEngine.triggerNightMarket(volume: vol, isPinball: isPinball);
        logSoundFx(
          category: '🍜 夜市市井',
          soundName: isPinball ? '夜市傳統彈珠台鋼珠碰撞' : '士林/饒河夜市 大火鐵板熱炒滋滋聲',
          dspDetails: isPinball ? '鋼珠金屬微敲擊: 2.0s | 隨機抖動' : '白噪音濾波油煎音色: 4.0s | 空間立體混音',
          volume: vol,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      } else if (isCultureInRange && step == 0 && (_barIndex % 2 == 1) && _random.nextDouble() < 0.40) {
        activeSound = '🎨 松菸華山文創黑膠與咖啡蒸氣';
        final vol = 0.50 * humanVelocity;
        await _audioEngine.triggerCulturalWarmth(volume: vol);
        logSoundFx(
          category: '🎨 文創藝術',
          soundName: '松菸/華山 咖啡機蒸氣與黑膠底噪',
          dspDetails: '黑膠炒豆底噪 (Vinyl Crackle) + 濃縮蒸氣嘶嘶聲 | 延音: 4.0s',
          volume: vol,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      } else if (step == 12 && _random.nextDouble() < 0.25) {
        // Daily urban surprises
        final urbanRoll = _random.nextDouble();
        if (urbanRoll < 0.35 && (isPowerInRange || isYouBikeInRange)) {
          activeSound = '🚲 YouBike 雙音車鈴';
          final vol = 0.55 * humanVelocity;
          await _audioEngine.triggerYouBikeBell(volume: vol);
          logSoundFx(
            category: '🚲 都會日常',
            soundName: 'YouBike 雙音旋轉車鈴',
            dspDetails: '高音雙頻鐘聲: 1800Hz / 2200Hz | 音量: ${(vol * 100).toInt()}%',
            volume: vol,
            stepInfo: 'Bar ${bar + 1}, Step $step',
          );
        } else if (urbanRoll < 0.65) {
          activeSound = '🏪 台灣超商進門叮咚聲';
          final vol = 0.50 * humanVelocity;
          await _audioEngine.triggerConvenienceStore(volume: vol);
          logSoundFx(
            category: '🏪 都會日常',
            soundName: '台灣超商進門經典叮咚門鈴',
            dspDetails: '八音門鈴動機: 1318Hz → 1046Hz | 殘響: 2.4s',
            volume: vol,
            stepInfo: 'Bar ${bar + 1}, Step $step',
          );
        } else if (urbanRoll < 0.85) {
          activeSound = '🚌 台北公車刷卡全票提示音';
          final vol = 0.55 * humanVelocity;
          await _audioEngine.triggerBusCardSwipe(volume: vol);
          logSoundFx(
            category: '🚌 都會日常',
            soundName: '台北公車上下車刷卡雙音',
            dspDetails: '全票嗶聲: 880Hz / 1760Hz 諧波 | 時長: 1.0s',
            volume: vol,
            stepInfo: 'Bar ${bar + 1}, Step $step',
          );
        } else {
          activeSound = '🚛 遠處垃圾車「少女的祈禱」';
          final vol = 0.48 * humanVelocity;
          await _audioEngine.triggerGarbageTruck(volume: vol);
          logSoundFx(
            category: '🚛 都會日常',
            soundName: '台灣垃圾車「少女的祈禱」音樂鈴',
            dspDetails: '經典八音盒調音 (Music Box DSP) | 時長: 3.2s',
            volume: vol,
            stepInfo: 'Bar ${bar + 1}, Step $step',
          );
        }
      }
    }

    _lastSemitone = semitone;

    // 5. 4-Bar Dynamic Drum Groove System (if not muted)
    final bool isDrumRestBar = (_totalBarCount % 8 == 6 || _totalBarCount % 8 == 7);

    if (!isDrumsMuted && !isDrumRestBar) {
      final drumPattern = _evaluate4BarDrumPattern(bar, step, isWalking, humanVelocity);
      isKick = drumPattern.isKick;
      isSnare = drumPattern.isSnare;
      isHiHat = drumPattern.isHiHat;

      if (isKick) {
        await _audioEngine.triggerKick(volume: drumPattern.kickVol);
        logSoundFx(
          category: '🥁 爵士鼓組',
          soundName: 'Lo-Fi 溫暖大鼓 (Kick)',
          dspDetails: '音高快速滑降 120Hz → 45Hz | 音量: ${(drumPattern.kickVol * 100).toInt()}%',
          volume: drumPattern.kickVol,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      }
      if (isSnare) {
        await _audioEngine.triggerSnare(volume: drumPattern.snareVol, useFallback: drumPattern.isGhostSnare);
        logSoundFx(
          category: '🥁 爵士鼓組',
          soundName: drumPattern.isGhostSnare ? 'Ghost Snare 幽靈輕點小鼓' : 'Lo-Fi 刷音小鼓 (Snare)',
          dspDetails: drumPattern.isGhostSnare ? '低力度次拍裝飾點綴' : '白噪音濾波 2400Hz + 音調基底 180Hz',
          volume: drumPattern.snareVol,
          stepInfo: 'Bar ${bar + 1}, Step $step',
        );
      }
      if (isHiHat) {
        final hatVol = drumPattern.hatVol * _currentComposition.sparkWeight;
        await _audioEngine.triggerHiHat(volume: hatVol);
      }
    }

    _state = _state.copyWith(
      stepIndex: step,
      barIndex: bar,
      currentChordName: chordName,
      activeSoundSource: activeSound,
      currentSemitone: semitone,
      isRhythmActive: isWalking,
      isKickActive: isKick,
      isSnareActive: isSnare,
      isHiHatActive: isHiHat,
      isPadActive: isPad,
    );
    notifyListeners();

    _currentStep = (_currentStep + 1) % 16;
    if (_currentStep == 0) {
      _barIndex = (_barIndex + 1) % 4;
      _totalBarCount++;
    }
  }

  /// 4-Bar Dynamic Drum Pattern Evaluator
  _DrumHit _evaluate4BarDrumPattern(int bar, int step, bool isWalking, double humanVelocity) {
    bool isKick = false;
    bool isSnare = false;
    bool isHiHat = false;
    bool isGhostSnare = false;
    double kickVol = 0.0;
    double snareVol = 0.0;
    double hatVol = 0.0;

    final baseMultiplier = isWalking ? 1.0 : 0.75;

    switch (bar) {
      // Bar 0: Laidback Foundation
      case 0:
        if (step == 0) {
          isKick = true;
          kickVol = 0.65 * humanVelocity * baseMultiplier;
        } else if (step == 10 && _random.nextDouble() < 0.6) {
          isKick = true;
          kickVol = 0.40 * humanVelocity * baseMultiplier;
        }
        if (step == 4 || step == 12) {
          isSnare = true;
          snareVol = 0.60 * humanVelocity * baseMultiplier;
        }
        if (step % 2 == 0) {
          isHiHat = true;
          hatVol = 0.30 * humanVelocity * baseMultiplier;
        }
        break;

      // Bar 1: Syncopated with Ghost Snare
      case 1:
        if (step == 0 || step == 8) {
          isKick = true;
          kickVol = (step == 0 ? 0.65 : 0.50) * humanVelocity * baseMultiplier;
        }
        if (step == 4 || step == 12) {
          isSnare = true;
          snareVol = 0.62 * humanVelocity * baseMultiplier;
        } else if (step == 14 && _random.nextDouble() < 0.55) {
          isSnare = true;
          isGhostSnare = true;
          snareVol = 0.28 * humanVelocity * baseMultiplier;
        }
        if (step % 2 == 0 && step != 14) {
          isHiHat = true;
          hatVol = 0.28 * humanVelocity * baseMultiplier;
        }
        break;

      // Bar 2: Double Kick Drive
      case 2:
        if (step == 0 || step == 3 || step == 10) {
          isKick = true;
          kickVol = (step == 3 ? 0.45 : 0.65) * humanVelocity * baseMultiplier;
        }
        if (step == 4 || step == 12) {
          isSnare = true;
          snareVol = 0.65 * humanVelocity * baseMultiplier;
        }
        if (step % 2 == 0) {
          isHiHat = true;
          hatVol = 0.35 * humanVelocity * baseMultiplier;
        }
        break;

      // Bar 3: Turnaround Break & Drop (Mute steps 8-15)
      case 3:
        if (step == 0) {
          isKick = true;
          kickVol = 0.70 * humanVelocity * baseMultiplier;
        }
        if (step == 4) {
          isSnare = true;
          snareVol = 0.60 * humanVelocity * baseMultiplier;
        }
        if (step == 0 || step == 2 || step == 4 || step == 6) {
          isHiHat = true;
          hatVol = 0.25 * humanVelocity * baseMultiplier;
        }
        break;
    }

    return _DrumHit(
      isKick: isKick,
      isSnare: isSnare,
      isHiHat: isHiHat,
      isGhostSnare: isGhostSnare,
      kickVol: kickVol,
      snareVol: snareVol,
      hatVol: hatVol,
    );
  }

  String _noteName(int semitone) {
    const names = ['D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#'];
    final normalized = (semitone % 12 + 12) % 12;
    final octave = 4 + (semitone ~/ 12);
    return '${names[normalized]}$octave';
  }

  /// Handles Location Update and triggers Gemini AI Re-Composition if displacement exceeds 150m.
  Future<void> _handleLocationUpdate(double lon, double lat, {bool forceRecompose = false}) async {
    _nearbyFeatures = _gisService.evaluateNearbyFeatures(longitude: lon, latitude: lat);

    double subBassVol = 0.0;
    double vinylVol = 0.0;
    double sparkVol = 0.0;

    isMrtInRange = false;
    isWaterInRange = false;
    isPowerInRange = false;
    isParkInRange = false;
    isYouBikeInRange = false;
    isTempleInRange = false;
    isMarketInRange = false;
    isCampusInRange = false;
    isCultureInRange = false;

    for (final feature in _nearbyFeatures) {
      switch (feature.type) {
        case FeatureType.mrt:
          final score = feature.proximityScore(GisConstants.mrtSubBassRadius);
          subBassVol = math.max(subBassVol, score);
          if (feature.distanceMeters <= GisConstants.mrtSubBassRadius) {
            isMrtInRange = true;
            isYouBikeInRange = true;
          }
          break;
        case FeatureType.water:
          final score = feature.proximityScore(GisConstants.waterTextureRadius);
          vinylVol = math.max(vinylVol, score);
          if (feature.distanceMeters <= GisConstants.waterTextureRadius) {
            isWaterInRange = true;
          }
          break;
        case FeatureType.power:
          final score = feature.proximityScore(GisConstants.powerGridRadius);
          sparkVol = math.max(sparkVol, score);
          if (feature.distanceMeters <= GisConstants.powerGridRadius) {
            isPowerInRange = true;
            isYouBikeInRange = true;
          }
          break;
        case FeatureType.park:
          if (feature.distanceMeters <= GisConstants.parkAcousticRadius) {
            isParkInRange = true;
            isYouBikeInRange = true;
          }
          break;
        case FeatureType.temple:
          if (feature.distanceMeters <= GisConstants.templeAcousticRadius) {
            isTempleInRange = true;
          }
          break;
        case FeatureType.market:
          if (feature.distanceMeters <= GisConstants.marketAcousticRadius) {
            isMarketInRange = true;
            isYouBikeInRange = true;
          }
          break;
        case FeatureType.campus:
          if (feature.distanceMeters <= GisConstants.campusAcousticRadius) {
            isCampusInRange = true;
            isYouBikeInRange = true;
          }
          break;
        case FeatureType.culture:
          if (feature.distanceMeters <= GisConstants.cultureAcousticRadius) {
            isCultureInRange = true;
            isYouBikeInRange = true;
          }
          break;
      }
    }

    _state = _state.copyWith(
      subBassVolume: subBassVol * _currentComposition.bassWeight,
      vinylVolume: vinylVol * _currentComposition.textureWeight,
      sparkVolume: sparkVol * _currentComposition.sparkWeight,
    );

    if (_state.isPlaying) {
      _audioEngine.setSubBassVolume(_state.subBassVolume);
      _audioEngine.setVinylVolume(_state.vinylVolume);
    }

    notifyListeners();

    // Check displacement from last AI composition anchor
    bool shouldRecompose = forceRecompose;
    if (_lastComposedLocation == null) {
      shouldRecompose = true;
    } else {
      final dist = _gisService.calculateDistanceMeters(
        lon1: _lastComposedLocation!.$1,
        lat1: _lastComposedLocation!.$2,
        lon2: lon,
        lat2: lat,
      );
      if (dist >= locationRegenerationThresholdMeters) {
        shouldRecompose = true;
      }
    }

    if (shouldRecompose) {
      await composeNewLocationAiTheme(lon, lat);
    }
  }

  /// Explicit manual coordinate or landmark teleport triggering instant AI re-composition.
  Future<void> onManualLocationChange(double lon, double lat) async {
    _isComposingAi = false;
    await _handleLocationUpdate(lon, lat, forceRecompose: true);
  }

  /// 🌟 Triggers Google Gemini AI to compose a brand new custom spatial motif for this location.
  Future<void> composeNewLocationAiTheme(double lon, double lat) async {
    _isComposingAi = true;
    _lastComposedLocation = (lon, lat);
    notifyListeners();

    try {
      final newComp = await _geminiService.composeSpatialMotif(
        longitude: lon,
        latitude: lat,
        nearbyFeatures: _nearbyFeatures,
        bpm: _state.bpm,
        isWalking: _sensorService.isWalking,
      );
      _currentComposition = newComp;
      _currentMood = AmbientMood(
        moodTitle: newComp.title,
        poeticNarrative: newComp.poeticStory,
        recommendedScale: newComp.scaleName,
        melodyWeight: newComp.melodyWeight,
        bassWeight: newComp.bassWeight,
        textureWeight: newComp.textureWeight,
        sparkWeight: newComp.sparkWeight,
      );
    } catch (_) {}

    _isComposingAi = false;
    notifyListeners();
  }

  void _handleMotionUpdate(double intensity) {
    final newBpm = _sensorService.currentBpm;
    if ((newBpm - _state.bpm).abs() > 0.5 || _state.isRhythmActive != _sensorService.isWalking) {
      _state = _state.copyWith(
        bpm: newBpm,
        isRhythmActive: _sensorService.isWalking,
      );
      _foregroundService.updateNotification(
        text: 'Tempo: ${newBpm.toStringAsFixed(0)} BPM | ${_sensorService.isWalking ? "Walking" : "Stationary"}',
      );
      notifyListeners();
    }
  }

  /// 💬 Directly interacts with Gemini AI Composer via chat and optionally hot-swaps playback composition.
  Future<AiChatResponse> chatWithAiComposer(String userPrompt) async {
    final loc = _locationService.currentLocation;
    final res = await _geminiService.chatWithComposer(
      userPrompt: userPrompt,
      longitude: loc.$1,
      latitude: loc.$2,
      nearbyFeatures: _nearbyFeatures,
      bpm: _state.bpm,
      isWalking: _sensorService.isWalking,
      currentComposition: _currentComposition,
    );
    if (res.newComposition != null) {
      applyCustomAiComposition(res.newComposition!);
    }
    return res;
  }

  /// 🌟 Applies a custom composition generated directly from the AI Composer Chat or UI.
  void applyCustomAiComposition(AiComposition composition) {
    _currentComposition = composition;
    _currentMood = AmbientMood(
      moodTitle: composition.title,
      poeticNarrative: composition.poeticStory,
      recommendedScale: composition.scaleName,
      melodyWeight: composition.melodyWeight,
      bassWeight: composition.bassWeight,
      textureWeight: composition.textureWeight,
      sparkWeight: composition.sparkWeight,
    );
    _state = _state.copyWith(
      currentChordName: composition.chordNames[0],
      activeSoundSource: composition.title,
    );
    notifyListeners();
  }

  /// Forces an instant AI re-composition with new prompt analysis.
  Future<void> refreshAiMood() async {
    final loc = _locationService.currentLocation;
    await composeNewLocationAiTheme(loc.$1, loc.$2);
  }

  // --- Manual Sound FX Testing Triggers (for Simulator Inspector) ---

  Future<void> testTriggerRealMrt(RealMrtItem item) async {
    final rootSemitone = _currentComposition.rootSemitones[0];
    double playbackRate = 1.0;
    int semitoneDelta = 0;
    if (!item.isVoice) {
      semitoneDelta = (rootSemitone - item.baseSemitone) % 12;
      final normalizedDelta = semitoneDelta > 6 ? (semitoneDelta - 12) : semitoneDelta;
      playbackRate = math.pow(2.0, normalizedDelta / 12.0).toDouble();
    }
    await _audioEngine.triggerRealMrtSample(
      item.assetPath,
      volume: 0.75,
      playbackRate: playbackRate,
      lowpassFreq: 2600.0,
      offsetSeconds: item.sliceOffset,
      durationSeconds: item.sliceDuration,
    );
    logSoundFx(
      category: '🚇 實錄變奏 (手動測試)',
      soundName: item.title,
      dspDetails: '手動測試調音: ${playbackRate.toStringAsFixed(3)}x (${semitoneDelta >= 0 ? "+$semitoneDelta" : semitoneDelta}st) | 濾波: 低通2600Hz | 切片: ${item.sliceDuration}s',
      volume: 0.75,
      playbackRate: playbackRate,
      stepInfo: '手動觸發',
    );
  }

  Future<void> testTriggerConvenienceStore() async {
    await _audioEngine.triggerConvenienceStore(volume: 0.75);
    logSoundFx(
      category: '🏪 都會日常 (手動測試)',
      soundName: '台灣超商進門經典叮咚門鈴',
      dspDetails: '八音門鈴動機: 1318Hz → 1046Hz | 殘響: 2.4s | 音量: 75%',
      volume: 0.75,
      stepInfo: '手動觸發',
    );
  }

  Future<void> testTriggerGarbageTruck() async {
    await _audioEngine.triggerGarbageTruck(volume: 0.75);
    logSoundFx(
      category: '🚛 都會日常 (手動測試)',
      soundName: '台灣垃圾車「少女的祈禱」音樂鈴',
      dspDetails: '八音盒調音 (Music Box DSP) | 時長: 3.2s | 音量: 75%',
      volume: 0.75,
      stepInfo: '手動觸發',
    );
  }

  Future<void> testTriggerTemple(bool useWoodenFish) async {
    await _audioEngine.triggerTempleBell(volume: 0.80, useWoodenFish: useWoodenFish);
    logSoundFx(
      category: '🏮 廟宇聲景 (手動測試)',
      soundName: useWoodenFish ? '艋舺龍山寺 傳統誦經木魚' : '行天宮/龍山寺 沉穩青銅梵鐘',
      dspDetails: useWoodenFish ? '木質共振: 392Hz (G4) | 殘響: 2.4s' : '青銅金屬諧波: 293Hz (D4) | 殘響: 5.0s',
      volume: 0.80,
      stepInfo: '手動觸發',
    );
  }

  Future<void> testTriggerNightMarket(bool isPinball) async {
    await _audioEngine.triggerNightMarket(volume: 0.75, isPinball: isPinball);
    logSoundFx(
      category: '🍜 夜市市井 (手動測試)',
      soundName: isPinball ? '夜市傳統彈珠台鋼珠碰撞' : '士林/饒河夜市 大火鐵板熱炒滋滋聲',
      dspDetails: isPinball ? '鋼珠金屬微敲擊: 2.0s' : '白噪音濾波油煎音色: 4.0s',
      volume: 0.75,
      stepInfo: '手動觸發',
    );
  }

  Future<void> testTriggerCampusBell() async {
    await _audioEngine.triggerCampusBell(volume: 0.80);
    logSoundFx(
      category: '🏫 校園聲景 (手動測試)',
      soundName: '台大傅鐘 21 響悠揚鐘聲',
      dspDetails: '和聲西敏寺動機: Ab4-C5-Bb4-Eb4 | 殘響: 4.0s',
      volume: 0.80,
      stepInfo: '手動觸發',
    );
  }

  Future<void> testTriggerCulture() async {
    await _audioEngine.triggerCulturalWarmth(volume: 0.75);
    logSoundFx(
      category: '🎨 文創藝術 (手動測試)',
      soundName: '松菸/華山 咖啡機蒸氣與黑膠底噪',
      dspDetails: '黑膠炒豆底噪 (Vinyl Crackle) + 濃縮蒸氣嘶嘶聲 | 延音: 4.0s',
      volume: 0.75,
      stepInfo: '手動觸發',
    );
  }

  Future<void> testTriggerNature(bool isCicada) async {
    if (isCicada) {
      await _audioEngine.triggerCicadas(volume: 0.75);
      logSoundFx(
        category: '🍃 自然生態 (手動測試)',
        soundName: '陽明山/大安森林公園 盛夏蟬鳴',
        dspDetails: '帶通濾波: 4.2kHz ~ 7.8kHz | 殘響長度: 4.0s',
        volume: 0.75,
        stepInfo: '手動觸發',
      );
    } else {
      await _audioEngine.triggerTreeFrogs(volume: 0.75);
      logSoundFx(
        category: '🍃 自然生態 (手動測試)',
        soundName: '象山/富陽自然公園 台灣原生樹蛙',
        dspDetails: '共振峰: 1.8kHz | 空間立體聲調製',
        volume: 0.75,
        stepInfo: '手動觸發',
      );
    }
  }

  Future<void> testTriggerBusSwipe() async {
    await _audioEngine.triggerBusCardSwipe(volume: 0.80);
    logSoundFx(
      category: '🚌 都會日常 (手動測試)',
      soundName: '台北公車上下車刷卡雙音',
      dspDetails: '全票嗶聲: 880Hz / 1760Hz 諧波 | 時長: 1.0s',
      volume: 0.80,
      stepInfo: '手動觸發',
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _locationSub?.cancel();
    _sensorSub?.cancel();
    _locationService.dispose();
    _sensorService.dispose();
    _audioEngine.dispose();
    super.dispose();
  }
}

class _DrumHit {
  final bool isKick;
  final bool isSnare;
  final bool isHiHat;
  final bool isGhostSnare;
  final double kickVol;
  final double snareVol;
  final double hatVol;

  const _DrumHit({
    required this.isKick,
    required this.isSnare,
    required this.isHiHat,
    required this.isGhostSnare,
    required this.kickVol,
    required this.snareVol,
    required this.hatVol,
  });
}
