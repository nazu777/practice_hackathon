import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'sensor_math.dart';
import '../core/constants.dart';

// ================================================================
// Called once at app startup (from main.dart)
// ================================================================
Future<void> initBackgroundService() async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      print('Notification permission denied.');
      return;
    }
  }

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'pulse_edge_channel',
    'PulseEdge Background Service',
    description: 'Continuously monitoring your heart health.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'pulse_edge_channel',
      initialNotificationTitle: 'PulseEdge',
      initialNotificationContent: 'Monitoring your heart health...',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

// ================================================================
// BACKGROUND ISOLATE LOGIC (Merged Member 3 + Member 4)
// ================================================================
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 🟢 REQUIRED: Keeps Android 15 from crashing
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  final List<double> svmBuffer = [];


  // 🟢 ADD THIS: A tracker for our throttle
  DateTime lastUIUpdate = DateTime.now();
  
  // 1. Listen to raw accelerometer events continuously
  accelerometerEvents.listen((AccelerometerEvent event) {
    // Calculate using the new SensorMath class
    final double rawSVM = SensorMath.calculateSVM(event.x, event.y, event.z);
    final double normalized = SensorMath.normalizeSVM(rawSVM);
    
    svmBuffer.add(normalized);

    // 🟢 THROTTLE: Only send to the UI every 200 milliseconds (5x a second)
    final now = DateTime.now();
    if (now.difference(lastUIUpdate).inMilliseconds > 200) {
      service.invoke('updateIntensity', {"intensity": normalized});
      lastUIUpdate = now;
    }
  });

  // 2. Every 10 seconds, calculate average for classification
  Timer.periodic(const Duration(seconds: SENSOR_WINDOW_SECONDS), (timer) {
    if (svmBuffer.isNotEmpty) {
      final double avgIntensity = SensorMath.computeAverage(svmBuffer);
      
      // 🟢 MEMBER 4'S ADDITION: Don't forget to classify the activity!
      final String activity = SensorMath.classifyActivity(avgIntensity);

      // Send the averaged "stabilized" data to the UI/Alert logic
      service.invoke('updateStabilizedIntensity', {
        'average': avgIntensity,
        'activity': activity,
      });

      svmBuffer.clear(); // Reset for the next 10 seconds
    }
  });
}