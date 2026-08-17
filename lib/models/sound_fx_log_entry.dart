/// Model representing a real-time Sound FX & DSP adjustment log entry in CityMu.
class SoundFxLogEntry {
  final DateTime timestamp;
  final String category; // e.g. '🚇 捷運聲景', '🏮 廟宇聲景', '🎹 合成器 Pad', '🥁 節奏鼓組', '🏪 都會日常', '🍃 自然生態'
  final String soundName; // e.g. 'C381 關門警報', '青銅梵鐘', 'Rhodes Dmaj7', 'Kick Drum'
  final String dspDetails; // e.g. '調音: +3 Semitones (1.189x) | 低通: 2600Hz | 音量: 32%'
  final double volume;
  final double? playbackRate;
  final int? semitone;
  final String? chord;
  final String? stepInfo; // e.g. 'Bar 1, Step 0'

  const SoundFxLogEntry({
    required this.timestamp,
    required this.category,
    required this.soundName,
    required this.dspDetails,
    required this.volume,
    this.playbackRate,
    this.semitone,
    this.chord,
    this.stepInfo,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = (timestamp.millisecond ~/ 100).toString();
    return '$h:$m:$s.$ms';
  }
}
