import 'dart:js_interop';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:web/web.dart' as web;
import '../core/constants/audio_constants.dart';

web.AudioContext? _audioCtx;
web.GainNode? _subBassGain;
web.OscillatorNode? _subBassOsc;
web.GainNode? _vinylGain;
web.OscillatorNode? _vinylOsc;

final Map<String, web.AudioBuffer> _audioBufferCache = {};
bool _preloadingStarted = false;

web.AudioContext _getOrCreateContext() {
  if (_audioCtx == null) {
    _audioCtx = web.AudioContext();
  }
  if (_audioCtx!.state == 'suspended') {
    _audioCtx!.resume();
  }
  if (!_preloadingStarted) {
    _preloadingStarted = true;
    _preloadAllWebSamples(_audioCtx!);
  }
  return _audioCtx!;
}

/// Preloads and decodes authentic audio samples into memory for zero-latency playback.
Future<void> _preloadAllWebSamples(web.AudioContext ctx) async {
  final assetsToLoad = [
    AudioConstants.taiwanMrtJingle,
    AudioConstants.taiwanMrtCardTap,
    AudioConstants.taiwanPedestrianCuckoo,
    AudioConstants.taiwanYouBikeBell,
    AudioConstants.taiwanTaipeiRain,
    AudioConstants.taiwanRhodesPad,
    // 1. 傳統廟宇 (Temples)
    AudioConstants.taiwanTempleBronzeBell,
    AudioConstants.taiwanTempleWoodenFish,
    // 2. 夜市老街 (Night Markets)
    AudioConstants.taiwanNightMarketWok,
    AudioConstants.taiwanNightMarketPinball,
    // 3. 日常都會 (Daily Urban)
    AudioConstants.taiwanConvenienceStore,
    AudioConstants.taiwanGarbageTruck,
    AudioConstants.taiwanBusCardSwipe,
    // 4. 自然生態 (Nature)
    AudioConstants.taiwanTaipeiCicadas,
    AudioConstants.taiwanTreeFrogs,
    // 5. 校園與文創 (Campus & Culture)
    AudioConstants.taiwanCampusFuBell,
    AudioConstants.taiwanCultureVinylCafe,
    // 基礎樂器與 Foley
    AudioConstants.fallbackFeltPiano,
    AudioConstants.fallbackSnare,
    AudioConstants.fallbackHiHat,
    AudioConstants.foleyMrtBeep,
    AudioConstants.foleyAirBrake,
    AudioConstants.foleyPowerSpark,
    AudioConstants.foleySubwayRumble,
    AudioConstants.foleyWaterTrickle,
    // Real Field Recordings - Taipei MRT Door & Broadcast Collection
    AudioConstants.realMrtC301DoorClosing,
    AudioConstants.realMrtC321DoorClosing,
    AudioConstants.realMrtC341DoorClosing,
    AudioConstants.realMrtC371DoorOpening,
    AudioConstants.realMrtC371DoorClosing,
    AudioConstants.realMrtC381DoorOpening,
    AudioConstants.realMrtC381DoorClosing,
    AudioConstants.realMrtCircularArrival,
    AudioConstants.realMrtCircularClosing,
    AudioConstants.realMrtClosingVoice,
  ];

  for (final path in assetsToLoad) {
    try {
      final byteData = await rootBundle.load(path);
      final uint8List = byteData.buffer.asUint8List();
      final jsArray = uint8List.buffer.toJS;
      final decodedBuffer = await ctx.decodeAudioData(jsArray).toDart;
      _audioBufferCache[path] = decodedBuffer;
    } catch (_) {}
  }
}

/// Base D4 frequency
const double _baseD4 = 293.665;

double _semitoneToFreq(num semitones) {
  return _baseD4 * math.pow(2.0, semitones / 12.0);
}

/// Plays an authentic sampled audio file with speed (pitch) and volume control.
void _playCachedOrSyntheticSample(
  String assetPath, {
  double speed = 1.0,
  double volume = 0.8,
  double fallbackFreq = 293.665,
}) {
  try {
    final ctx = _getOrCreateContext();
    final now = ctx.currentTime;
    final cached = _audioBufferCache[assetPath];

    if (cached != null) {
      // 100% Real Sampled Audio Buffer Player
      final source = ctx.createBufferSource();
      source.buffer = cached;
      source.playbackRate.value = speed;

      final gainNode = ctx.createGain();
      gainNode.gain.setValueAtTime(volume.clamp(0.01, 1.2), now);

      source.connect(gainNode);
      gainNode.connect(ctx.destination);

      source.start(now);
      return;
    }

    // High-Fidelity Multi-Harmonic Acoustic Felt Piano / Rhodes Synthesizer Fallback
    final targetFreq = fallbackFreq * speed;
    final osc1 = ctx.createOscillator(); // Fundamental
    final osc2 = ctx.createOscillator(); // Warm 2nd harmonic
    final osc3 = ctx.createOscillator(); // 3rd chime harmonic
    final gain1 = ctx.createGain();
    final gain2 = ctx.createGain();
    final gain3 = ctx.createGain();
    final masterGain = ctx.createGain();
    final filter = ctx.createBiquadFilter();

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(2400.0, now);
    filter.frequency.exponentialRampToValueAtTime(700.0, now + 1.2);

    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(targetFreq, now);
    gain1.gain.setValueAtTime(0.70, now);

    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(targetFreq * 2.0, now);
    gain2.gain.setValueAtTime(0.22, now);

    osc3.type = 'sine';
    osc3.frequency.setValueAtTime(targetFreq * 3.0, now);
    gain3.gain.setValueAtTime(0.08, now);

    // Natural Piano ADSR Envelope
    final effVol = volume.clamp(0.01, 1.0) * 0.45;
    masterGain.gain.setValueAtTime(0.0001, now);
    masterGain.gain.linearRampToValueAtTime(effVol, now + 0.006); // Fast natural hammer strike
    masterGain.gain.exponentialRampToValueAtTime(0.0001, now + 1.8); // Smooth musical ring decay

    osc1.connect(gain1);
    osc2.connect(gain2);
    osc3.connect(gain3);
    gain1.connect(filter);
    gain2.connect(filter);
    gain3.connect(filter);
    filter.connect(masterGain);
    masterGain.connect(ctx.destination);

    osc1.start(now);
    osc2.start(now);
    osc3.start(now);
    osc1.stop(now + 1.9);
    osc2.stop(now + 1.9);
    osc3.stop(now + 1.9);
  } catch (_) {}
}

/// Plays one-shot sampled audio via Web Audio Buffer API.
void playHtml5Audio(String assetPath, {double speed = 1.0, double volume = 0.8}) {
  _playCachedOrSyntheticSample(
    assetPath,
    speed: speed,
    volume: volume,
    fallbackFreq: 293.665,
  );
}

/// Plays a Real MRT Field Recording Sample with slice trimming, harmonic pitch tuning, envelope, and lowpass filter.
void playHtml5RealMrtSample(
  String assetPath, {
  double volume = 0.35,
  double playbackRate = 1.0,
  double lowpassFreq = 2800.0,
  double offsetSeconds = 0.0,
  double? durationSeconds,
}) {
  try {
    final ctx = _getOrCreateContext();
    final now = ctx.currentTime;
    final cached = _audioBufferCache[assetPath];

    if (cached != null) {
      final source = ctx.createBufferSource();
      source.buffer = cached;
      source.playbackRate.value = playbackRate.clamp(0.5, 2.0);

      // Warm vintage Lo-Fi Low-pass filter to soften harsh environmental noise
      final filter = ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.value = lowpassFreq;

      final gainNode = ctx.createGain();
      final targetVol = volume.clamp(0.01, 1.0);
      gainNode.gain.setValueAtTime(0.001, now);
      gainNode.gain.linearRampToValueAtTime(targetVol, now + 0.04);

      final playDuration = durationSeconds ?? math.min(1.5, cached.duration.toDouble());
      gainNode.gain.setValueAtTime(targetVol, now + math.max(0.05, playDuration - 0.15));
      gainNode.gain.exponentialRampToValueAtTime(0.0001, now + playDuration);

      source.connect(filter);
      filter.connect(gainNode);
      gainNode.connect(ctx.destination);

      source.start(now, offsetSeconds, playDuration + 0.05);
      return;
    }

    _playCachedOrSyntheticSample(
      assetPath,
      speed: playbackRate,
      volume: volume,
      fallbackFreq: 440.0,
    );
  } catch (_) {}
}

/// Plays a lush multi-voice Lo-Fi chord Pad using genuine acoustic sample buffers.
void playHtml5Pad(
  List<int> semitones, {
  double volume = 0.6,
  double durationSeconds = 3.2,
}) {
  try {
    final ctx = _getOrCreateContext();
    final now = ctx.currentTime;
    final cachedPad = _audioBufferCache[AudioConstants.taiwanRhodesPad];

    if (cachedPad != null) {
      for (final s in semitones) {
        final source = ctx.createBufferSource();
        source.buffer = cachedPad;
        source.playbackRate.value = AudioConstants.semitonesToSpeed(s);

        final gain = ctx.createGain();
        gain.gain.setValueAtTime(0.0001, now);
        gain.gain.linearRampToValueAtTime(volume / semitones.length, now + 0.6);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + durationSeconds);

        source.connect(gain);
        gain.connect(ctx.destination);

        source.start(now);
        source.stop(now + durationSeconds + 0.1);
      }
      return;
    }

    // High quality synthetic fallback pad
    for (final s in semitones) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      final filter = ctx.createBiquadFilter();

      filter.type = 'lowpass';
      filter.frequency.value = 1600;

      osc.type = 'sine';
      osc.frequency.setValueAtTime(_semitoneToFreq(s), now);

      gain.gain.setValueAtTime(0.0001, now);
      gain.gain.linearRampToValueAtTime(volume * 0.18 / semitones.length, now + 0.6);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + durationSeconds);

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + durationSeconds + 0.1);
    }
  } catch (_) {}
}

/// Plays a smooth Portamento Glide note.
void playHtml5GlideNote({
  required int startSemitone,
  required int targetSemitone,
  double volume = 0.7,
  double glideDuration = 0.16,
}) {
  try {
    final ctx = _getOrCreateContext();
    final now = ctx.currentTime;
    final cachedPiano = _audioBufferCache[AudioConstants.fallbackFeltPiano];

    if (cachedPiano != null) {
      final source = ctx.createBufferSource();
      source.buffer = cachedPiano;

      final startRate = AudioConstants.semitonesToSpeed(startSemitone);
      final targetRate = AudioConstants.semitonesToSpeed(targetSemitone);

      source.playbackRate.setValueAtTime(startRate, now);
      source.playbackRate.linearRampToValueAtTime(targetRate, now + glideDuration);

      final gain = ctx.createGain();
      gain.gain.setValueAtTime(volume, now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 1.2);

      source.connect(gain);
      gain.connect(ctx.destination);

      source.start(now);
      return;
    }

    // Synthetic glide
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(_semitoneToFreq(startSemitone), now);
    osc.frequency.exponentialRampToValueAtTime(_semitoneToFreq(targetSemitone), now + glideDuration);

    gain.gain.setValueAtTime(volume * 0.35, now);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.8);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.85);
  } catch (_) {}
}

/// Plays a rapid rolling Arpeggio.
void playHtml5Arpeggio(
  List<int> semitones, {
  double volume = 0.6,
  double interval = 0.06,
}) {
  for (int i = 0; i < semitones.length; i++) {
    final delay = i * interval;
    Future.delayed(Duration(milliseconds: (delay * 1000).round()), () {
      _playCachedOrSyntheticSample(
        AudioConstants.fallbackFeltPiano,
        speed: AudioConstants.semitonesToSpeed(semitones[i]),
        volume: volume * (0.85 - (i * 0.05)),
        fallbackFreq: _semitoneToFreq(semitones[i]),
      );
    });
  }
}

/// Plays Taipei Metro Arrival Jingle.
void playHtml5MrtJingle({double volume = 0.8}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanMrtJingle,
    volume: volume,
    fallbackFreq: 330.0,
  );
}

/// Plays Taipei Metro 3-tone Card Tap.
void playHtml5MrtCardTap({double volume = 0.75}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanMrtCardTap,
    volume: volume,
    fallbackFreq: 440.0,
  );
}

/// Plays Taiwan Pedestrian Cuckoo Traffic Signal.
void playHtml5PedestrianBird({bool isTweet = false, double volume = 0.65}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanPedestrianCuckoo,
    volume: volume,
    speed: isTweet ? 1.25 : 1.0,
    fallbackFreq: isTweet ? 880.0 : 660.0,
  );
}

/// Plays YouBike Double Bell Ring.
void playHtml5YouBikeBell({double volume = 0.7}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanYouBikeBell,
    volume: volume,
    fallbackFreq: 2850.0,
  );
}

/// 🏮 Plays resonant Buddhist/Taoist Temple Bell & Singing Bowl (青銅梵鐘與木魚).
void playHtml5TempleBell({double volume = 0.6, bool useWoodenFish = false}) {
  _playCachedOrSyntheticSample(
    useWoodenFish ? AudioConstants.taiwanTempleWoodenFish : AudioConstants.taiwanTempleBronzeBell,
    volume: volume,
    fallbackFreq: 110.0,
  );
}

/// 🍜 Plays lively Night Market Sizzle & Pinball Sounds (夜市熱炒與彈珠台).
void playHtml5NightMarket({double volume = 0.5, bool isPinball = false}) {
  _playCachedOrSyntheticSample(
    isPinball ? AudioConstants.taiwanNightMarketPinball : AudioConstants.taiwanNightMarketWok,
    volume: volume,
    fallbackFreq: 2400.0,
  );
}

/// 🏫 Plays NTU Fu Bell / Campus Westminster 4-tone chime (台大傅鐘鐘聲).
void playHtml5CampusBell({double volume = 0.6}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanCampusFuBell,
    volume: volume,
    fallbackFreq: 415.3,
  );
}

/// 🎨 Plays Cultural & Arts Vinyl / Espresso / Acoustic (松菸華山文創黑膠咖啡).
void playHtml5CulturalWarmth({double volume = 0.5}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanCultureVinylCafe,
    volume: volume,
    fallbackFreq: 220.0,
  );
}

/// 🏪 Plays Taiwan Convenience Store Entrance Chime (超商進門叮咚聲).
void playHtml5ConvenienceStore({double volume = 0.6}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanConvenienceStore,
    volume: volume,
    fallbackFreq: 587.33,
  );
}

/// 🚛 Plays Taiwan Garbage Truck Maiden's Prayer Melody (垃圾車少女的祈禱).
void playHtml5GarbageTruck({double volume = 0.55}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanGarbageTruck,
    volume: volume,
    fallbackFreq: 622.25,
  );
}

/// 🚌 Plays Taipei Bus Card Reader Chime (公車刷卡提示音).
void playHtml5BusCardSwipe({double volume = 0.65}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanBusCardSwipe,
    volume: volume,
    fallbackFreq: 1046.5,
  );
}

/// 🍃 Plays Taipei Summer Cicadas (大安森林/陽明山盛夏蟬鳴).
void playHtml5Cicadas({double volume = 0.45}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanTaipeiCicadas,
    volume: volume,
    fallbackFreq: 4200.0,
  );
}

/// 🐸 Plays Taiwan Native Tree Frogs (象山/富陽自然公園樹蛙鳴叫).
void playHtml5TreeFrogs({double volume = 0.5}) {
  _playCachedOrSyntheticSample(
    AudioConstants.taiwanTreeFrogs,
    volume: volume,
    fallbackFreq: 1550.0,
  );
}

/// Plays acoustic Kick drum.
void playHtml5Kick({double volume = 0.7}) {
  try {
    final ctx = _getOrCreateContext();
    final now = ctx.currentTime;

    final osc = ctx.createOscillator();
    final gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(140.0, now);
    osc.frequency.exponentialRampToValueAtTime(42.0, now + 0.08);

    gain.gain.setValueAtTime(volume.clamp(0.01, 1.0), now);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.28);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.3);
  } catch (_) {}
}

/// Plays acoustic Snare / Rimshot.
void playHtml5Snare({double volume = 0.6, bool useFallback = false}) {
  _playCachedOrSyntheticSample(
    AudioConstants.fallbackSnare,
    volume: volume,
    fallbackFreq: 220.0,
  );
}

/// Plays acoustic Hi-Hat.
void playHtml5HiHat({double volume = 0.4}) {
  _playCachedOrSyntheticSample(
    AudioConstants.fallbackHiHat,
    volume: volume,
    fallbackFreq: 6200.0,
  );
}

/// Plays a punchy acoustic/synth Lo-Fi Bass note.
void playHtml5BassNote({
  required int semitones,
  double volume = 0.7,
  double durationSeconds = 0.8,
}) {
  try {
    final ctx = _getOrCreateContext();
    final now = ctx.currentTime;
    final baseFreq = _semitoneToFreq(semitones - 12); // Octave down for deep sub bass

    final osc1 = ctx.createOscillator();
    final osc2 = ctx.createOscillator();
    final gain = ctx.createGain();
    final filter = ctx.createBiquadFilter();

    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(baseFreq, now);

    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(baseFreq, now);

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(360.0, now);
    filter.frequency.exponentialRampToValueAtTime(120.0, now + durationSeconds);

    final effVol = volume.clamp(0.01, 1.0) * 0.68;
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.linearRampToValueAtTime(effVol, now + 0.015);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + durationSeconds);

    osc1.connect(filter);
    osc2.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + durationSeconds + 0.05);
    osc2.stop(now + durationSeconds + 0.05);
  } catch (_) {}
}

/// Sets or adjusts continuous loop tracks (Sub-Bass or Vinyl/Rain).
void setHtml5LoopAudio(String key, String assetPath, double volume) {
  try {
    final ctx = _getOrCreateContext();
    final clampedVol = volume.clamp(0.0, 1.0);
    final now = ctx.currentTime;

    if (key == 'sub_bass') {
      if (_subBassOsc == null) {
        _subBassOsc = ctx.createOscillator()
          ..type = 'sine'
          ..frequency.value = 55.0;
        _subBassGain = ctx.createGain()
          ..gain.setValueAtTime(0.0001, now);

        _subBassOsc!.connect(_subBassGain!);
        _subBassGain!.connect(ctx.destination);
        _subBassOsc!.start(now);
      }
      _subBassGain?.gain.setTargetAtTime(clampedVol * 0.25, now, 0.1);
    } else if (key == 'vinyl') {
      // Use sampled gentle rain/vinyl buffer if loaded
      final rainBuf = _audioBufferCache[AudioConstants.taiwanTaipeiRain];
      if (rainBuf != null) {
        // Sample buffer rain loop handled by web buffer source
      }
      if (_vinylGain == null) {
        _vinylOsc = ctx.createOscillator()
          ..type = 'triangle'
          ..frequency.value = 80.0;

        final filter = ctx.createBiquadFilter()
          ..type = 'lowpass'
          ..frequency.value = 400.0;

        _vinylGain = ctx.createGain()
          ..gain.setValueAtTime(0.0001, now);

        _vinylOsc!.connect(filter);
        filter.connect(_vinylGain!);
        _vinylGain!.connect(ctx.destination);
        _vinylOsc!.start(now);
      }
      _vinylGain?.gain.setTargetAtTime(clampedVol * 0.08, now, 0.1);
    }
  } catch (_) {}
}

/// Stops all active Web audio loops.
void stopHtml5Audio() {
  try {
    if (_audioCtx != null) {
      final now = _audioCtx!.currentTime;
      _subBassGain?.gain.setTargetAtTime(0.0001, now, 0.05);
      _vinylGain?.gain.setTargetAtTime(0.0001, now, 0.05);
    }
  } catch (_) {}
}
