import 'package:safe_scales/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/services/user_state_service.dart';

class AuthService {
  UserRepository userRepository = UserRepository();
  final supabaseClient = SupabaseConfig.client;
  final _userState = UserStateService();

  supabase.User? get currentUser => _userState.supabaseUser;

  // ---------------- CREATE ----------------

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
        // Add user to database
        await userRepository.signUpUser(authResponse.user!.id, username, email, password);

        // Set the current user in UserStateService
        _userState.setUser(authResponse.user);
        await _userState.loadUserProfile();
      }

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // ---------------- READ ----------------


  Future<bool> signIn({required String email, required String password}) async {
    try {
      Map<String, String> userInfo = await userRepository.loginWithEmail(email, password);

      if (userInfo.isEmpty) {
        return false;
      }
      else {
        final supabaseUser = supabase.User(
          id: userInfo['id']!,
          email: userInfo['email'],
          createdAt: userInfo['created_at']!,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          role: 'authenticated',
        );

        // Set the current user in UserStateService
        _userState.setUser(supabaseUser);
        _userState.setUserProfile(userInfo);

        return true;
      }

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

  Future<bool> isUserInAnyClasses(String userId) async {
    List<dynamic> classes = await userRepository.getUsersJoinedClasses(userId);

    return classes.isNotEmpty;
  }

  // ---------------- UPDATE ----------------

  Future<bool> joinClass(String userId, String classId) async {
    return await userRepository.joinClass(userId, classId);
  }

  // ---------------- DELETE ----------------


}
