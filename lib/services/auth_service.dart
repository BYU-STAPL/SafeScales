import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safe_scales/config/supabase_config.dart';

class AuthService {
  final supabase = SupabaseConfig.client;

  Future<AuthResponse> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // First create the auth user
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
      );

      if (authResponse.user != null) {
        // Then add the user to our custom Users table
        await supabase.from('Users').insert({
          'id': authResponse.user!.id,
          'Username': username,
          'Email': email,
          'password':
              password, // Note: In a production app, you should never store plain passwords
        });
      }

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    final response =
        await supabase
            .from('Users')
            .select()
            .eq('Email', email)
            .eq('password', password) // In production, hash and compare!
            .single();

    return response != null;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}
