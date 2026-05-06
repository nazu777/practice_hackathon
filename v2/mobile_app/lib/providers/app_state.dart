import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';

// ================================================================
// LIVE VALUES (Modern Notifier + Stream Adapter Architecture)
// ================================================================

// 1. Static Risk (Main Branch Backend Logic)
class RiskNotifier extends Notifier<double> {
  @override
  double build() => 0.0; // Starts at 0 until form is submitted
  
  void setRisk(double value) => state = value; 
}
final riskProvider = NotifierProvider<RiskNotifier, double>(RiskNotifier.new);

// ================================================================
// BACKGROUND SERVICE STREAMS (Main Branch Internal Logic)
// ================================================================

// Listens to the 10x/sec live feed for the chart
final _liveStreamProvider = StreamProvider<double>((ref) {
  return FlutterBackgroundService()
      .on('updateIntensity')
      .map((event) => (event?['intensity'] as num?)?.toDouble() ?? 0.0);
});

// Listens to the 10-second stabilized feed for the alerts
final _stabilizedStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FlutterBackgroundService()
      .on('updateStabilizedIntensity')
      .map((event) => {
            'average': (event?['average'] as num?)?.toDouble() ?? 0.0,
            'activity': event?['activity'] as String? ?? ACTIVITY_SITTING,
          });
});

// ================================================================
// UI-FACING PROVIDERS (Keeping your Branch names for the UI)
// ================================================================

// UI watches this for the chart (intensityProvider name from your branch)
final intensityProvider = Provider<double>((ref) {
  return ref.watch(_liveStreamProvider).value ?? 0.0;
});

// UI watches this for the label (activityProvider name from your branch)
final activityProvider = Provider<String>((ref) {
  final data = ref.watch(_stabilizedStreamProvider).value;
  return data?['activity'] as String? ?? ACTIVITY_SITTING;
});

// Computed: The final strain product value (risk × stabilized intensity)
final strainProductProvider = Provider<double>((ref) {
  final risk = ref.watch(riskProvider);
  final data = ref.watch(_stabilizedStreamProvider).value;
  final averageIntensity = data?['average'] as double? ?? 0.0;
  
  return risk * averageIntensity;
});

// Computed: Alert level (alertLevelProvider name from your branch)
final alertLevelProvider = Provider<String>((ref) {
  final risk = ref.watch(riskProvider);
  final product = ref.watch(strainProductProvider);

  // If the user is physically exerting themselves to a dangerous strain level,
  // or if their baseline risk is extremely high, trigger Critical.
  if (product > STRAIN_ELEVATED_MAX || risk >= 0.80) return ALERT_CRITICAL;
  
  // If their baseline risk is moderately high, or strain is elevated, trigger Elevated.
  if (product > STRAIN_STABLE_MAX   || risk >= 0.60) return ALERT_ELEVATED;
  
  return ALERT_STABLE;
});