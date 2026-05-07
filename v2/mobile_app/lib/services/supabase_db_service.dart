import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as app_model;

class SupabaseDBService {
  static SupabaseClient get _client => Supabase.instance.client;

  // Sync user profile to Supabase
  static Future<void> syncUserProfile(app_model.User user, {double? currentRisk}) async {
    try {
      await _client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'current_risk': currentRisk,
      });
    } catch (e) {
      print('SUPABASE ERROR (syncUserProfile): $e');
    }
  }

  // Sync health parameters to Supabase
  static Future<void> syncHealthParameters({
    required String userId,
    required List<double> parameters,
  }) async {
    try {
      await _client.from('health_parameters').upsert({
        'user_id': userId,
        'age': parameters[0],
        'sex': parameters[1],
        'chest_pain_type': parameters[2],
        'resting_bp': parameters[3],
        'cholesterol': parameters[4],
        'fasting_bs': parameters[5],
        'resting_ecg': parameters[6],
        'max_hr': parameters[7],
        'exercise_angina': parameters[8],
        'oldpeak': parameters[9],
        'st_slope': parameters[10],
      });
    } catch (e) {
      print('SUPABASE ERROR (syncHealthParameters): $e');
    }
  }

  // Sync risk score to Supabase
  static Future<void> syncRiskHistory({
    required String userId,
    required double riskScore,
    required List<double> parameters,
  }) async {
    try {
      await _client.from('risk_history').insert({
        'user_id': userId,
        'risk_score': riskScore,
        'parameters': parameters,
      });
    } catch (e) {
      print('SUPABASE ERROR (syncRiskHistory): $e');
    }
  }

  // Sync rating to Supabase
  static Future<void> syncRating({
    required String userId,
    required int stars,
  }) async {
    await _client.from('ratings').upsert(
      {
        'user_id': userId,
        'stars': stars,
      },
      onConflict: 'user_id',
    );
  }

  // Get user's health parameters from Supabase (for backup/restore)
  static Future<Map<String, dynamic>?> getHealthParameters(String userId) async {
    try {
      final response = await _client
          .from('health_parameters')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('Failed to get health parameters: $e');
      return null;
    }
  }

  // Get user's risk history from Supabase
  static Future<List<Map<String, dynamic>>> getRiskHistory(String userId) async {
    try {
      final response = await _client
          .from('risk_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List<dynamic>);
    } catch (e) {
      print('Failed to get risk history: $e');
      return [];
    }
  }
}