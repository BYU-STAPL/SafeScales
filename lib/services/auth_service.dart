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
        emailRedirectTo: null,
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
      print('Attempting to sign in with email: $email');

      // Hash the provided password
      final hashedPassword = hashPassword(password);
      print('Hashed password being used: $hashedPassword');

      // First check if user exists with matching email
      final userCheck =
          await supabaseClient
              .from('Users')
              .select()
              .eq('Email', email)
              .limit(1)
              .maybeSingle();

      print('User check result: $userCheck');
      if (userCheck != null) {
        print('Password in database: ${userCheck['password']}');
      }

      if (userCheck != null) {
        // Verify the password matches
        if (userCheck['password'] == hashedPassword) {
          print('Password verified successfully');

          // Create a minimal user object for UserStateService
          final user = supabase.User(
            id: userCheck['id'],
            email: userCheck['Email'],
            createdAt: userCheck['created_at'],
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            role: 'authenticated',
          );

          // Set the current user in UserStateService
          _userState.setUser(user);
          _userState.setUserProfile(userCheck);
          print('User profile set successfully');
          return true;
        } else {
          print('Password does not match');
          print('Provided hash: $hashedPassword');
          print('Database hash: ${userCheck['password']}');
          return false;
        }
      }

      print('Authentication failed - no user found with this email');
      return false;
    } catch (e) {
      print('Error signing in: $e');
      // Clear any existing user state on error
      _userState.setUser(null);
      _userState.setUserProfile(null);
      return false;
    }
  }

  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
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
