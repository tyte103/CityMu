/// Represents the AI-generated urban mood, narrative context, and mixing weights.
class AmbientMood {
  const AmbientMood({
    required this.moodTitle,
    required this.poeticNarrative,
    required this.recommendedScale,
    required this.melodyWeight,
    required this.bassWeight,
    required this.textureWeight,
    required this.sparkWeight,
  });

  final String moodTitle;
  final String poeticNarrative;
  final String recommendedScale;
  final double melodyWeight;
  final double bassWeight;
  final double textureWeight;
  final double sparkWeight;

  factory AmbientMood.defaultMood() {
    return const AmbientMood(
      moodTitle: 'Urban Serenity',
      poeticNarrative: 'The city breathes in gentle pulses beneath the afternoon light.',
      recommendedScale: 'D Major Pentatonic',
      melodyWeight: 0.8,
      bassWeight: 0.7,
      textureWeight: 0.5,
      sparkWeight: 0.4,
    );
  }

  factory AmbientMood.fromJson(Map<String, dynamic> json) {
    return AmbientMood(
      moodTitle: json['moodTitle'] as String? ?? 'Urban Flow',
      poeticNarrative: json['poeticNarrative'] as String? ?? 'Walking through the harmonic arteries of the city.',
      recommendedScale: json['recommendedScale'] as String? ?? 'D Major Pentatonic',
      melodyWeight: (json['melodyWeight'] as num?)?.toDouble() ?? 0.8,
      bassWeight: (json['bassWeight'] as num?)?.toDouble() ?? 0.7,
      textureWeight: (json['textureWeight'] as num?)?.toDouble() ?? 0.5,
      sparkWeight: (json['sparkWeight'] as num?)?.toDouble() ?? 0.4,
    );
  }
}
