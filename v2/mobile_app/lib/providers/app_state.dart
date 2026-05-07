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

class MockSensorEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setMock(bool value) => state = value;
}
final mockSensorEnabledProvider = NotifierProvider<MockSensorEnabledNotifier, bool>(MockSensorEnabledNotifier.new);

// Listens to the 10x/sec live feed for the chart
final _liveStreamProvider = StreamProvider<double>((ref) {
  final isMock = ref.watch(mockSensorEnabledProvider);
  if (isMock) {
    return Stream.periodic(const Duration(milliseconds: 100), (count) {
      // Simulate sitting, walking, running bursts
      double base = 0.1;
      if (count % 300 > 200) base = 0.8; // Burst
      else if (count % 300 > 100) base = 0.3; // Walk
      return base + (DateTime.now().millisecond / 10000.0); // Add jitter
    });
  }

  return FlutterBackgroundService()
      .on('updateIntensity')
      .map((event) => (event?['intensity'] as num?)?.toDouble() ?? 0.0);
});

// Listens to the 10-second stabilized feed for the alerts
final _stabilizedStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final isMock = ref.watch(mockSensorEnabledProvider);
  if (isMock) {
    return Stream.periodic(const Duration(seconds: 10), (count) {
      double avg = 0.1;
      String act = ACTIVITY_SITTING;
      if (count % 30 > 20) { avg = 0.8; act = ACTIVITY_RUNNING; }
      else if (count % 30 > 10) { avg = 0.3; act = ACTIVITY_WALKING; }
      return {'average': avg, 'activity': act};
    });
  }

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
  final product = ref.watch(strainProductProvider);

  if (product <= STRAIN_STABLE_MAX)   return ALERT_STABLE;
  if (product <= STRAIN_ELEVATED_MAX) return ALERT_ELEVATED;
  return ALERT_CRITICAL;
});