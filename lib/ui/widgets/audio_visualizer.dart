import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/audio_parameter.dart';

/// Zen Minimalist Audio Waveform Visualizer.
/// Smoothly renders dynamic sound waves responsive to the active Lo-Fi tracks.
class AudioVisualizer extends StatefulWidget {
  const AudioVisualizer({
    super.key,
    required this.audioParameter,
    this.height = 100,
  });

  final AudioParameter audioParameter;
  final double height;

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _WaveformPainter(
            animationValue: _animController.value,
            audioParameter: widget.audioParameter,
            primaryColor: Theme.of(context).colorScheme.primary,
            secondaryColor: Theme.of(context).colorScheme.secondary,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.animationValue,
    required this.audioParameter,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  final double animationValue;
  final AudioParameter audioParameter;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final isPlaying = audioParameter.isPlaying;
    const barCount = 28;
    final totalSpacing = size.width * 0.2;
    final barWidth = (size.width - totalSpacing) / barCount;
    final spacing = totalSpacing / (barCount - 1);
    final centerY = size.height / 2.0;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final normalizedX = i / (barCount - 1);
      final phase = animationValue * 2 * math.pi + (normalizedX * 4 * math.pi);

      double energy = 0.08; // Idle breathing height
      if (isPlaying) {
        final subBassFactor = audioParameter.subBassVolume * 0.4;
        final vinylFactor = audioParameter.vinylVolume * 0.2;
        final rhythmFactor = audioParameter.isRhythmActive ? 0.35 : 0.15;
        final stepEmphasis = (i % 4 == (audioParameter.stepIndex % 4)) ? 0.3 : 0.0;

        energy = 0.15 + (math.sin(phase).abs() * (0.3 + subBassFactor + vinylFactor + rhythmFactor + stepEmphasis));
      }

      final barHeight = (size.height * energy).clamp(6.0, size.height * 0.9);
      final left = i * (barWidth + spacing);
      final top = centerY - (barHeight / 2.0);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        Radius.circular(barWidth / 2.0),
      );

      // Color gradient from primary to sage
      final color = Color.lerp(primaryColor, secondaryColor, normalizedX)!
          .withValues(alpha: isPlaying ? (0.6 + energy * 0.4).clamp(0.2, 1.0) : 0.25);
      paint.color = color;

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.audioParameter != audioParameter;
  }
}
