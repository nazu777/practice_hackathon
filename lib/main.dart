import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/onboarding_screen.dart';
import 'core/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PulseEdgeApp(),
    ),
  );
}

class PulseEdgeApp extends StatelessWidget {
  const PulseEdgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse Edge',
      debugShowCheckedModeBanner: false,

      // 🔥 Theme
      theme: AppTheme.darkTheme,

      // 🔥 Smooth transitions
      themeMode: ThemeMode.dark,

      // 🔥 Future-ready navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        // later you can add:
        // '/dashboard': (_) => const DashboardScreen(),
        // '/form': (_) => const AssessmentForm(),
      },

      // 🔥 Better UX (keyboard dismiss globally)
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child!,
        );
      },
    );
  }
}