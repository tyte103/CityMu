/// Stub implementation for Native/VM platforms.
void playHtml5Audio(String assetPath, {double speed = 1.0, double volume = 0.8}) {}

void playHtml5RealMrtSample(
  String assetPath, {
  double volume = 0.35,
  double playbackRate = 1.0,
  double lowpassFreq = 2800.0,
  double offsetSeconds = 0.0,
  double? durationSeconds,
}) {}

void playHtml5Pad(List<int> semitones, {double volume = 0.6, double durationSeconds = 3.0}) {}

void playHtml5GlideNote({
  required int startSemitone,
  required int targetSemitone,
  double volume = 0.7,
  double glideDuration = 0.15,
}) {}

void playHtml5Arpeggio(List<int> semitones, {double volume = 0.6, double interval = 0.06}) {}

void playHtml5MrtJingle({double volume = 0.7}) {}

void playHtml5MrtCardTap({double volume = 0.65}) {}

void playHtml5PedestrianBird({bool isTweet = false, double volume = 0.5}) {}

void playHtml5YouBikeBell({double volume = 0.55}) {}

void playHtml5TempleBell({double volume = 0.5, bool useWoodenFish = false}) {}

void playHtml5NightMarket({double volume = 0.4, bool isPinball = false}) {}

void playHtml5CampusBell({double volume = 0.55}) {}

void playHtml5CulturalWarmth({double volume = 0.45}) {}

void playHtml5ConvenienceStore({double volume = 0.6}) {}

void playHtml5GarbageTruck({double volume = 0.55}) {}

void playHtml5BusCardSwipe({double volume = 0.65}) {}

void playHtml5Cicadas({double volume = 0.45}) {}

void playHtml5TreeFrogs({double volume = 0.5}) {}

void playHtml5Kick({double volume = 0.7}) {}

void playHtml5Snare({double volume = 0.6}) {}

void playHtml5HiHat({double volume = 0.4}) {}

void playHtml5BassNote({required int semitones, double volume = 0.7, double durationSeconds = 0.8}) {}

void setHtml5LoopAudio(String key, String assetPath, double volume) {}

void stopHtml5Audio() {}
