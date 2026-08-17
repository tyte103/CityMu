import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../core/constants/audio_constants.dart';
import 'audio_engine_platform.dart' as platform_audio;

/// Cross-Platform Audio Engine Service.
/// - Native (iOS / Android / macOS): Uses C++ flutter_soloud DSP engine.
/// - Web (Chrome): Uses Web Audio API synthesizer with polyphonic pads, portamento glides, and iconic Taiwan foley.
class AudioEngineService {
  AudioEngineService._internal();
  static final AudioEngineService instance = AudioEngineService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // SoLoud Native Sound Sources
  AudioSource? _mrtBeepSource;
  AudioSource? _feltPianoSource;
  AudioSource? _airBrakeSource;
  AudioSource? _lofiSnareSource;
  AudioSource? _powerSparkSource;
  AudioSource? _hiHatSource;
  AudioSource? _subwayRumbleSource;
  AudioSource? _waterTrickleSource;

  // Native Loop handles
  SoundHandle? _subBassHandle;
  SoundHandle? _vinylHandle;

  /// Initializes audio engine and preloads assets.
  Future<bool> init() async {
    if (_isInitialized) return true;

    if (kIsWeb) {
      _isInitialized = true;
      developer.log('AudioEngineService initialized in Web mode.', name: 'AudioEngine');
      return true;
    }

    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) {
        await soloud.init();
      }

      // Preload primary foley sound sources
      _mrtBeepSource = await soloud.loadAsset(AudioConstants.foleyMrtBeep);
      _airBrakeSource = await soloud.loadAsset(AudioConstants.foleyAirBrake);
      _powerSparkSource = await soloud.loadAsset(AudioConstants.foleyPowerSpark);
      _subwayRumbleSource = await soloud.loadAsset(AudioConstants.foleySubwayRumble);
      _waterTrickleSource = await soloud.loadAsset(AudioConstants.foleyWaterTrickle);

      // Preload fallback instruments
      _feltPianoSource = await soloud.loadAsset(AudioConstants.fallbackFeltPiano);
      _lofiSnareSource = await soloud.loadAsset(AudioConstants.fallbackSnare);
      _hiHatSource = await soloud.loadAsset(AudioConstants.fallbackHiHat);

      _isInitialized = true;
      developer.log('AudioEngineService initialized in Native SoLoud mode.', name: 'AudioEngine');
      return true;
    } catch (e, stack) {
      developer.log('Failed to initialize AudioEngineService: $e', name: 'AudioEngine', error: e, stackTrace: stack);
      _isInitialized = false;
      return false;
    }
  }

  /// Plays a lush Lo-Fi jazz chord pad with long sustain and tape chorus.
  Future<void> playPad({
    required List<int> semitones,
    double volume = 0.6,
    double durationSeconds = 3.0,
  }) async {
    if (kIsWeb) {
      platform_audio.playHtml5Pad(semitones, volume: volume, durationSeconds: durationSeconds);
      return;
    }

    if (!_isInitialized) return;
    for (final st in semitones) {
      playMelodyNote(semitones: st, volume: volume * 0.35);
    }
  }

  /// Plays a melody note with Portamento Pitch Glide (轉音 / 滑音).
  Future<void> playGlideNote({
    required int startSemitone,
    required int targetSemitone,
    double volume = 0.7,
    double glideDuration = 0.15,
  }) async {
    if (kIsWeb) {
      platform_audio.playHtml5GlideNote(
        startSemitone: startSemitone,
        targetSemitone: targetSemitone,
        volume: volume,
        glideDuration: glideDuration,
      );
      return;
    }

    // Native fallback: play target note
    playMelodyNote(semitones: targetSemitone, volume: volume);
  }

  /// Plays a rolling grace-note arpeggio (琶音滾奏).
  Future<void> playArpeggio({
    required List<int> semitones,
    double volume = 0.6,
    double interval = 0.06,
  }) async {
    if (kIsWeb) {
      platform_audio.playHtml5Arpeggio(semitones, volume: volume, interval: interval);
      return;
    }

    for (int i = 0; i < semitones.length; i++) {
      Future.delayed(Duration(milliseconds: (i * interval * 1000).round()), () {
        playMelodyNote(semitones: semitones[i], volume: volume * 0.4);
      });
    }
  }

  /// 🚇 Triggers Taipei Metro Jingle Arpeggio.
  Future<void> triggerMrtJingle({double volume = 0.7}) async {
    if (kIsWeb) {
      platform_audio.playHtml5MrtJingle(volume: volume);
      return;
    }
    playArpeggio(semitones: [0, 5, 7, 9, 12], volume: volume, interval: 0.12);
  }

  /// 🚇 Triggers authentic Taipei Metro 3-tone card tap.
  Future<void> triggerMrtCardTap({double volume = 0.65}) async {
    if (kIsWeb) {
      platform_audio.playHtml5MrtCardTap(volume: volume);
      return;
    }
    playArpeggio(semitones: [4, 7, 12], volume: volume, interval: 0.08);
  }

  /// 🚇 Triggers a specific Real Taipei MRT Field Recording Sample with tuning, slice offset, duration, and lowpass.
  Future<void> triggerRealMrtSample(
    String assetPath, {
    double volume = 0.35,
    double playbackRate = 1.0,
    double lowpassFreq = 2800.0,
    double offsetSeconds = 0.0,
    double? durationSeconds,
  }) async {
    if (kIsWeb) {
      platform_audio.playHtml5RealMrtSample(
        assetPath,
        volume: volume,
        playbackRate: playbackRate,
        lowpassFreq: lowpassFreq,
        offsetSeconds: offsetSeconds,
        durationSeconds: durationSeconds,
      );
      return;
    }
    playMelodyNote(semitones: 0, volume: volume);
  }

  /// 🚦 Triggers Pedestrian Traffic Bird Chirp (Cuckoo or Tweet).
  Future<void> triggerPedestrianBird({bool isTweet = false, double volume = 0.5}) async {
    if (kIsWeb) {
      platform_audio.playHtml5PedestrianBird(isTweet: isTweet, volume: volume);
      return;
    }
    playMelodyNote(semitones: isTweet ? 9 : 4, volume: volume);
  }

  /// 🚲 Triggers YouBike double bell ring.
  Future<void> triggerYouBikeBell({double volume = 0.55}) async {
    if (kIsWeb) {
      platform_audio.playHtml5YouBikeBell(volume: volume);
      return;
    }
    playMelodyNote(semitones: 12, volume: volume);
  }

  /// 🏮 Triggers Resonant Temple Bell / Singing Bowl chime or Wooden Fish.
  Future<void> triggerTempleBell({double volume = 0.5, bool useWoodenFish = false}) async {
    if (kIsWeb) {
      platform_audio.playHtml5TempleBell(volume: volume, useWoodenFish: useWoodenFish);
      return;
    }
    playMelodyNote(semitones: useWoodenFish ? 7 : -12, volume: volume);
  }

  /// 🍜 Triggers Lively Night Market sizzle or pinball sounds.
  Future<void> triggerNightMarket({double volume = 0.4, bool isPinball = false}) async {
    if (kIsWeb) {
      platform_audio.playHtml5NightMarket(volume: volume, isPinball: isPinball);
      return;
    }
    playMelodyNote(semitones: isPinball ? 12 : 7, volume: volume * 0.5);
  }

  /// 🏫 Triggers NTU Fu Bell / Campus Westminster chime.
  Future<void> triggerCampusBell({double volume = 0.55}) async {
    if (kIsWeb) {
      platform_audio.playHtml5CampusBell(volume: volume);
      return;
    }
    playArpeggio(semitones: [7, 4, 0, -5], volume: volume, interval: 0.28);
  }

  /// 🎨 Triggers Cultural & Arts vinyl coffee & acoustic swell.
  Future<void> triggerCulturalWarmth({double volume = 0.45}) async {
    if (kIsWeb) {
      platform_audio.playHtml5CulturalWarmth(volume: volume);
      return;
    }
    playMelodyNote(semitones: -5, volume: volume);
  }

  /// 🏪 Triggers Taiwan Convenience Store Entrance Chime (超商進門叮咚聲).
  Future<void> triggerConvenienceStore({double volume = 0.6}) async {
    if (kIsWeb) {
      platform_audio.playHtml5ConvenienceStore(volume: volume);
      return;
    }
    playArpeggio(semitones: [4, 0, -5, 0, 2, 7, 2, 7], volume: volume, interval: 0.18);
  }

  /// 🚛 Triggers Taiwan Garbage Truck Maiden's Prayer Melody (垃圾車少女的祈禱).
  Future<void> triggerGarbageTruck({double volume = 0.55}) async {
    if (kIsWeb) {
      platform_audio.playHtml5GarbageTruck(volume: volume);
      return;
    }
    playMelodyNote(semitones: 1, volume: volume);
  }

  /// 🚌 Triggers Taipei Bus Card Reader Chime (公車刷卡提示音).
  Future<void> triggerBusCardSwipe({double volume = 0.65}) async {
    if (kIsWeb) {
      platform_audio.playHtml5BusCardSwipe(volume: volume);
      return;
    }
    playArpeggio(semitones: [10, 14], volume: volume, interval: 0.15);
  }

  /// 🍃 Triggers Taipei Summer Cicadas (大安森林/陽明山盛夏蟬鳴).
  Future<void> triggerCicadas({double volume = 0.45}) async {
    if (kIsWeb) {
      platform_audio.playHtml5Cicadas(volume: volume);
      return;
    }
    playMelodyNote(semitones: 19, volume: volume * 0.3);
  }

  /// 🐸 Triggers Taiwan Native Tree Frogs (象山/富陽自然公園樹蛙鳴叫).
  Future<void> triggerTreeFrogs({double volume = 0.5}) async {
    if (kIsWeb) {
      platform_audio.playHtml5TreeFrogs(volume: volume);
      return;
    }
    playMelodyNote(semitones: 10, volume: volume * 0.4);
  }

  /// Plays a melody note based on semitone offset relative to D4 using warm acoustic felt piano.
  Future<bool> playMelodyNote({
    required int semitones,
    double volume = 0.8,
  }) async {
    final speed = AudioConstants.semitonesToSpeed(semitones);
    final assetPath = AudioConstants.fallbackFeltPiano;

    if (kIsWeb) {
      platform_audio.playHtml5Audio(assetPath, speed: speed, volume: volume);
      return true;
    }

    if (!_isInitialized) return false;
    try {
      final soloud = SoLoud.instance;
      final source = _feltPianoSource ?? _mrtBeepSource;
      if (source == null) return false;

      final handle = await soloud.play(source, volume: volume.clamp(0.0, 1.0));
      soloud.setRelativePlaySpeed(handle, speed);
      return true;
    } catch (e) {
      developer.log('Error playing melody note: $e', name: 'AudioEngine');
      return false;
    }
  }

  /// Plays a punchy acoustic/synth Lo-Fi Bass note.
  Future<void> playBassNote({
    required int semitones,
    double volume = 0.7,
    double durationSeconds = 0.8,
  }) async {
    if (kIsWeb) {
      platform_audio.playHtml5BassNote(
        semitones: semitones,
        volume: volume,
        durationSeconds: durationSeconds,
      );
      return;
    }
    // Native fallback: play low pitched piano note
    playMelodyNote(semitones: semitones - 12, volume: volume);
  }

  /// Triggers a punchy Lo-Fi kick hit.
  Future<void> triggerKick({
    double volume = 0.7,
  }) async {
    if (kIsWeb) {
      platform_audio.playHtml5Kick(volume: volume);
      return;
    }

    if (!_isInitialized) return;
    try {
      if (_feltPianoSource != null) {
        final handle = await SoLoud.instance.play(_feltPianoSource!, volume: volume.clamp(0.0, 1.0));
        SoLoud.instance.setRelativePlaySpeed(handle, 0.5);
      }
    } catch (e) {
      developer.log('Error triggering kick: $e', name: 'AudioEngine');
    }
  }

  /// Triggers a snare / air brake hit.
  Future<void> triggerSnare({
    double volume = 0.7,
    bool useFallback = false,
  }) async {
    if (kIsWeb) {
      platform_audio.playHtml5Snare(volume: volume);
      return;
    }

    if (!_isInitialized) return;
    try {
      final source = useFallback ? _lofiSnareSource : _airBrakeSource;
      if (source != null) {
        await SoLoud.instance.play(source, volume: volume.clamp(0.0, 1.0));
      }
    } catch (e) {
      developer.log('Error triggering snare: $e', name: 'AudioEngine');
    }
  }

  /// Triggers a hi-hat / power spark hit.
  Future<void> triggerHiHat({
    double volume = 0.5,
    bool useFallback = false,
  }) async {
    if (kIsWeb) {
      platform_audio.playHtml5HiHat(volume: volume);
      return;
    }

    if (!_isInitialized) return;
    try {
      final source = useFallback ? _hiHatSource : _powerSparkSource;
      if (source != null) {
        await SoLoud.instance.play(source, volume: volume.clamp(0.0, 1.0));
      }
    } catch (e) {
      developer.log('Error triggering hi-hat: $e', name: 'AudioEngine');
    }
  }

  /// Starts or adjusts the Sub-Bass ambient drone loop (Metro rumble).
  Future<void> setSubBassVolume(double volume) async {
    final clampedVol = volume.clamp(0.0, 1.0);

    if (kIsWeb) {
      platform_audio.setHtml5LoopAudio('sub_bass', AudioConstants.foleySubwayRumble, clampedVol);
      return;
    }

    if (!_isInitialized || _subwayRumbleSource == null) return;
    try {
      final soloud = SoLoud.instance;
      if (_subBassHandle == null || !soloud.getIsValidVoiceHandle(_subBassHandle!)) {
        if (clampedVol > 0.01) {
          _subBassHandle = await soloud.play(
            _subwayRumbleSource!,
            volume: clampedVol,
            looping: true,
          );
        }
      } else {
        soloud.setVolume(_subBassHandle!, clampedVol <= 0.01 ? 0.0 : clampedVol);
      }
    } catch (e) {
      developer.log('Error adjusting sub-bass volume: $e', name: 'AudioEngine');
    }
  }

  /// Starts or adjusts the Vinyl ambient trickle loop (Water conduit).
  Future<void> setVinylVolume(double volume) async {
    final clampedVol = volume.clamp(0.0, 1.0);

    if (kIsWeb) {
      platform_audio.setHtml5LoopAudio('vinyl', AudioConstants.foleyWaterTrickle, clampedVol);
      return;
    }

    if (!_isInitialized || _waterTrickleSource == null) return;
    try {
      final soloud = SoLoud.instance;
      if (_vinylHandle == null || !soloud.getIsValidVoiceHandle(_vinylHandle!)) {
        if (clampedVol > 0.01) {
          _vinylHandle = await soloud.play(
            _waterTrickleSource!,
            volume: clampedVol,
            looping: true,
          );
        }
      } else {
        soloud.setVolume(_vinylHandle!, clampedVol <= 0.01 ? 0.0 : clampedVol);
      }
    } catch (e) {
      developer.log('Error adjusting vinyl volume: $e', name: 'AudioEngine');
    }
  }

  /// Stops all playing sounds and active loops.
  Future<void> stopAll() async {
    if (kIsWeb) {
      platform_audio.stopHtml5Audio();
      return;
    }

    if (!_isInitialized) return;
    try {
      if (_subBassHandle != null) {
        SoLoud.instance.stop(_subBassHandle!);
        _subBassHandle = null;
      }
      if (_vinylHandle != null) {
        SoLoud.instance.stop(_vinylHandle!);
        _vinylHandle = null;
      }
    } catch (e) {
      developer.log('Error stopping audio: $e', name: 'AudioEngine');
    }
  }

  /// Disposes audio sources and shuts down the engine.
  Future<void> dispose() async {
    await stopAll();
    if (!kIsWeb && _isInitialized) {
      _mrtBeepSource = null;
      _airBrakeSource = null;
      _powerSparkSource = null;
      _subwayRumbleSource = null;
      _waterTrickleSource = null;
      _feltPianoSource = null;
      _lofiSnareSource = null;
      _hiHatSource = null;
      SoLoud.instance.deinit();
    }
    _isInitialized = false;
  }
}
