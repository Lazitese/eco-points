import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

/// Central access point for all Supabase operations.
class SupabaseService {
  SupabaseService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;

  // ── Auth ───────────────────────────────────────────────────────────────────

  static User? get currentUser => _client.auth.currentUser;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    // Create profile row
    if (res.user != null) {
      await _client.from(SupabaseConstants.profilesTable).upsert({
        'id': res.user!.id,
        'display_name': displayName,
        'total_points': 0,
      });
    }
    return res;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => _client.auth.signOut();

  // ── Storage ────────────────────────────────────────────────────────────────

  /// Uploads [file] to the verification-photos bucket.
  /// Returns the public URL of the uploaded file.
  static Future<String> uploadVerificationPhoto(File file) async {
    final userId = currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$timestamp.jpg';

    await _client.storage
        .from(SupabaseConstants.photoBucket)
        .upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );

    return _client.storage
        .from(SupabaseConstants.photoBucket)
        .getPublicUrl(path);
  }

  // ── Activities ─────────────────────────────────────────────────────────────

  /// Inserts a meal-verification activity.
  static Future<void> insertMealActivity({
    required String photoUrl,
    required int points,
  }) async {
    await _client.from(SupabaseConstants.activitiesTable).insert({
      'user_id': currentUser!.id,
      'type': 'meal',
      'photo_url': photoUrl,
      'points': points,
      'status': 'pending', // pending → approved by admin/AI
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Inserts a walking activity.
  static Future<void> insertWalkActivity({
    required double distanceKm,
    required int points,
    required int durationSeconds,
  }) async {
    await _client.from(SupabaseConstants.activitiesTable).insert({
      'user_id': currentUser!.id,
      'type': 'walk',
      'distance_km': distanceKm,
      'points': points,
      'duration_seconds': durationSeconds,
      'status': 'approved', // walks are auto-approved
      'created_at': DateTime.now().toIso8601String(),
    });

    // Update profile total_points
    await _client.rpc('increment_points', params: {
      'uid': currentUser!.id,
      'delta': points,
    });
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> fetchProfile() async {
    final res = await _client
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();
    return res;
  }

  // ── Leaderboard stream ─────────────────────────────────────────────────────

  /// Returns a real-time stream of the top 50 profiles sorted by points.
  static Stream<List<Map<String, dynamic>>> leaderboardStream() {
    return _client
        .from(SupabaseConstants.profilesTable)
        .stream(primaryKey: ['id'])
        .order('total_points', ascending: false)
        .limit(50);
  }

  // ── Verified points stream ─────────────────────────────────────────────────

  /// Streams the current user's total verified points.
  static Stream<List<Map<String, dynamic>>> myPointsStream() {
    return _client
        .from(SupabaseConstants.profilesTable)
        .stream(primaryKey: ['id'])
        .eq('id', currentUser!.id)
        .limit(1);
  }
}
