import 'dart:math' as math;

/// Core audio, scale, and tempo constants for the Cyber-LoFi engine.
abstract final class AudioConstants {
  /// Base reference frequency for D4 in Hertz.
  static const double baseFrequencyD4 = 293.665;

  /// Semitone offsets for D Major Pentatonic scale relative to D4 (0).
  /// [D4 (0), E4 (+2), F#4 (+4), A4 (+7), B4 (+9), D5 (+12)]
  static const List<int> dMajorPentatonicSemitones = [0, 2, 4, 7, 9, 12];

  /// Pitch Shift Boundary Limit: if |delta_semitones| > 7, fallback to felt piano.
  static const int maxFoleySemitoneShift = 7;

  /// Default and minimum tempo in beats per minute.
  static const double minBpm = 75.0;

  /// Maximum tempo cap in beats per minute.
  static const double maxBpm = 95.0;

  /// Acceleration to BPM mapping multiplier: BPM = minBpm + (M * bpmMultiplier).
  static const double bpmMultiplier = 5.0;

  /// Stationary threshold in m/s^2 (de-gravity magnitude M).
  static const double motionStationaryThreshold = 0.3;

  /// Standard Earth gravity magnitude in m/s^2.
  static const double standardGravity = 9.80665;

  /// Asset paths for primary Foley samples.
  static const String foleyMrtBeep = 'assets/audio/foley_primary/mrt_beep.wav';
  static const String foleyAirBrake = 'assets/audio/foley_primary/air_brake.wav';
  static const String foleyPowerSpark = 'assets/audio/foley_primary/power_spark.wav';
  static const String foleySubwayRumble = 'assets/audio/foley_primary/subway_rumble.wav';
  static const String foleyWaterTrickle = 'assets/audio/foley_primary/water_trickle.wav';

  /// Asset paths for authentic Taiwanese Urban Field Recordings & Physical Models.
  static const String taiwanMrtJingle = 'assets/audio/taiwan_urban/mrt_arrival_jingle.wav';
  static const String taiwanMrtCardTap = 'assets/audio/taiwan_urban/mrt_card_tap_triplet.wav';
  static const String taiwanPedestrianCuckoo = 'assets/audio/taiwan_urban/pedestrian_cuckoo.wav';
  static const String taiwanYouBikeBell = 'assets/audio/taiwan_urban/youbike_bell_dual.wav';
  static const String taiwanTaipeiRain = 'assets/audio/taiwan_urban/taipei_rain_lofi.wav';
  static const String taiwanRhodesPad = 'assets/audio/taiwan_urban/rhodes_chord_pad.wav';

  // 1. 傳統廟宇 (Temples & Spiritual)
  static const String taiwanTempleBronzeBell = 'assets/audio/taiwan_urban/temple_bronze_bell.wav';
  static const String taiwanTempleWoodenFish = 'assets/audio/taiwan_urban/temple_wooden_fish.wav';

  // 2. 夜市老街 (Night Markets & Street Life)
  static const String taiwanNightMarketWok = 'assets/audio/taiwan_urban/night_market_wok_sizzle.wav';
  static const String taiwanNightMarketPinball = 'assets/audio/taiwan_urban/night_market_pinball.wav';

  // 3. 日常都會生活 (Daily Urban Culture)
  static const String taiwanConvenienceStore = 'assets/audio/taiwan_urban/convenience_store_chime.wav';
  static const String taiwanGarbageTruck = 'assets/audio/taiwan_urban/garbage_truck_melody.wav';
  static const String taiwanBusCardSwipe = 'assets/audio/taiwan_urban/bus_card_swipe.wav';

  // 4. 自然生態與公園 (Nature & Parks)
  static const String taiwanTaipeiCicadas = 'assets/audio/taiwan_urban/taipei_summer_cicadas.wav';
  static const String taiwanTreeFrogs = 'assets/audio/taiwan_urban/taiwan_tree_frogs.wav';

  // 5. 學術與文創生活 (Campus & Cultural Parks)
  static const String taiwanCampusFuBell = 'assets/audio/taiwan_urban/campus_fu_bell.wav';
  static const String taiwanCultureVinylCafe = 'assets/audio/taiwan_urban/culture_vinyl_cafe.wav';

  /// Real Field Recordings - Taipei MRT Door & Broadcast Collection
  static const String realMrtC301DoorClosing = 'assets/audio/real_recordings/01_mrt_c301_door_closing.wav';
  static const String realMrtC321DoorClosing = 'assets/audio/real_recordings/02_mrt_c321_door_closing.wav';
  static const String realMrtC341DoorClosing = 'assets/audio/real_recordings/03_mrt_c341_door_closing.wav';
  static const String realMrtC371DoorOpening = 'assets/audio/real_recordings/04_mrt_c371_door_opening.wav';
  static const String realMrtC371DoorClosing = 'assets/audio/real_recordings/05_mrt_c371_door_closing.wav';
  static const String realMrtC381DoorOpening = 'assets/audio/real_recordings/06_mrt_c381_door_opening.wav';
  static const String realMrtC381DoorClosing = 'assets/audio/real_recordings/07_mrt_c381_door_closing.wav';
  static const String realMrtCircularArrival = 'assets/audio/real_recordings/08_mrt_circular_door_opening_and_arrival_announcement.wav';
  static const String realMrtCircularClosing = 'assets/audio/real_recordings/09_mrt_circular_door_closing_new_and_old.wav';
  static const String realMrtClosingVoice = 'assets/audio/real_recordings/10_mrt_doors_closing_voice_announcement.wav';

  /// Asset paths for fallback instruments.
  static const String fallbackFeltPiano = 'assets/audio/fallback_instruments/felt_piano_d.wav';
  static const String fallbackSnare = 'assets/audio/fallback_instruments/lofi_snare.wav';
  static const String fallbackHiHat = 'assets/audio/fallback_instruments/hihat.wav';

  /// Computes playback rate (speed multiplier) for a given semitone offset.
  /// speed = 2^(semitones / 12)
  static double semitonesToSpeed(int semitones) {
    return math.pow(2.0, semitones / 12.0).toDouble();
  }

  /// Checks whether a semitone offset requires fallback instrument protection.
  static bool requiresFallback(int semitones) {
    return semitones.abs() > maxFoleySemitoneShift;
  }
}
