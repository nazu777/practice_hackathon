import 'dart:math';
import '../core/constants.dart';

// ================================================================
// PulseEdge — Sensor Math Library
// Member 3 owns this file entirely.
// These are PURE FUNCTIONS — no Flutter, no Riverpod, no async.
// They can be unit tested completely independently.
// ================================================================

/// FUNCTION 1: Calculate Dynamic Signal Vector Magnitude
///
/// Takes raw accelerometer values (in m/s²) from sensors_plus.
/// Converts to g-force, computes vector magnitude, removes gravity.
///
/// Why subtract 1.0?
/// A phone sitting perfectly still still reads ~9.8 m/s² (1g) on one axis
/// because gravity is always pulling on it.
/// Subtracting 1.0 removes this constant gravity so we only measure MOVEMENT.
///
/// Example:
///   Phone sitting still → SVM ≈ 0.0
///   Phone being carried → SVM ≈ 0.3–0.8
///   Phone during sprint  → SVM ≈ 1.5–2.5
double calculateSVM(double ax, double ay, double az) {
  // Step 1: Convert m/s² to g-force by dividing by 9.8
  final double axG = ax / 9.8;
  final double ayG = ay / 9.8;
  final double azG = az / 9.8;

  // Step 2: Calculate total vector magnitude (Pythagorean theorem in 3D)
  final double totalMagnitude = sqrt(axG * axG + ayG * ayG + azG * azG);

  // Step 3: Subtract 1g to remove constant gravity component
  final double dynamicSVM = totalMagnitude - 1.0;

  // Step 4: Clamp at 0 — negative values are just noise when still
  return dynamicSVM < 0.0 ? 0.0 : dynamicSVM;
}

/// FUNCTION 2: Normalize SVM to 0.0–1.0
///
/// Raw SVM values can go above 1.0 during vigorous activity.
/// We scale it against MAX_EXPECTED_SVM (2.5) defined in constants.dart.
/// Result is always clamped between 0.0 and 1.0.
///
/// Example:
///   rawSVM = 0.0  → 0.0  (sitting still)
///   rawSVM = 1.25 → 0.5  (moderate walking)
///   rawSVM = 2.5  → 1.0  (full sprint)
///   rawSVM = 3.0  → 1.0  (clamped at max)
double normalizeSVM(double rawSVM) {
  final double normalized = rawSVM / MAX_EXPECTED_SVM;
  if (normalized < 0.0) return 0.0;
  if (normalized > 1.0) return 1.0;
  return normalized;
}

/// FUNCTION 3: Compute Average of a List of Samples
///
/// Collects raw sensor readings over 10 seconds, then averages them.
/// This smooths out sudden spikes (e.g., phone being picked up).
///
/// Example:
///   samples = [0.1, 0.15, 0.12, 0.18, 0.13] → 0.136
double computeAverage(List<double> samples) {
  if (samples.isEmpty) return 0.0;
  final double sum = samples.reduce((a, b) => a + b);
  return sum / samples.length;
}

/// FUNCTION 4: Classify Activity from Intensity Value
///
/// Maps the 0.0–1.0 intensity to a human-readable activity label.
/// Thresholds come from constants.dart so everyone uses the same values.
///
/// Ranges (from constants.dart):
///   0.00–0.20 → SITTING
///   0.21–0.60 → WALKING
///   0.61–1.00 → RUNNING
String classifyActivity(double intensity) {
  if (intensity <= INTENSITY_SITTING_MAX) return ACTIVITY_SITTING;
  if (intensity <= INTENSITY_WALKING_MAX) return ACTIVITY_WALKING;
  return ACTIVITY_RUNNING;
}