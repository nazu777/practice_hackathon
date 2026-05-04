import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/assessment_form.dart';
import 'services/background_service.dart';
import 'services/local_db.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start background sensor service
  await initBackgroundService();

  runApp(
    const ProviderScope(
      child: PulseEdgeApp(),
    ),
  );
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