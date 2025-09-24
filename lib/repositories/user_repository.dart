import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Repository responsible for all user-related sign up and login database operations
class UserRepository {
  final SupabaseClient _supabase;

  UserRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;


  // ---------------- CREATE ----------------

  Future<void> signUpUser(String userId, String username, String email, String password) async {
    try {
      await _supabase
          .from('Users')
          .insert({
            'id': userId,
            'Username': username,
            'Email': email,
          'password': password, // Store plain password
        });
    }
    catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }

  // ---------------- READ ----------------

  Future<Map<String, String>> loginWithEmail(String email, String password) async {
    try {
      final response = await _supabase
          .from('Users')
          .select()
          .eq('Email', email)
          .single();

      // Check email again
      // Check password after
      if (response['Email'] == email && response['password'] == password) {
        return {
          'email': response['Email'].toString(),
          'id': response['id'].toString(),
          'created_at': response['created_at'].toString(),
        };
      }


      return {};
    }
    catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }

  Future<List<dynamic>> getUsersJoinedClasses(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('Users')
          .select('joined_classes')
          .eq('id', userId)
          .single();

      final joinedClasses = response['joined_classes'] as List<dynamic>?;

      return joinedClasses ?? [];
    }
    catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }


  // ---------------- UPDATE ----------------

  Future<bool> joinClass(String userId, String classId) async {
    try {
      // Get current user's joined classes
      final response = await SupabaseConfig.client
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
    }
    catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }


  Future<void> insertInitialReadingProgressData(String userId, String classId) async {
    try {
      // Get modules for the class
      final classResponse = await _supabase
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
    }
    catch (e) {
      throw UserRepositoryException(e.toString());
    }
  }

  Future<void> insertInitialDragonData(String userId, String classId) async {
    try {
      // Initialize dragons for each module
      final classAssetsResponse = await SupabaseConfig.client
          .from('classes')
          .select('assets')
          .eq('id', classId)
          .single();

      final classAssetList = List<Map<String, dynamic>>.from(classAssetsResponse['assets'] ?? []);

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
    }
    catch (e) {
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
