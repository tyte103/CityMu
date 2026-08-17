/// Encapsulates the current audio state, musical elements, and playback metrics.
class AudioParameter {
  const AudioParameter({
    required this.bpm,
    required this.isPlaying,
    required this.subBassVolume,
    required this.vinylVolume,
    required this.sparkVolume,
    required this.isRhythmActive,
    required this.currentSemitone,
    required this.isUsingFallback,
    required this.stepIndex,
    required this.barIndex,
    required this.currentChordName,
    required this.activeSoundSource,
    required this.isKickActive,
    required this.isSnareActive,
    required this.isHiHatActive,
    required this.isPadActive,
  });

  final double bpm;
  final bool isPlaying;
  final double subBassVolume;
  final double vinylVolume;
  final double sparkVolume;
  final bool isRhythmActive;
  final int currentSemitone;
  final bool isUsingFallback;
  final int stepIndex;
  final int barIndex;
  final String currentChordName;
  final String activeSoundSource;
  final bool isKickActive;
  final bool isSnareActive;
  final bool isHiHatActive;
  final bool isPadActive;

  AudioParameter copyWith({
    double? bpm,
    bool? isPlaying,
    double? subBassVolume,
    double? vinylVolume,
    double? sparkVolume,
    bool? isRhythmActive,
    int? currentSemitone,
    bool? isUsingFallback,
    int? stepIndex,
    int? barIndex,
    String? currentChordName,
    String? activeSoundSource,
    bool? isKickActive,
    bool? isSnareActive,
    bool? isHiHatActive,
    bool? isPadActive,
  }) {
    return AudioParameter(
      bpm: bpm ?? this.bpm,
      isPlaying: isPlaying ?? this.isPlaying,
      subBassVolume: subBassVolume ?? this.subBassVolume,
      vinylVolume: vinylVolume ?? this.vinylVolume,
      sparkVolume: sparkVolume ?? this.sparkVolume,
      isRhythmActive: isRhythmActive ?? this.isRhythmActive,
      currentSemitone: currentSemitone ?? this.currentSemitone,
      isUsingFallback: isUsingFallback ?? this.isUsingFallback,
      stepIndex: stepIndex ?? this.stepIndex,
      barIndex: barIndex ?? this.barIndex,
      currentChordName: currentChordName ?? this.currentChordName,
      activeSoundSource: activeSoundSource ?? this.activeSoundSource,
      isKickActive: isKickActive ?? this.isKickActive,
      isSnareActive: isSnareActive ?? this.isSnareActive,
      isHiHatActive: isHiHatActive ?? this.isHiHatActive,
      isPadActive: isPadActive ?? this.isPadActive,
    );
  }

  factory AudioParameter.initial() {
    return const AudioParameter(
      bpm: 75.0,
      isPlaying: false,
      subBassVolume: 0.0,
      vinylVolume: 0.0,
      sparkVolume: 0.0,
      isRhythmActive: false,
      currentSemitone: 0,
      isUsingFallback: false,
      stepIndex: 0,
      barIndex: 0,
      currentChordName: 'Dmaj7',
      activeSoundSource: '待機中',
      isKickActive: false,
      isSnareActive: false,
      isHiHatActive: false,
      isPadActive: false,
    );
  }
}
