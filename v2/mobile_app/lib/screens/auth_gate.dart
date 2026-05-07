import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../core/error_handler.dart';
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
            loading: () => const _LoadingScreen(),
            error: (e, st) => _ErrorScreen(
              message: ErrorHandler.getMessage(e),
              onRetry: () => ref.invalidate(hasProfileProvider),
            ),
          );
        }
      },
      loading: () => const _LoadingScreen(),
      error: (e, st) => _ErrorScreen(
        message: ErrorHandler.getMessage(e),
        onRetry: () => ref.invalidate(authStateProvider),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );
  }
}

class _ErrorScreen extends ConsumerWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 24),
              Text(
                'Oops!',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again'),
              ),
              TextButton(
                onPressed: () => ref.read(authStateProvider.notifier).signOut(),
                child: const Text('Go Back', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
