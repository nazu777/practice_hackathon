import 'dart:math';
import '../core/constants.dart';

// ================================================================
// PulseEdge — Sensor Math Library
// Merged Version: Combines Member 3's class structure 
// with Member 4's constants and clamping logic.
// ================================================================

class SensorMath {
  
  /// FUNCTION 1: Calculate Dynamic Signal Vector Magnitude
  static double calculateSVM(double ax, double ay, double az) {
    // Convert m/s² to g-force
    final double axG = ax / 9.8;
    final double ayG = ay / 9.8;
    final double azG = az / 9.8;

    // Calculate total vector magnitude
    final double totalMagnitude = sqrt(axG * axG + ayG * ayG + azG * azG);

    // Subtract 1g to remove constant gravity component
    final double dynamicSVM = totalMagnitude - 1.0;

    // Clamp at 0 — negative values are just noise when still.
    // (Better than Shrihari's .abs() which turns downward freefall into positive spikes)
    return dynamicSVM < 0.0 ? 0.0 : dynamicSVM;
  }

  /// FUNCTION 2: Normalize SVM to 0.0–1.0
  static double normalizeSVM(double rawSVM) {
    // Using Member 4's shared constant instead of Shrihari's hardcoded 2.0
    final double normalized = rawSVM / MAX_EXPECTED_SVM;
    
    // Using Shrihari's clean .clamp() syntax
    return normalized.clamp(0.0, 1.0);
  }

  /// FUNCTION 3: Compute Average of a List of Samples
  static double computeAverage(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    return samples.reduce((a, b) => a + b) / samples.length;
  }

  /// FUNCTION 4: Classify Activity from Intensity Value
  /// Shrihari forgot this, but Member 4 remembered we need it!
  static String classifyActivity(double intensity) {
    if (intensity <= INTENSITY_SITTING_MAX) return ACTIVITY_SITTING;
    if (intensity <= INTENSITY_WALKING_MAX) return ACTIVITY_WALKING;
    return ACTIVITY_RUNNING;
  }
}