import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is AuthApiException) {
      // Handle specific Supabase Auth errors
      switch (error.code) {
        case 'email_address_invalid':
          return 'The email address provided is invalid. Please check and try again.';
        case 'invalid_credentials':
          return 'Invalid email or password. Please try again.';
        case 'email_not_confirmed':
          return 'Please confirm your email address before logging in.';
        case 'user_already_exists':
          return 'An account with this email already exists.';
        case 'weak_password':
          return 'Password is too weak. Please use a stronger password.';
        case 'over_rate_limit':
          return 'Too many requests. Please wait a while before trying again.';
        default:
          return error.message;
      }
    }

    if (error is PostgrestException) {
      return 'Database error: ${error.message}';
    }

    // Fallback for other errors
    final str = error.toString();
    if (str.contains('network_error') || str.contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    }

    return str;
  }
}
