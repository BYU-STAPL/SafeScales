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
      print('Attempting sign in with email: $email');

      // Get all users with matching email
      final response = await supabaseClient
          .from('Users')
          .select()
          .eq('Email', email);

      print('Database response: $response');

      if (response == null || response.isEmpty) {
        print('No user found with email: $email');
        return false;
      }

      // Check all matching users for password match
      for (var user in response) {
        print('Checking user: ${user['Username']}');
        print('Stored email: ${user['Email']}');
        print('Stored password: ${user['password']}');
        print('Input password: $password');
        print('Password comparison result: ${user['password'] == password}');

        if (user['password'] == password) {
          print('Password match found for user: ${user['Username']}');

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

          print('Created user object: ${supabaseUser.toJson()}');

          // Set the current user in UserStateService
          _userState.setUser(supabaseUser);
          _userState.setUserProfile(user);
          print('User state updated successfully');
          return true;
        }
      }

      print('No matching password found for any user with email: $email');
      return false;
    } catch (e) {
      print('Error signing in: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: $e');
      // Clear any existing user state on error
      _userState.setUser(null);
      _userState.setUserProfile(null);
      return false;
    }
  }

  Future<void> signOut() async {
    _userState.setUser(null);
    _userState.setUserProfile(null);
  }

  supabase.User? get currentUser => _userState.supabaseUser;
}
