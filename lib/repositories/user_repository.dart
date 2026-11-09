import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Repository responsible for all user-related sign up and login database operations
class UserRepository {
  final SupabaseClient _supabase;

  UserRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseConfig.client;

  // ---------------- CREATE ----------------

  /// Profile rows are created by the auth.users trigger. This only fills
  /// username after signup when the caller has a real Auth session.
  Future<void> ensureProfileAfterSignUp(
    String userId,
    String username,
    String email,
  ) async {
    try {
      // Wait briefly for the trigger-created row, then set Username.
      for (var attempt = 0; attempt < 5; attempt++) {
        final existing =
            await _supabase
                .from('Users')
                .select('id')
                .eq('id', userId)
                .maybeSingle();
        if (existing != null) {
          await _supabase
              .from('Users')
              .update({'Username': username})
              .eq('id', userId);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      throw UserRepositoryException(
        'Profile was not created for $email. Try signing in again.',
      );
    } catch (e) {
      if (e is UserRepositoryException) rethrow;
      throw UserRepositoryException(e.toString());
    }
  }

  // ---------------- READ ----------------

  Future<List<dynamic>> getUsersJoinedClasses(String userId) async {
    try {
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('joined_classes')
              .eq('id', userId)
              .single();

      final joinedClasses = response['joined_classes'] as List<dynamic>?;

      return joinedClasses ?? [];
    } catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }

  // ---------------- UPDATE ----------------

  Future<bool> joinClass(String userId, String classId) async {
    try {
      // Get current user's joined classes
      final response =
          await SupabaseConfig.client
              .from('Users')
              .select('joined_classes')
              .eq('id', userId)
              .single();

      List<String> joinedClasses = List<String>.from(
        response['joined_classes'] ?? [],
      );

      // User has already joined exit
      if (joinedClasses.contains(classId)) {
        return false;
      }

      // Add class
      joinedClasses.add(classId);

      // Update user's joined classes
      await SupabaseConfig.client
          .from('Users')
          .update({'joined_classes': joinedClasses})
          .eq('id', userId);

      // Add Initial Data
      await insertInitialReadingProgressData(userId, classId);
      await insertInitialDragonData(userId, classId);

      return true;
    } catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }

  Future<void> insertInitialReadingProgressData(
    String userId,
    String classId,
  ) async {
    try {
      // Get modules for the class
      final classResponse =
          await _supabase
              .from('classes')
              .select('course_modules')
              .eq('id', classId)
              .single();

      // Initialize empty progress for each module
      Map<String, dynamic> initialReadingProgress = {};
      if (classResponse['course_modules'] != null) {
        for (var moduleId in classResponse['course_modules']) {
          initialReadingProgress[moduleId] = {
            'reading': {
              'completed': false,
              'completed_at': null,
              'bookmarks': [],
            },
          };
        }
      }

      // Insert default class data
      await _supabase
          .from('Users')
          .update({'reading_progress': initialReadingProgress})
          .eq('id', userId);
    } catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }

  Future<void> insertInitialDragonData(String userId, String classId) async {
    try {
      // Initialize dragons for each module
      final classAssetsResponse =
          await SupabaseConfig.client
              .from('classes')
              .select('assets')
              .eq('id', classId)
              .single();

      final classAssetList = List<Map<String, dynamic>>.from(
        classAssetsResponse['assets'] ?? [],
      );

      Map<String, dynamic> initialDragonData = {};

      for (final asset in classAssetList) {
        if (asset['type'] != 'dragon') continue;

        final dragonId = asset['id'] as String?;
        if (dragonId == null) continue;

        initialDragonData[dragonId] = {
          'name': 'no name',
          'phases': ['egg'],
        };
      }

      // Insert default class data
      await SupabaseConfig.client
          .from('Users')
          .update({'dragons': initialDragonData})
          .eq('id', userId);
    } catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }

  // ---------------- DELETE ----------------
}

/// Custom exception for repository operations
class UserRepositoryException implements Exception {
  final String message;
  UserRepositoryException(this.message);

  @override
  String toString() => 'UserRepositoryException: $message';
}
