import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Repository responsible for all user-related sign up and login database operations
/// This layer only handles data access - no business logic
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


  // ---------------- UPDATE ----------------


// ---------------- DELETE ----------------


}

/// Custom exception for repository operations
class UserRepositoryException implements Exception {
  final String message;
  UserRepositoryException(this.message);

  @override
  String toString() => 'UserRepositoryException: $message';
}
