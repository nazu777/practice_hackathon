import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'supabase_db_service.dart';
import 'auth_service.dart';

// ================================================================
// PulseEdge — Local SQLite Database with Supabase Sync
// Stores user profile and risk score on-device.
// Optionally syncs to Supabase for cloud backup.
// ================================================================

class LocalDB {
  static Database? _database;

  static Future<Database> get _db async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final String dbPath = join(await getDatabasesPath(), 'pulse_edge.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_profile (
            id              INTEGER PRIMARY KEY,
            age             REAL,
            sex             REAL,
            chest_pain_type REAL,
            resting_bp      REAL,
            cholesterol     REAL,
            fasting_bs      REAL,
            resting_ecg     REAL,
            max_hr          REAL,
            exercise_angina REAL,
            oldpeak         REAL,
            st_slope        REAL,
            risk_score      REAL NOT NULL,
            created_at      TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Save or overwrite the user's profile and risk score.
  /// Only one profile is kept at a time (previous is deleted).
  /// Optionally syncs to Supabase if user is authenticated.
  static Future<void> saveUserProfile({
    required List<double> rawInputs,
    required double riskScore,
  }) async {
    final db = await _db;

    // Delete existing profile (only one user per device)
    await db.delete('user_profile');

    await db.insert('user_profile', {
      'age':             rawInputs[0],
      'sex':             rawInputs[1],
      'chest_pain_type': rawInputs[2],
      'resting_bp':      rawInputs[3],
      'cholesterol':     rawInputs[4],
      'fasting_bs':      rawInputs[5],
      'resting_ecg':     rawInputs[6],
      'max_hr':          rawInputs[7],
      'exercise_angina': rawInputs[8],
      'oldpeak':         rawInputs[9],
      'st_slope':        rawInputs[10],
      'risk_score':      riskScore,
      'created_at':      DateTime.now().toIso8601String(),
    });

    // Sync to Supabase if user is authenticated
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      try {
        await SupabaseDBService.syncUserProfile(currentUser, currentRisk: riskScore);
        await SupabaseDBService.syncHealthParameters(
          userId: currentUser.id,
          parameters: rawInputs,
        );
        await SupabaseDBService.syncRiskHistory(
          userId: currentUser.id,
          riskScore: riskScore,
          parameters: rawInputs,
        );
      } catch (e) {
        print('SUPABASE ERROR (LocalDB Sync): $e');
      }
    } else {
      print('SYNC SKIPPED: No authenticated user found.');
    }
  }

  /// Load the saved risk score. Returns null if no profile exists yet.
  static Future<double?> getSavedRiskScore() async {
    final db   = await _db;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['risk_score'] as double;
  }

  /// Load the full profile
  static Future<Map<String, dynamic>?> getSavedProfile() async {
    final db   = await _db;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Returns true if the user has already filled the assessment form.
  static Future<bool> hasProfile() async {
    final db   = await _db;
    final rows = await db.query('user_profile', limit: 1);
    return rows.isNotEmpty;
  }

  /// Delete the user's profile (used for "Reset" or "Re-assess" button).
  static Future<void> clearProfile() async {
    final db = await _db;
    await db.delete('user_profile');
  }
}
