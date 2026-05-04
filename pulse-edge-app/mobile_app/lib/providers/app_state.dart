import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';

// ================================================================
// MOCK VALUES (hardcoded for development)
// Member 4 will replace these with real data sources later.
// Member 2: Use ref.watch() on these providers in your widgets.
// ================================================================

// Phase 1 — Static risk score from TFLite model (0.0 to 1.0)
// Member 4 will update this after running ml_service.dart inference
final riskProvider = StateProvider<double>((ref) => 0.45);

// Phase 2 — Real-time intensity from accelerometer (0.0 to 1.0)
// Member 3 will update this every 10 seconds via background service
final intensityProvider = StateProvider<double>((ref) => 0.20);

// Computed: Activity label based on current intensity
// Member 2: watch this to show SITTING / WALKING / RUNNING label
final activityProvider = Provider<String>((ref) {
  final intensity = ref.watch(intensityProvider);
  if (intensity <= INTENSITY_SITTING_MAX) return ACTIVITY_SITTING;
  if (intensity <= INTENSITY_WALKING_MAX) return ACTIVITY_WALKING;
  return ACTIVITY_RUNNING;
});

// Computed: Alert level based on risk × intensity
// Member 2: watch this to change screen color (green/yellow/red)
final alertLevelProvider = Provider<String>((ref) {
  final risk      = ref.watch(riskProvider);
  final intensity = ref.watch(intensityProvider);
  final product   = risk * intensity;

  if (product <= STRAIN_STABLE_MAX)   return ALERT_STABLE;
  if (product <= STRAIN_ELEVATED_MAX) return ALERT_ELEVATED;
  return ALERT_CRITICAL;
});

// Computed: The final strain product value (risk × intensity)
// Member 2: watch this to display the raw number on the dashboard
final strainProductProvider = Provider<double>((ref) {
  return ref.watch(riskProvider) * ref.watch(intensityProvider);
});
