import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/local_db.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() async {
    final authService = ref.watch(authServiceProvider);
    return await authService.checkAuthStatus();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      return await authService.signIn(email, password);
    });
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      return await authService.signUp(email, password);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      return null;
    });
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

final hasProfileProvider = FutureProvider<bool>((ref) async {
  return await LocalDB.hasProfile();
});
