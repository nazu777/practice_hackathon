import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Backend / Logic Imports (From Main)
import 'services/background_service.dart';
import 'services/local_db.dart';
import 'screens/assessment_form.dart';
import 'screens/dashboard_screen.dart';

// Frontend / UI Imports (From your Branch)
import 'screens/auth_gate.dart';
import 'core/theme.dart';

void main() async {
  // Keep the backend initialization logic from Incoming (Left)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 1. Fire off the UI immediately
  runApp(
    const ProviderScope(
      child: PulseEdgeApp(),
    ),
  );

  // 2. Start the heavy background stuff *after* the UI is requested
  _initServices();
}

/// Helper to run background init (From Main)
Future<void> _initServices() async {
  try {
    await Permission.notification.request();
    await initBackgroundService();
  } catch (e) {
    debugPrint("Service Init Error: $e");
  }
}

class PulseEdgeApp extends StatelessWidget {
  const PulseEdgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse Edge',
      debugShowCheckedModeBanner: false,

      // 🔥 Using your Branch's UI/Theme logic
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Keep your Branch's routing structure
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        // You can integrate the Main branch's screens here later:
        '/dashboard': (_) => const DashboardScreen(),
        '/form': (_) => const AssessmentFormScreen(),
      },

      // 🔥 Keep your Branch's UX improvements
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child!,
        );
      },
    );
  }
}