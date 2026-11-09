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
      // Create Auth user; DB trigger creates the public Users profile row.
      final authResponse = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (authResponse.user != null) {
        // Ensure username/email are set on the profile (trigger may race).
        await userRepository.ensureProfileAfterSignUp(
          authResponse.user!.id,
          username,
          email,
        );

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
      final authResponse = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        return false;
      }

      _userState.setUser(user);
      await _userState.loadUserProfile();
      return true;
    } catch (e) {
      print('Error signing in: $e');
      _userState.setUser(null);
      _userState.setUserProfile(null);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
      _userState.setUser(null);
      _userState.setUserProfile(null);
    } catch (e) {
      print('Error signing out: $e');
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
