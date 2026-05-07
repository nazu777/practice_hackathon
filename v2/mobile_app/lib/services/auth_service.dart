import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as app_model;

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  app_model.User? _currentUser;
  
  app_model.User? get currentUser {
    if (_currentUser != null) return _currentUser;
    
    // Fallback to current session if local variable is null
    final user = _client.auth.currentUser;
    if (user != null) {
      _currentUser = app_model.User(id: user.id, email: user.email ?? '');
    }
    return _currentUser;
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<app_model.User?> init() async {
    return await checkAuthStatus();
  }

  Future<app_model.User?> checkAuthStatus() async {
    final session = _client.auth.currentSession;
    final supabaseUser = session?.user;
    if (supabaseUser == null) {
      _currentUser = null;
      return null;
    }

    _currentUser = app_model.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
    );
    return _currentUser;
  }

  Future<StreamSubscription<AuthState>> onAuthStateChange(
    void Function(AuthChangeEvent event, Session? session) callback,
  ) async {
    return _client.auth.onAuthStateChange.listen((authState) {
      final event = authState.event;
      final session = authState.session;
      final supabaseUser = session?.user;
      if (event == AuthChangeEvent.signedIn && supabaseUser != null) {
        _currentUser = app_model.User(
          id: supabaseUser.id,
          email: supabaseUser.email ?? '',
        );
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
      }
      callback(event, session);
    });
  }

  Future<app_model.User?> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final supabaseUser = response.user ?? response.session?.user;
    if (supabaseUser == null) {
      throw Exception('Login failed. Please try again.');
    }

    _currentUser = app_model.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
    );

    // Sync profile on login to ensure public.users is populated
    try {
      await _client.from('users').upsert({
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('SUPABASE ERROR (signIn sync): $e');
    }

    return _currentUser;
  }

  Future<app_model.User?> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final supabaseUser = response.user ?? response.session?.user;
    if (supabaseUser == null) {
      throw Exception('Signup failed. Please check your email and password.');
    }

    _currentUser = app_model.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
    );

    try {
      // Use upsert instead of insert to avoid errors if the user profile already exists
      await _client.from('users').upsert({
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Profile sync error: $e');
      // Ignore secondary sync errors so auth still works.
    }

    return _currentUser;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _currentUser = null;
  }
}
