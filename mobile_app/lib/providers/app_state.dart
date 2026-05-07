import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';

// ================================================================
// LIVE VALUES (Modern Notifier + Stream Adapter Architecture)
// ================================================================

class RiskNotifier extends Notifier<double> {
  @override
  double build() => 0.0; 
  
  void setRisk(double value) => state = value; 
}
final riskProvider = NotifierProvider<RiskNotifier, double>(RiskNotifier.new);

// 🔥 NEW: Modern Notifier for Dismiss State (Replaces deprecated StateProvider)
class DismissNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setDismissed(bool value) => state = value;
}
final isDismissedProvider = NotifierProvider<DismissNotifier, bool>(DismissNotifier.new);

// ================================================================
// BACKGROUND SERVICE STREAMS
// ================================================================

final _liveStreamProvider = StreamProvider<double>((ref) {
  return FlutterBackgroundService()
      .on('updateIntensity')
      .map((event) => (event?['intensity'] as num?)?.toDouble() ?? 0.0);
});

final _stabilizedStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FlutterBackgroundService()
      .on('updateStabilizedIntensity')
      .map((event) => {
            'average': (event?['average'] as num?)?.toDouble() ?? 0.0,
            'activity': event?['activity'] as String? ?? ACTIVITY_SITTING,
          });
});

// ================================================================
// UI-FACING PROVIDERS
// ================================================================

final intensityProvider = Provider<double>((ref) {
  return ref.watch(_liveStreamProvider).value ?? 0.0;
});

final activityProvider = Provider<String>((ref) {
  final data = ref.watch(_stabilizedStreamProvider).value;
  return data?['activity'] as String? ?? ACTIVITY_SITTING;
});

final stabilizedIntensityProvider = Provider<double>((ref) {
  final data = ref.watch(_stabilizedStreamProvider).value;
  return (data?['average'] as double?) ?? 0.0;
});

final strainProductProvider = Provider<double>((ref) {
  final risk = ref.watch(riskProvider);
  final data = ref.watch(_stabilizedStreamProvider).value;
  final averageIntensity = data?['average'] as double? ?? 0.0;
  
  return risk * averageIntensity;
});

final alertLevelProvider = Provider<String>((ref) {
  final risk = ref.watch(riskProvider);
  final product = ref.watch(strainProductProvider);

  if (product > STRAIN_ELEVATED_MAX || risk >= 0.80) return ALERT_CRITICAL;
  if (product > STRAIN_STABLE_MAX   || risk >= 0.60) return ALERT_ELEVATED;
  
  return ALERT_STABLE;
});