import 'package:citymu/core/constants/audio_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Audio & DSP Pitch Shifting Tests', () {
    test('Semitone to Playback Rate Speed Conversion', () {
      // 0 semitones (Unshifted root D4) => speed = 1.0
      expect(AudioConstants.semitonesToSpeed(0), closeTo(1.0, 0.0001));

      // +12 semitones (Octave up D5) => speed = 2.0
      expect(AudioConstants.semitonesToSpeed(12), closeTo(2.0, 0.0001));

      // -12 semitones (Octave down D3) => speed = 0.5
      expect(AudioConstants.semitonesToSpeed(-12), closeTo(0.5, 0.0001));

      // +7 semitones (Perfect fifth A4) => speed = 2^(7/12) ~ 1.4983
      expect(AudioConstants.semitonesToSpeed(7), closeTo(1.4983, 0.001));
    });

    test('Pitch Shift Fallback Protection Boundary Check (|delta| > 7)', () {
      // Within limits (<= 7 semitones) => Foley primary source
      expect(AudioConstants.requiresFallback(0), isFalse);
      expect(AudioConstants.requiresFallback(2), isFalse); // E4
      expect(AudioConstants.requiresFallback(4), isFalse); // F#4
      expect(AudioConstants.requiresFallback(7), isFalse); // A4
      expect(AudioConstants.requiresFallback(-7), isFalse);

      // Beyond limit (> 7 semitones) => Fallback felt piano safeguard triggered
      expect(AudioConstants.requiresFallback(8), isTrue);
      expect(AudioConstants.requiresFallback(9), isTrue); // B4
      expect(AudioConstants.requiresFallback(12), isTrue); // D5
      expect(AudioConstants.requiresFallback(-8), isTrue);
    });

    test('D Major Pentatonic Scale Definition', () {
      final scale = AudioConstants.dMajorPentatonicSemitones;
      expect(scale, equals([0, 2, 4, 7, 9, 12]));
    });
  });
}
