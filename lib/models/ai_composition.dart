/// Data model for an AI-composed spatial Lo-Fi musical piece.
class AiMotifNote {
  final int bar; // 0 to 3
  final int step; // 0 to 15
  final int semitone; // relative to D (or root)
  final double velocity;
  final double durationSeconds;
  final bool hasGraceNote; // 爵士微裝飾音

  const AiMotifNote({
    required this.bar,
    required this.step,
    required this.semitone,
    this.velocity = 0.85,
    this.durationSeconds = 1.0,
    this.hasGraceNote = false,
  });

  factory AiMotifNote.fromJson(Map<String, dynamic> json) {
    return AiMotifNote(
      bar: (json['bar'] as num?)?.toInt() ?? 0,
      step: (json['step'] as num?)?.toInt() ?? 2,
      semitone: (json['semitone'] as num?)?.toInt() ?? 0,
      velocity: (json['velocity'] as num?)?.toDouble() ?? 0.85,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 1.0,
      hasGraceNote: json['hasGraceNote'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'bar': bar,
    'step': step,
    'semitone': semitone,
    'velocity': velocity,
    'durationSeconds': durationSeconds,
    'hasGraceNote': hasGraceNote,
  };
}

/// Represents the complete AI composition for a specific urban location.
class AiComposition {
  final String title;
  final String poeticStory;
  final String scaleName;
  final List<List<int>> chordProgression; // 4 bars of chord semitone lists
  final List<String> chordNames; // 4 chord names e.g. ["Dmaj7", "Bm7", "Gmaj7", "A7sus4"]
  final List<int> rootSemitones;
  final List<AiMotifNote> motifNotes; // 4-bar structured melody events
  final double melodyWeight;
  final double bassWeight;
  final double textureWeight;
  final double sparkWeight;
  final double composedLongitude;
  final double composedLatitude;
  final DateTime composedAt;

  const AiComposition({
    required this.title,
    required this.poeticStory,
    required this.scaleName,
    required this.chordProgression,
    required this.chordNames,
    required this.rootSemitones,
    required this.motifNotes,
    this.melodyWeight = 0.85,
    this.bassWeight = 0.75,
    this.textureWeight = 0.60,
    this.sparkWeight = 0.50,
    required this.composedLongitude,
    required this.composedLatitude,
    required this.composedAt,
  });

  /// Default harmonic piece used before first AI generation or on error
  factory AiComposition.defaultTaipeiStation(double lon, double lat) {
    return AiComposition(
      title: '台北車站 · 晨光微光',
      poeticStory: '川流不息的都會動脈，電聯車與晨光共鳴出溫暖的 Neo-Soul 節奏。',
      scaleName: 'D Major Neo-Soul',
      chordProgression: [
        [0, 4, 7, 11], // Dmaj7
        [-3, 0, 4, 7], // Bm7
        [-7, -3, 0, 4], // Gmaj7
        [-5, 0, 2, 5], // A7sus4
      ],
      chordNames: ['Dmaj7', 'Bm7', 'Gmaj7', 'A7sus4'],
      rootSemitones: [0, -3, -7, -5],
      motifNotes: [
        const AiMotifNote(bar: 0, step: 2, semitone: 4, velocity: 0.90, hasGraceNote: true),
        const AiMotifNote(bar: 0, step: 6, semitone: 7, velocity: 0.92),
        const AiMotifNote(bar: 0, step: 10, semitone: 9, velocity: 0.85),
        const AiMotifNote(bar: 0, step: 14, semitone: 12, velocity: 0.80),
        const AiMotifNote(bar: 1, step: 2, semitone: 11, velocity: 0.86),
        const AiMotifNote(bar: 1, step: 6, semitone: 9, velocity: 0.88),
        const AiMotifNote(bar: 1, step: 10, semitone: 7, velocity: 0.82),
        const AiMotifNote(bar: 1, step: 14, semitone: 4, velocity: 0.78),
        const AiMotifNote(bar: 2, step: 2, semitone: 0, velocity: 0.88, hasGraceNote: true),
        const AiMotifNote(bar: 2, step: 6, semitone: 4, velocity: 0.90),
        const AiMotifNote(bar: 2, step: 10, semitone: 7, velocity: 0.94),
        const AiMotifNote(bar: 2, step: 14, semitone: 14, velocity: 0.85),
        const AiMotifNote(bar: 3, step: 2, semitone: 12, velocity: 0.90),
        const AiMotifNote(bar: 3, step: 6, semitone: 9, velocity: 0.85),
        const AiMotifNote(bar: 3, step: 10, semitone: 7, velocity: 0.80),
        const AiMotifNote(bar: 3, step: 14, semitone: 0, velocity: 0.75),
      ],
      melodyWeight: 0.9,
      bassWeight: 0.8,
      textureWeight: 0.6,
      sparkWeight: 0.5,
      composedLongitude: lon,
      composedLatitude: lat,
      composedAt: DateTime.now(),
    );
  }

  factory AiComposition.fromJson(Map<String, dynamic> json, double lon, double lat) {
    final rawChords = json['chordProgression'] as List<dynamic>?;
    List<List<int>> chords = [];
    if (rawChords != null) {
      for (final c in rawChords) {
        if (c is List) {
          chords.add(c.map((e) => (e as num).toInt()).toList());
        }
      }
    }
    if (chords.length < 4) {
      chords = [
        [0, 4, 7, 11],
        [-3, 0, 4, 7],
        [-7, -3, 0, 4],
        [-5, 0, 2, 5],
      ];
    }

    final rawChordNames = (json['chordNames'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Dmaj7', 'Bm7', 'Gmaj7', 'A7sus4'];

    final rawRoots = (json['rootSemitones'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [0, -3, -7, -5];

    final rawNotes = json['motifNotes'] as List<dynamic>?;
    List<AiMotifNote> notes = [];
    if (rawNotes != null) {
      for (final n in rawNotes) {
        if (n is Map<String, dynamic>) {
          notes.add(AiMotifNote.fromJson(n));
        }
      }
    }
    if (notes.isEmpty) {
      notes = AiComposition.defaultTaipeiStation(lon, lat).motifNotes;
    }

    return AiComposition(
      title: json['title'] as String? ?? '城市空間即時聲景',
      poeticStory: json['poeticStory'] as String? ?? '漫步於都市的巷弄與聲波之中。',
      scaleName: json['scaleName'] as String? ?? 'D Major Pentatonic',
      chordProgression: chords,
      chordNames: rawChordNames,
      rootSemitones: rawRoots,
      motifNotes: notes,
      melodyWeight: (json['melodyWeight'] as num?)?.toDouble() ?? 0.85,
      bassWeight: (json['bassWeight'] as num?)?.toDouble() ?? 0.75,
      textureWeight: (json['textureWeight'] as num?)?.toDouble() ?? 0.60,
      sparkWeight: (json['sparkWeight'] as num?)?.toDouble() ?? 0.50,
      composedLongitude: lon,
      composedLatitude: lat,
      composedAt: DateTime.now(),
    );
  }
}
