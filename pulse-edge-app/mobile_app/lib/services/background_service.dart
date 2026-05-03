import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// Member 3: add your imports below this line
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'sensor_math.dart';
import '../core/constants.dart';

// ================================================================
// Called once at app startup (from main.dart)
// ================================================================
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'pulse_edge_channel',
      initialNotificationTitle: 'PulseEdge',
      initialNotificationContent: 'Monitoring your heart health...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

// ================================================================
// THIS IS WHERE MEMBER 3 PUTS THEIR LOGIC
// This function runs in a separate isolate (background thread)
// ================================================================
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

   final List<double> svmBuffer = [];

  // Listen to accelerometer events continuously
  // sensors_plus emits multiple events per second
  accelerometerEvents.listen((AccelerometerEvent event) {
    // Calculate and normalize each reading as it arrives
    final double rawSVM    = calculateSVM(event.x, event.y, event.z);
    final double normalized = normalizeSVM(rawSVM);
    svmBuffer.add(normalized);
  });

  // Every 10 seconds: average the buffer, classify, broadcast to UI
  Timer.periodic(const Duration(seconds: SENSOR_WINDOW_SECONDS), (timer) {
    if (svmBuffer.isNotEmpty) {
      final double avgIntensity = computeAverage(svmBuffer);
      final String activity     = classifyActivity(avgIntensity);

      // Send data to the Flutter UI (Member 4 listens to this)
      service.invoke('intensityUpdate', {
        'intensity': avgIntensity,
        'activity':  activity,
      });

      svmBuffer.clear();
    }
  });
}
