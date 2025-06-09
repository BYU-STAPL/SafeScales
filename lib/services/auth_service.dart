import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:safe_scales/config/supabase_config.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
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
          'password': hashPassword(password),
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
      // Get user from Users table
      final response =
          await supabaseClient
              .from('Users')
              .select()
              .eq('Email', email)
              .single();

      // Hash the provided password
      final hashedPassword = hashPassword(password);

      print('Input hashed password: $hashedPassword');
      print('Stored password: ${response['password']}');

      // Compare passwords
      if (response['password'] != hashedPassword) {
        print('Passwords do not match');
        return false;
      }

      print('Passwords match!');

      // Create a simple user object with the necessary data
      final user = supabase.User(
        id: response['id'],
        email: response['Email'],
        createdAt: response['created_at'],
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        role: 'authenticated',
      );

      // Set the current user in UserStateService
      _userState.setUser(user);
      _userState.setUserProfile(response);
      return true;
    } catch (e) {
      print('Error signing in: $e');
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

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
