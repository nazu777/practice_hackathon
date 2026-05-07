import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';
import 'assessment_form.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final hasProfileAsync = ref.watch(hasProfileProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const OnboardingScreen();
        } else {
          return hasProfileAsync.when(
            data: (hasProfile) {
              if (hasProfile) {
                return const DashboardScreen();
              } else {
                return const AssessmentFormScreen();
              }
            },
            loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator())),
            error: (e, st) => Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Error loading profile: $e', style: const TextStyle(color: Colors.white)))),
          );
        }
      },
      loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Auth Error: $e', style: const TextStyle(color: Colors.white)))),
    );
  }
}
