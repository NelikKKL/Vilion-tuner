import 'dart:math';
import 'dart:typed_data';

/// YIN pitch detection algorithm.
/// Reference: "YIN, a fundamental frequency estimator for speech and music"
/// de Cheveigné & Kawahara, 2002.
class YinPitchDetector {
  final int sampleRate;
  final double threshold;
  final int bufferSize;

  YinPitchDetector({
    required this.sampleRate,
    this.threshold = 0.15, // Lower = more sensitive, higher = more stable
    this.bufferSize = 2048,
  });

  /// Detect pitch from a PCM float buffer.
  /// Returns frequency in Hz, or -1 if no pitch detected.
  double getPitch(Float32List buffer) {
    final halfBuffer = bufferSize ~/ 2;
    final yinBuffer = Float32List(halfBuffer);

    // Step 1: Difference function
    _differenceFunction(buffer, yinBuffer, halfBuffer);

    // Step 2: Cumulative mean normalized difference
    _cumulativeMeanNormalizedDifference(yinBuffer, halfBuffer);

    // Step 3: Absolute threshold
    final tauEstimate = _absoluteThreshold(yinBuffer, halfBuffer);

    if (tauEstimate == -1) return -1;

    // Step 4: Parabolic interpolation for better accuracy
    final betterTau = _parabolicInterpolation(yinBuffer, tauEstimate, halfBuffer);

    return sampleRate / betterTau;
  }

  void _differenceFunction(Float32List buffer, Float32List yinBuffer, int halfBuffer) {
    for (int tau = 0; tau < halfBuffer; tau++) {
      yinBuffer[tau] = 0;
    }

    for (int tau = 1; tau < halfBuffer; tau++) {
      for (int j = 0; j < halfBuffer; j++) {
        final delta = buffer[j] - buffer[j + tau];
        yinBuffer[tau] += delta * delta;
      }
    }
  }

  void _cumulativeMeanNormalizedDifference(Float32List yinBuffer, int halfBuffer) {
    yinBuffer[0] = 1.0;
    double runningSum = 0.0;

    for (int tau = 1; tau < halfBuffer; tau++) {
      runningSum += yinBuffer[tau];
      if (runningSum == 0) {
        yinBuffer[tau] = 1.0;
      } else {
        yinBuffer[tau] *= tau / runningSum;
      }
    }
  }

  int _absoluteThreshold(Float32List yinBuffer, int halfBuffer) {
    for (int tau = 2; tau < halfBuffer; tau++) {
      if (yinBuffer[tau] < threshold) {
        // Find local minimum
        while (tau + 1 < halfBuffer && yinBuffer[tau + 1] < yinBuffer[tau]) {
          tau++;
        }
        return tau;
      }
    }
    return -1;
  }

  double _parabolicInterpolation(Float32List yinBuffer, int tauEstimate, int halfBuffer) {
    final x0 = tauEstimate < 1 ? tauEstimate : tauEstimate - 1;
    final x2 = tauEstimate + 1 < halfBuffer ? tauEstimate + 1 : tauEstimate;

    if (x0 == tauEstimate) {
      return yinBuffer[tauEstimate] <= yinBuffer[x2]
          ? tauEstimate.toDouble()
          : x2.toDouble();
    }
    if (x2 == tauEstimate) {
      return yinBuffer[tauEstimate] <= yinBuffer[x0]
          ? tauEstimate.toDouble()
          : x0.toDouble();
    }

    final s0 = yinBuffer[x0];
    final s1 = yinBuffer[tauEstimate];
    final s2 = yinBuffer[x2];

    return tauEstimate + (s2 - s0) / (2 * (2 * s1 - s2 - s0));
  }

  /// Convert raw 16-bit PCM bytes to normalized Float32List
  static Float32List pcmBytesToFloat32(Uint8List bytes) {
    final samples = bytes.length ~/ 2;
    final floats = Float32List(samples);
    final byteData = ByteData.sublistView(bytes);

    for (int i = 0; i < samples; i++) {
      final int16 = byteData.getInt16(i * 2, Endian.little);
      floats[i] = int16 / 32768.0; // Normalize to -1.0 .. 1.0
    }

    return floats;
  }

  /// RMS energy of the buffer — used to gate silence
  static double rms(Float32List buffer) {
    double sum = 0;
    for (final s in buffer) {
      sum += s * s;
    }
    return sqrt(sum / buffer.length);
  }
}
