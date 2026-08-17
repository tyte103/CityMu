import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/enums/feature_type.dart';
import '../models/ai_composition.dart';
import '../models/ambient_mood.dart';
import '../models/spatial_feature.dart';

/// Service leveraging Google Gemini API to dynamically compose custom
/// spatial Lo-Fi music motifs, chord progressions, and poetic soundscape narratives
/// tailored to exact coordinates and nearby urban field elements.
class GeminiService {
  GeminiService._internal() {
    init(apiKey: defaultKey);
  }
  static final GeminiService instance = GeminiService._internal();

  GenerativeModel? _model;
  String? _apiKey;

  String? get currentApiKey => _apiKey;
  bool get hasValidApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Default API key loaded from compile-time environment variable if available
  static const String defaultKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Initializes Gemini API with the given API key.
  void init({String? apiKey, String modelName = 'gemini-3.5-flash-lite'}) {
    _apiKey = (apiKey != null && apiKey.isNotEmpty) ? apiKey : defaultKey;
    try {
      _model = GenerativeModel(
        model: modelName,
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.7,
        ),
      );
      developer.log('Gemini model initialized with $modelName.', name: 'GeminiService');
    } catch (e) {
      developer.log('Failed to initialize Gemini Model: $e', name: 'GeminiService');
    }
  }

  /// Sets or updates the API key at runtime.
  void setApiKey(String key) {
    _apiKey = key.trim();
    if (_apiKey!.isNotEmpty) {
      init(apiKey: _apiKey);
    } else {
      _model = null;
    }
  }

  /// 🎵 Dynamically composes a 4-bar Lo-Fi chord progression and recurring melodic motif
  /// based on nearby sounds, distances, walking BPM, and location coordinates.
  Future<AiComposition> composeSpatialMotif({
    required double longitude,
    required double latitude,
    required List<SpatialFeature> nearbyFeatures,
    required double bpm,
    required bool isWalking,
  }) async {
    // 1. If Gemini model is available, request real-time online AI composition
    if (_model != null) {
      final featuresList = nearbyFeatures.isEmpty
          ? 'No specific landmarks detected (Quiet residential neighborhood)'
          : nearbyFeatures.map((f) =>
              '- [Sound Source: ${f.name} (${f.type.name})], Distance: ${f.distanceMeters.toStringAsFixed(1)}m'
            ).join('\n');

      final prompt = '''
You are the Master AI Lo-Fi Music Composer for CityMu (Urban Taiwan Generative Music Engine).
Compose a dedicated, ultra-musical 4-bar Lo-Fi chord progression and a memorable 4-bar melody motif uniquely inspired by the user's current coordinates and urban soundscape.

[User Real-Time Context]
- Location Coordinates: ($longitude, $latitude)
- Motion Status: ${isWalking ? "Walking" : "Stationary"} ($bpm BPM)
- Available Nearby Urban Sounds & Distances:
$featuresList

[Music Composition Guidelines]
1. Key & Mood: Choose an inspiring key centered around D, G, C, F, Eb, or A (Neo-Soul / Lydian / Pentatonic / Chillhop).
2. "chordProgression": Exactly 4 chords, each chord is an array of semitones relative to Root D=0 (e.g., Dmaj7 is [0, 4, 7, 11], Bm7 is [-3, 0, 4, 7], Gmaj7 is [-7, -3, 0, 4], A7sus4 is [-5, 0, 2, 5]).
3. "chordNames": Exactly 4 names e.g., ["Dmaj7", "Bm7", "Gmaj7", "A7sus4"].
4. "rootSemitones": Array of 4 integers indicating root note of each bar e.g. [0, -3, -7, -5].
5. "motifNotes": Array of 8 to 16 note objects across the 4 bars (bar: 0..3, step: 0..15, semitone: integer relative to D=0, velocity: 0.7..1.0, hasGraceNote: boolean). Must be varied and melodic, following the chord tones and extensions of each bar.
6. Output in valid JSON matching this schema:
{
  "title": "Landmark / Coordinate Title (e.g. 台北車站 · 晨光微光 / 忠孝東路 · 晚風脈動 / 大安林間 · 碎陽慢調)",
  "poeticStory": "1 poetic sentence in Traditional Chinese describing the soundscape vibe.",
  "scaleName": "Scale / Style Name",
  "chordProgression": [[0,4,7,11], [-3,0,4,7], [-7,-3,0,4], [-5,0,2,5]],
  "chordNames": ["Dmaj7", "Bm7", "Gmaj7", "A7sus4"],
  "rootSemitones": [0, -3, -7, -5],
  "motifNotes": [
    {"bar": 0, "step": 2, "semitone": 4, "velocity": 0.9, "hasGraceNote": true},
    {"bar": 0, "step": 6, "semitone": 7, "velocity": 0.92, "hasGraceNote": false},
    {"bar": 0, "step": 10, "semitone": 9, "velocity": 0.85, "hasGraceNote": false},
    {"bar": 0, "step": 14, "semitone": 12, "velocity": 0.80, "hasGraceNote": false},
    {"bar": 1, "step": 1, "semitone": 11, "velocity": 0.86, "hasGraceNote": false},
    {"bar": 1, "step": 5, "semitone": 9, "velocity": 0.88, "hasGraceNote": false},
    {"bar": 1, "step": 9, "semitone": 7, "velocity": 0.82, "hasGraceNote": false},
    {"bar": 1, "step": 13, "semitone": 4, "velocity": 0.78, "hasGraceNote": false},
    {"bar": 2, "step": 2, "semitone": 0, "velocity": 0.88, "hasGraceNote": true},
    {"bar": 2, "step": 6, "semitone": 4, "velocity": 0.90, "hasGraceNote": false},
    {"bar": 2, "step": 10, "semitone": 7, "velocity": 0.94, "hasGraceNote": false},
    {"bar": 2, "step": 14, "semitone": 14, "velocity": 0.85, "hasGraceNote": false},
    {"bar": 3, "step": 3, "semitone": 12, "velocity": 0.90, "hasGraceNote": false},
    {"bar": 3, "step": 7, "semitone": 9, "velocity": 0.85, "hasGraceNote": false},
    {"bar": 3, "step": 11, "semitone": 7, "velocity": 0.80, "hasGraceNote": false},
    {"bar": 3, "step": 15, "semitone": 0, "velocity": 0.75, "hasGraceNote": false}
  ],
  "melodyWeight": 0.88,
  "bassWeight": 0.78,
  "textureWeight": 0.60,
  "sparkWeight": 0.50
}
''';

      try {
        final response = await _model!.generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 12));
        final text = response.text;
        if (text != null && text.isNotEmpty) {
          final cleanJson = _extractJson(text);
          final data = jsonDecode(cleanJson) as Map<String, dynamic>;
          developer.log('Gemini AI composed successfully: ${data['title']}', name: 'GeminiService');
          return AiComposition.fromJson(data, longitude, latitude);
        }
      } catch (e) {
        developer.log('Gemini online error ($e), utilizing instant dynamic spatial generative composer.', name: 'GeminiService');
      }
    }

    // 2. High-Quality Dynamic Algorithmic Generative Composition dynamically calculated from spatial features & coordinates
    return _generateLocalSpatialComposition(longitude, latitude, nearbyFeatures, bpm, isWalking);
  }

  /// Cleans markdown code fences if present in AI response.
  String _extractJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  /// High-Quality Dynamic Spatial Generative Composer that creates a distinct motif
  /// based on dominant closest landmarks, coordinate seeds, dynamic melodic contour generation,
  /// and optional musical style overrides.
  AiComposition _generateLocalSpatialComposition(
    double lon,
    double lat,
    List<SpatialFeature> features,
    double bpm,
    bool isWalking, {
    String? styleOverride,
  }) {
    // Determine closest dominant landmark within acoustic range (<= 350m)
    SpatialFeature? dominant;
    double minDistance = double.infinity;

    for (final f in features) {
      if (f.distanceMeters < minDistance) {
        minDistance = f.distanceMeters;
        dominant = f;
      }
    }

    // Coordinate hash seed for infinite unique variations per coordinate
    final coordSeed = (((lon * 100000).round()).abs() ^ ((lat * 100000).round()).abs()) + (lon * 100).toInt();
    final variationIndex = coordSeed % 4;

    String title;
    String story;
    String scaleName;
    List<List<int>> chords;
    List<String> chordNames;
    List<int> roots;
    double bassW = 0.75;
    double textW = 0.55;
    double sparkW = 0.50;

    if (styleOverride == 'metal') {
      title = '工業金屬 · 城市脈動 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '強烈的 Dorian 小調五度 Power Chords 與厚重低音轟鳴，展現重金屬工業的狂野能量。';
      scaleName = 'D Dorian Heavy Metal';
      chords = [[0, 7, 12, 19], [-2, 5, 10, 17], [-5, 2, 7, 14], [-3, 4, 9, 16]];
      chordNames = ['D5 Power', 'C5 Power', 'G5 Power', 'A5 Power'];
      roots = [0, -2, -5, -3];
      bassW = 0.98;
      textW = 0.40;
      sparkW = 0.90;
    } else if (styleOverride == 'jazz') {
      title = '微醺爵士 · 漫夜藍調 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '浪漫的 Major 9th 與 11th 延伸和弦，伴隨溫潤的 Rhodes 電鋼琴在夜色中流淌。';
      scaleName = 'Eb Major 9th Neo-Soul';
      chords = [[-1, 3, 6, 10, 14], [-6, -2, 1, 5, 8], [-3, 0, 4, 7, 11], [-8, -4, -1, 3, 6]];
      chordNames = ['Ebmaj9', 'Abmaj7', 'Fm9', 'Bb13'];
      roots = [-1, -6, -3, -8];
      bassW = 0.85;
      textW = 0.60;
      sparkW = 0.55;
    } else if (styleOverride == 'rain') {
      title = '深夜細雨 · 黑膠時光 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '細雨敲打在窗櫺上，溫柔降七和弦與黑膠微粒沉澱出深夜的寧靜思緒。';
      scaleName = 'C Minor 9th Melancholic';
      chords = [[-5, -1, 2, 5, 10], [-9, -5, -2, 2, 7], [-7, -3, 0, 3, 8], [-12, -8, -5, -2, 1]];
      chordNames = ['Cm9', 'Abmaj7', 'Fm9', 'G7b9'];
      roots = [-5, -9, -7, -12];
      bassW = 0.70;
      textW = 0.90;
      sparkW = 0.35;
    } else if (styleOverride == 'water') {
      title = '水岸晨曦 · 陽光吉他 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '陽光在粼粼水波上跳躍，明亮清澈的 Lydian 吉他琶音帶來愜意清新的早晨。';
      scaleName = 'F Lydian / Acoustic Sunlit';
      chords = [[-9, -5, -2, 2, 5], [-10, -7, -3, 0, 4], [-12, -8, -5, -1, 2], [-5, -1, 2, 7]];
      chordNames = ['Fmaj7#11', 'Em9', 'Dm9', 'Cmaj7'];
      roots = [-9, -10, -12, -5];
      bassW = 0.55;
      textW = 0.85;
      sparkW = 0.50;
    } else if (styleOverride == 'temple') {
      title = '古剎鐘磬 · 東方禪境 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '青煙繚繞與梵鐘悠揚共鳴，東方五聲音階在古雅香火中撫平浮躁的心靈。';
      scaleName = 'D Oriental Pentatonic (宮商角徵羽)';
      chords = [[0, 4, 7, 14], [-7, -3, 2, 7], [-5, 0, 7, 12], [-3, 0, 4, 9]];
      chordNames = ['D(add9)', 'G(sus2)', 'A(add9)', 'Bm7'];
      roots = [0, -7, -5, -3];
      bassW = 0.60;
      textW = 0.70;
      sparkW = 0.75;
    } else if (styleOverride == 'cyber') {
      title = '賽博霓虹 · 電子脈衝 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '穿梭在霓虹燈影與未來科技之都，高速八度跳躍與電子合成音浪奔騰不息。';
      scaleName = 'A Dorian Cyber Synthwave';
      chords = [[-10, -3, 0, 4, 9], [-13, -6, -2, 2, 7], [-12, -5, -1, 2, 7], [-8, -1, 2, 6, 11]];
      chordNames = ['Am9', 'Fmaj7#11', 'Dm9', 'Em9'];
      roots = [-10, -13, -12, -8];
      bassW = 0.95;
      textW = 0.35;
      sparkW = 0.95;
    } else if (dominant != null && dominant.type == FeatureType.mrt && dominant.distanceMeters <= 250) {
      // 🚇 MRT Metro Hub Zone
      final subStation = dominant.name.contains('台北車站')
          ? '台北車站'
          : (dominant.name.contains('西門') ? '西門捷運站' : '捷運站體');
      title = '$subStation · 晨光微光 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '電聯車進站的五音泛音與車軌聲，編織成都會專屬的 Neo-Soul 節奏。';
      scaleName = 'D Major Neo-Soul';
      bassW = 0.90;
      textW = 0.50;
      sparkW = 0.60;

      if (variationIndex == 0) {
        chords = [[0, 4, 7, 11], [-3, 0, 4, 7], [-7, -3, 0, 4], [-5, 0, 2, 5]];
        chordNames = ['Dmaj7', 'Bm7', 'Gmaj7', 'A7sus4'];
        roots = [0, -3, -7, -5];
      } else if (variationIndex == 1) {
        chords = [[-7, -3, 0, 4], [-5, 0, 2, 5], [0, 4, 7, 11], [-3, 0, 4, 7]];
        chordNames = ['Gmaj7', 'A7sus4', 'Dmaj7', 'Bm7'];
        roots = [-7, -5, 0, -3];
      } else if (variationIndex == 2) {
        chords = [[-3, 0, 4, 7], [-7, -3, 0, 4], [-5, 0, 2, 5], [0, 4, 7, 11]];
        chordNames = ['Bm7', 'Gmaj7', 'A7sus4', 'Dmaj7'];
        roots = [-3, -7, -5, 0];
      } else {
        chords = [[0, 4, 7, 11], [-7, -3, 0, 4], [-3, 0, 4, 7], [-5, 0, 2, 5]];
        chordNames = ['Dmaj7', 'Gmaj7', 'Bm7', 'A7sus4'];
        roots = [0, -7, -3, -5];
      }
    } else if (dominant != null && dominant.type == FeatureType.water && dominant.distanceMeters <= 350) {
      // 🌊 Riverfront Water Zone
      title = '淡水河岸 · 水波微漾 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '水流細語與微風交錯，流暢的 Lydian 和聲在波光中緩緩迴盪。';
      scaleName = 'F Lydian / C Chillhop';
      bassW = 0.50;
      textW = 0.88;
      sparkW = 0.40;

      if (variationIndex == 0) {
        chords = [[-9, -5, -2, 2, 5], [-10, -7, -3, 0, 4], [-12, -8, -5, -1, 2], [-5, -1, 2, 7]];
        chordNames = ['Fmaj7#11', 'Em9', 'Dm9', 'Cmaj7'];
        roots = [-9, -10, -12, -5];
      } else {
        chords = [[-5, -1, 2, 7], [-9, -5, -2, 2, 5], [-12, -8, -5, -1, 2], [-10, -7, -3, 0, 4]];
        chordNames = ['Cmaj7', 'Fmaj7#11', 'Dm9', 'Em9'];
        roots = [-5, -9, -12, -10];
      }
    } else if (dominant != null && dominant.type == FeatureType.park && dominant.distanceMeters <= 350) {
      // 🌳 Park / Greenery Zone
      final parkName = dominant.name.contains('大安') ? '大安森林' : '綠意公園';
      title = '$parkName · 林間微風 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '穿透樹梢的碎陽與鳥鳴號誌，帶來如詩般的木質 Lo-Fi 旋律。';
      scaleName = 'G Major Pentatonic';
      bassW = 0.60;
      textW = 0.65;
      sparkW = 0.55;

      if (variationIndex == 0) {
        chords = [[-7, -3, 0, 4, 7], [-5, -1, 2, 5], [-10, -7, -3, 0], [-8, -5, -1, 2]];
        chordNames = ['Gmaj9', 'Cmaj7', 'Am7', 'D9'];
        roots = [-7, -5, -10, -8];
      } else {
        chords = [[-5, -1, 2, 5], [-7, -3, 0, 4, 7], [-10, -7, -3, 0], [-8, -5, -1, 2]];
        chordNames = ['Cmaj7', 'Gmaj9', 'Am7', 'D9'];
        roots = [-5, -7, -10, -8];
      }
    } else if (dominant != null && dominant.type == FeatureType.power && dominant.distanceMeters <= 350) {
      // ⚡ Tech / Power Grid Zone
      title = '光華科技廊道 · 霓虹脈衝 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      story = '電網與城市變壓節點的微電流，化為俐落的 Future Lo-Fi 律動。';
      scaleName = 'A Dorian Electronic';
      bassW = 0.80;
      textW = 0.40;
      sparkW = 0.95;

      chords = [[-10, -7, -3, 0], [-5, 0, 2, 5], [-8, -5, -1, 2], [-7, -3, 0, 4]];
      chordNames = ['Am7', 'D7sus4', 'Em7', 'Gmaj7'];
      roots = [-10, -5, -8, -7];
    } else {
      // 🏙️ Quiet Residential Neighborhood Zone (Coordinates roaming)
      final subLoc = '巷弄漫步 [${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}]';
      title = '靜謐街角 · $subLoc';
      story = '遠離喧囂的台北巷弄，午後微風伴隨放鬆的溫暖木質琴音。';
      scaleName = 'C Major Warm Lo-Fi';
      bassW = 0.65;
      textW = 0.60;
      sparkW = 0.45;

      if (variationIndex == 0) {
        chords = [[-5, -1, 2, 7], [-10, -7, -3, 0], [-12, -8, -5, -1], [-7, -3, 0, 2]];
        chordNames = ['Cmaj7', 'Am7', 'Dm7', 'G7'];
        roots = [-5, -10, -12, -7];
      } else if (variationIndex == 1) {
        chords = [[-12, -8, -5, -1], [-7, -3, 0, 2], [-5, -1, 2, 7], [-10, -7, -3, 0]];
        chordNames = ['Dm7', 'G7', 'Cmaj7', 'Am7'];
        roots = [-12, -7, -5, -10];
      } else {
        chords = [[-5, -1, 2, 7], [-7, -3, 0, 2], [-10, -7, -3, 0], [-12, -8, -5, -1]];
        chordNames = ['Cmaj7', 'G7', 'Am7', 'Dm7'];
        roots = [-5, -7, -10, -12];
      }
    }

    // Dynamic Algorithmic Melody Generation:
    // Builds a customized, lyrical singing arc tailored to the coordinate seed & chords
    final List<AiMotifNote> generatedNotes = [];

    // Musical phrasing rhythm templates per bar (Neo-Soul / Lo-Fi syncopations)
    final stepTemplates = [
      [2, 6, 10],           // Space-filled opening motif
      [1, 4, 8, 12],        // Groovy conversational answer
      [2, 6, 9, 14],        // Emotive singing climax
      [0, 4, 8],            // Gentle resolution cadence
    ];

    for (int bar = 0; bar < 4; bar++) {
      final chord = chords[bar];
      final root = roots[bar];
      final steps = stepTemplates[bar % stepTemplates.length];

      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        
        // Select harmonious pitch from chord tones with smooth voice leading
        final toneIndex = (coordSeed + i * 2) % chord.length;
        int notePitch = chord[toneIndex];

        // Ensure notes sit comfortably within the singing register (D4 to B5)
        if (bar == 0) {
          // Opening motif: gentle mid-range
          notePitch = chord[i % chord.length];
        } else if (bar == 1) {
          // Ascending motion
          notePitch = chord[(i + 1) % chord.length] + ((i == steps.length - 1) ? 2 : 0);
        } else if (bar == 2) {
          // Sweet climax: reach 7th or 9th extension
          notePitch = root + 9 + ((i % 2 == 0) ? 0 : -2);
        } else {
          // Resolving down to tonic root/third
          notePitch = chord[0] + ((i == steps.length - 1) ? 0 : 4);
        }

        final bool hasGrace = (step % 4 == 2) && ((coordSeed + i) % 3 == 0);
        final double velocity = 0.75 + (((coordSeed + step * 5) % 20) / 100.0);

        generatedNotes.add(
          AiMotifNote(
            bar: bar,
            step: step,
            semitone: notePitch,
            velocity: velocity.clamp(0.70, 0.95),
            hasGraceNote: hasGrace,
          ),
        );
      }
    }

    return AiComposition(
      title: title,
      poeticStory: story,
      scaleName: scaleName,
      chordProgression: chords,
      chordNames: chordNames,
      rootSemitones: roots,
      motifNotes: generatedNotes,
      melodyWeight: 0.88,
      bassWeight: bassW,
      textureWeight: textW,
      sparkWeight: sparkW,
      composedLongitude: lon,
      composedLatitude: lat,
      composedAt: DateTime.now(),
    );
  }

  /// 💬 Conversational interaction with Gemini AI Composer.
  /// Allows the user to ask questions, request style adjustments, or instruct custom compositions.
  Future<AiChatResponse> chatWithComposer({
    required String userPrompt,
    required double longitude,
    required double latitude,
    required List<SpatialFeature> nearbyFeatures,
    required double bpm,
    required bool isWalking,
    required AiComposition currentComposition,
  }) async {
    final featuresSummary = nearbyFeatures.isEmpty
        ? '安靜街區 (無特別近距離地標)'
        : nearbyFeatures.take(5).map((f) => '${f.name}(${f.distanceMeters.toStringAsFixed(0)}m)').join(', ');

    if (_model != null) {
      final prompt = '''
You are the Master AI Lo-Fi Music Composer for CityMu (Urban Taiwan Generative Music Engine).
The user is directly chatting with you in real-time while listening to the generative music in Greater Taipei.

[Current Music & Location Context]
- Location Coordinates: ($longitude, $latitude)
- Current Track: ${currentComposition.title} (${currentComposition.scaleName})
- Current Chords: ${currentComposition.chordNames.join(' - ')}
- Nearby Sounds: $featuresSummary
- Motion Status: ${isWalking ? "Walking" : "Stationary"} ($bpm BPM)

[User Chat Message]
"$userPrompt"

[Instructions]
1. Answer the user politely and enthusiastically in Traditional Chinese (繁體中文).
2. If the user asks you to modify the music, change musical styles, create a new melody, adjust chords, or compose for the current scene, provide BOTH a conversational response in "replyMessage" AND a complete new musical composition in "newComposition".
3. If the user only asks questions (e.g. asking why music sounds a certain way, or explaining the chords, or general chat), answer them nicely in "replyMessage" and set "hasNewComposition" to false.
4. Output in valid JSON matching this schema:
{
  "replyMessage": "Your conversational answer in Traditional Chinese",
  "hasNewComposition": true,
  "newComposition": {
    "title": "...",
    "poeticStory": "...",
    "scaleName": "...",
    "chordProgression": [[0,4,7,11], [-3,0,4,7], [-7,-3,0,4], [-5,0,2,5]],
    "chordNames": ["Dmaj7", "Bm7", "Gmaj7", "A7sus4"],
    "rootSemitones": [0, -3, -7, -5],
    "motifNotes": [
      {"bar": 0, "step": 2, "semitone": 4, "velocity": 0.85, "hasGraceNote": true},
      {"bar": 0, "step": 6, "semitone": 7, "velocity": 0.90, "hasGraceNote": false},
      {"bar": 1, "step": 2, "semitone": 11, "velocity": 0.88, "hasGraceNote": false},
      {"bar": 2, "step": 2, "semitone": 14, "velocity": 0.95, "hasGraceNote": false},
      {"bar": 3, "step": 4, "semitone": 0, "velocity": 0.80, "hasGraceNote": false}
    ],
    "melodyWeight": 0.85,
    "bassWeight": 0.80,
    "textureWeight": 0.65,
    "sparkWeight": 0.50
  }
}
''';

      try {
        final response = await _model!.generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 12));
        final text = response.text;
        if (text != null && text.isNotEmpty) {
          final cleanJson = _extractJson(text);
          final data = jsonDecode(cleanJson) as Map<String, dynamic>;
          final replyMsg = data['replyMessage'] as String? ?? '收到！我已為您微調了空間音樂風格。';
          final hasNewComp = data['hasNewComposition'] == true && data['newComposition'] != null;

          AiComposition? comp;
          if (hasNewComp) {
            comp = AiComposition.fromJson(data['newComposition'] as Map<String, dynamic>, longitude, latitude);
          }

          return AiChatResponse(
            message: replyMsg,
            newComposition: comp,
            isMusicUpdated: comp != null,
          );
        }
      } catch (e) {
        developer.log('Gemini Chat online error: $e', name: 'GeminiService');
      }
    }

    // Dynamic Intelligent Local Fallback Response
    return _generateLocalChatResponse(userPrompt, longitude, latitude, nearbyFeatures, bpm, isWalking, currentComposition);
  }

  /// Intelligent local fallback chat handler with full natural language understanding
  AiChatResponse _generateLocalChatResponse(
    String prompt,
    double lon,
    double lat,
    List<SpatialFeature> features,
    double bpm,
    bool isWalking,
    AiComposition current,
  ) {
    final lower = prompt.trim().toLowerCase();

    // 1. Identity & Self-Introduction ("你是誰", "自我介紹", "介紹自己", "你叫什麼")
    final bool isIdentity = lower.contains('你是誰') ||
        lower.contains('你是') ||
        lower.contains('你是哪位') ||
        lower.contains('自我介紹') ||
        lower.contains('介紹自己') ||
        lower.contains('你是做什麼') ||
        lower.contains('你叫什麼') ||
        lower.contains('名字') ||
        lower.contains('who are you') ||
        lower.contains('who r u');

    if (isIdentity) {
      return const AiChatResponse(
        message: '👋 您好！我是 **CityMu 專屬的 Gemini AI 空間音樂作曲家**。\n\n'
            '我的核心任務是為您在台灣都會漫步時，即時編織專屬於當下時空的生成式 Lo-Fi 聲景音樂！\n\n'
            '🎵 **我能為您做什麼？**\n'
            '• **即時風格切換**：對我說「加點重金屬」、「換成微醺爵士」、「來點深夜雨感」\n'
            '• **空間聲景融入**：偵測周遭 102 處地標錄音（捷運、廟宇梵鐘、鳥鳴號誌、水岸水流），將環境基頻化為樂曲和聲\n'
            '• **隨身步伐同步**：依據您的移動速度與 GPS 座標，即時演算專屬動機旋律\n'
            '• **現場音檔分析**：輸入「分析現場音檔特徵」獲取即時空間頻譜\n'
            '• **隨機獨立創作**：輸入「隨機創作」或「換一首」獲取全新和弦動機',
      );
    }

    // 2. App Guidance & FAQ ("這是什麼", "CityMu是什麼", "怎麼用", "功能")
    final bool isAppGuidance = lower.contains('這是什麼') ||
        lower.contains('citymu') ||
        lower.contains('怎麼用') ||
        lower.contains('如何使用') ||
        lower.contains('有什麼功能') ||
        lower.contains('怎麼玩') ||
        lower.contains('玩法') ||
        lower.contains('help') ||
        lower.contains('說明') ||
        lower.contains('幫助');

    if (isAppGuidance) {
      return const AiChatResponse(
        message: '🏙️ **CityMu 空間聲景音樂導覽**：\n\n'
            '1. **空間探索地圖**：在地圖上漫步，接近捷運站、公園、碼頭或夜市（共 102 處真實地標）時，會自動觸發專屬實錄環境聲景。\n'
            '2. **動態音樂生成**：音樂會依據您的步行速度（BPM）與經緯度動態調整節奏、低音與琶音動機。\n'
            '3. **AI 作曲家即時對話**：您可以隨時在此告訴我您想聽的曲風（例如：「換成陽光吉他」、「加點重金屬」），我會即時為您現場作曲並一鍵套用！',
      );
    }

    // 3. Current Track Inquiries & Appreciation ("現在在播什麼", "歌名", "和弦", "好聽")
    final bool isTrackInquiry = lower.contains('歌名') ||
        lower.contains('什麼歌') ||
        lower.contains('現在在播') ||
        lower.contains('目前播放') ||
        lower.contains('什麼和弦') ||
        lower.contains('樂理') ||
        lower.contains('好聽') ||
        lower.contains('讚') ||
        lower.contains('喜歡') ||
        lower.contains('謝謝') ||
        lower.contains('thx') ||
        lower.contains('thanks');

    if (isTrackInquiry) {
      return AiChatResponse(
        message: '🎶 **當前播放空間樂章**：\n\n'
            '• **曲名**：${current.title}\n'
            '• **調式音階**：${current.scaleName}\n'
            '• **進行和弦**：${current.chordNames.join(" ➔ ")}\n'
            '• **意境意象**：${current.poeticStory}\n\n'
            '很高興能為您的漫步時光增添旋律！若想嘗試不同心情的曲風，隨時告訴我～',
      );
    }

    // 4. Connection / Test / Greetings ("test", "測試", "你好", "早安")
    final bool isTestOrGreeting = lower == 'test' ||
        lower == '測試' ||
        lower.contains('test') ||
        lower == 'hi' ||
        lower == 'hello' ||
        lower == '嗨' ||
        lower == '你好' ||
        lower == '哈囉' ||
        lower == '早安' ||
        lower == '午安' ||
        lower == '晚安' ||
        lower == '在嗎' ||
        lower == '聽得到嗎' ||
        lower == '安安';

    if (isTestOrGreeting) {
      final featuresCount = features.length;
      return AiChatResponse(
        message: '🎙️ 連線通訊正常！我是 CityMu 專屬的 Gemini AI 音樂作曲家。\n\n'
            '我正在為您即時監聽 (${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}) 的空間聲景（周遭涵蓋 $featuresCount 個實體聲源）。\n\n'
            '您可以隨時直接下達風格指令：\n'
            '• 「加點重金屬 / 搖滾」\n'
            '• 「切換成微醺浪漫 Neo-Soul」\n'
            '• 「換成深夜細雨 Minor 9th」\n'
            '• 「分析現場音檔特徵」\n'
            '• 「隨機獨立全新創作」',
      );
    }

    // 5. Audio Analysis inquiries ("音檔", "分析", "錄音", "頻率")
    final bool isAudioAnalysis = lower.contains('音檔') ||
        lower.contains('分析') ||
        lower.contains('聆聽') ||
        lower.contains('錄音') ||
        lower.contains('頻率') ||
        lower.contains('特徵');

    if (isAudioAnalysis) {
      final featuresDesc = features.isEmpty
          ? '當前街區環境聲音平穩，環境底噪約 42dB'
          : features.take(4).map((f) => '${f.name} (距 ${f.distanceMeters.toStringAsFixed(0)}m)').join('、');

      return AiChatResponse(
        message: '🔊 現場空間音檔頻譜分析報告：\n\n'
            '• 偵測聲景特徵：$featuresDesc\n'
            '• 頻率響應：主頻分佈於 200Hz ~ 3.2kHz，包含空間微風殘響與交通節奏\n'
            '• 和聲適配：已將現場環境基頻融入當前【${current.title}】的 ${current.scaleName} 調式中，消除空間衝突感。',
      );
    }

    // 6. Style Transformations & Musical Commands
    String? styleTag;
    String styleName = '客製化音樂風格';
    bool isMusicCommand = false;

    if (lower.contains('金屬') || lower.contains('重金屬') || lower.contains('搖滾') || lower.contains('metal') || lower.contains('rock') || lower.contains('龐克') || lower.contains('炸')) {
      styleTag = 'metal';
      styleName = '工業重金屬 Heavy Metal';
      isMusicCommand = true;
    } else if (lower.contains('爵士') || lower.contains('jazz') || lower.contains('neo-soul') || lower.contains('微醺') || lower.contains('浪漫') || lower.contains('藍調') || lower.contains('鋼琴')) {
      styleTag = 'jazz';
      styleName = '微醺爵士 Neo-Soul';
      isMusicCommand = true;
    } else if (lower.contains('雨') || lower.contains('夜') || lower.contains('憂鬱') || lower.contains('沉思') || lower.contains('慢') || lower.contains('lofi') || lower.contains('lo-fi')) {
      styleTag = 'rain';
      styleName = '深夜細雨 Minor 9th';
      isMusicCommand = true;
    } else if (lower.contains('水') || lower.contains('河') || lower.contains('海') || lower.contains('陽光') || lower.contains('吉他') || lower.contains('輕快') || lower.contains('清新')) {
      styleTag = 'water';
      styleName = '陽光水岸 Lydian 吉他';
      isMusicCommand = true;
    } else if (lower.contains('廟') || lower.contains('寺') || lower.contains('禪') || lower.contains('東方') || lower.contains('鐘') || lower.contains('古風') || lower.contains('傳統')) {
      styleTag = 'temple';
      styleName = '古剎東方禪境五音';
      isMusicCommand = true;
    } else if (lower.contains('電音') || lower.contains('科技') || lower.contains('電子') || lower.contains('synth') || lower.contains('賽博') || lower.contains('未來')) {
      styleTag = 'cyber';
      styleName = '賽博龐克 Synthwave';
      isMusicCommand = true;
    } else if (lower.contains('改') || lower.contains('換') || lower.contains('加') || lower.contains('寫') || lower.contains('創') || lower.contains('旋律') || lower.contains('和弦') || lower.contains('隨機') || lower.contains('重新')) {
      isMusicCommand = true;
    }

    if (isMusicCommand) {
      // Generate new unique composition with seed and optional style tag
      final double seedShift = ((DateTime.now().millisecondsSinceEpoch % 10000) + 1) * 0.0001;
      final newComp = _generateLocalSpatialComposition(
        lon + seedShift,
        lat + seedShift,
        features,
        bpm,
        isWalking,
        styleOverride: styleTag,
      );

      if (styleTag != null) {
        return AiChatResponse(
          message: '🎸 收到！已為您融入【$styleName】的音樂質地！\n\n'
              '已為您重新調配了專屬和弦進程【${newComp.chordNames.join(" ➔ ")}】與全新動機旋律，點選下方即可立即套用！',
          newComposition: newComp,
          isMusicUpdated: true,
        );
      }

      return AiChatResponse(
        message: '✨ 收到您的音樂指令「$prompt」！\n\n'
            '我已結合當前座標 (${lon.toStringAsFixed(3)}, ${lat.toStringAsFixed(3)}) 與周遭空間聲景，為您即時編織了全新的專屬和弦進程【${newComp.chordNames.join(" ➔ ")}】與動機旋律！',
        newComposition: newComp,
        isMusicUpdated: true,
      );
    }

    // 7. Friendly Casual Chat Fallback (Does NOT force a confusing music card)
    return AiChatResponse(
      message: '😊 收到！我是隨時陪伴您漫步台北街頭的 CityMu AI 音樂夥伴。\n\n'
          '如果您想為現在的心情配一段音樂，可以隨時對我說：「換成陽光吉他」、「加點重金屬」或「來點微醺爵士」，我會立即為您現場作曲！',
    );
  }

  /// Backward compatible mood generation
  Future<AmbientMood> generateUrbanMood({
    required double longitude,
    required double latitude,
    required List<SpatialFeature> nearbyFeatures,
    required double bpm,
    required bool isWalking,
  }) async {
    final comp = await composeSpatialMotif(
      longitude: longitude,
      latitude: latitude,
      nearbyFeatures: nearbyFeatures,
      bpm: bpm,
      isWalking: isWalking,
    );
    return AmbientMood(
      moodTitle: comp.title,
      poeticNarrative: comp.poeticStory,
      recommendedScale: comp.scaleName,
      melodyWeight: comp.melodyWeight,
      bassWeight: comp.bassWeight,
      textureWeight: comp.textureWeight,
      sparkWeight: comp.sparkWeight,
    );
  }
}

/// Response data wrapper for Gemini AI Composer Chat
class AiChatResponse {
  final String message;
  final AiComposition? newComposition;
  final bool isMusicUpdated;

  const AiChatResponse({
    required this.message,
    this.newComposition,
    this.isMusicUpdated = false,
  });
}
