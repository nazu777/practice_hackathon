import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/assessment_form.dart';
import 'services/background_service.dart';
import 'services/local_db.dart';
import 'screens/dashboard_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Fire off the UI immediately (No await here!)
  runApp(
    const ProviderScope(
      child: PulseEdgeApp(),
    ),
  );

  // 2. Start the heavy background stuff *after* the UI is requested
  // We remove the 'await' from the permission and service init 
  // so they don't hold up the main thread.
  _initServices();
}



/// Helper to run background init without blocking the UI thread
Future<void> _initServices() async {
  try {
    // Request permission silently
    await Permission.notification.request();
    // Initialize the background engine
    await initBackgroundService();
  } catch (e) {
    debugPrint("Service Init Error: $e");
  }
}

class PulseEdgeApp extends ConsumerWidget {
  const PulseEdgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PulseEdge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      // If user already filled the form, skip straight to dashboard
      home: FutureBuilder<bool>(
        future: LocalDB.hasProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == true) {
            return const DashboardScreen();
          }
          return const AssessmentFormScreen();
        },
      ),
    );
  }
}