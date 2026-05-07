import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _apiHost = String.fromEnvironment('API_HOST', defaultValue: '');

  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for desktop, and override with --dart-define on physical devices.
  static String get baseUrl {
    if (_apiHost.isNotEmpty) {
      return '$_apiHost/api/auth';
    }

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/auth';
    }

    return 'http://127.0.0.1:5000/api/auth';
  }

  static const String _tokenKey = 'auth_token';
  
  // Current User memory cache
  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> init() async {
    await checkAuthStatus();
  }

  // Check Auth Status (equivalent to Firebase authStateChanges on load)
  Future<User?> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null) {
      _currentUser = null;
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = User.fromJson(data['user']);
        return _currentUser;
      } else {
        await signOut();
        return null;
      }
    } catch (e) {
      debugPrint("Check Auth Error: $e");
      return null;
    }
  }

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        
        _currentUser = User.fromJson(data['user']);
        return _currentUser;
      } else {
        throw Exception(data['message'] ?? 'Failed to sign in');
      }
    } catch (e) {
      debugPrint("Sign In Error: $e");
      rethrow;
    }
  }

  // Sign Up
  Future<User?> signUp(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        
        _currentUser = User.fromJson(data['user']);
        return _currentUser;
      } else {
        throw Exception(data['message'] ?? 'Failed to sign up');
      }
    } catch (e) {
      debugPrint("Sign Up Error: $e");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      _currentUser = null;
    } catch (e) {
      debugPrint("Sign Out Error: $e");
    }
  }
}
