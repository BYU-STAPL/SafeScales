import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/services/user_state_service.dart';

class AuthService {
  final supabaseClient = SupabaseConfig.client;
  final _userState = UserStateService();

  Future<supabase.AuthResponse> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // First create the auth user
      final authResponse = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Then add the user to our custom Users table
        await supabaseClient.from('Users').insert({
          'id': authResponse.user!.id,
          'Username': username,
          'Email': email,
          'password': password, // Store plain password
        });

        // Set the current user in UserStateService
        _userState.setUser(authResponse.user);
        await _userState.loadUserProfile();
      }

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      // Get all users with matching email
      final response = await supabaseClient
          .from('Users')
          .select()
          .eq('Email', email);

      if (response.isEmpty) {
        print('No user found with email: $email');
        return false;
      }

      // Check all matching users for password match
      for (var user in response) {
        if (user['password'] == password) {
          // Create a simple user object with the necessary data
          final supabaseUser = supabase.User(
            id: user['id'],
            email: user['Email'],
            createdAt: user['created_at'],
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            role: 'authenticated',
          );

          // Set the current user in UserStateService
          _userState.setUser(supabaseUser);
          _userState.setUserProfile(user);

          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌Error signing in: $e');
      print('❌Error type: ${e.runtimeType}');
      print('❌Error details: $e');
      // Clear any existing user state on error
      _userState.setUser(null);
      _userState.setUserProfile(null);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Supabase
      await supabaseClient.auth.signOut();

      // Clear user state
      _userState.setUser(null);
      _userState.setUserProfile(null);
    } catch (e) {
      print('❌Error signing out: $e');
      // Even if there's an error, clear the local user state
      _userState.setUser(null);
      _userState.setUserProfile(null);
    }
  }

  supabase.User? get currentUser => _userState.supabaseUser;
}
