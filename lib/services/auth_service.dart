import 'package:safe_scales/config/auth_redirect.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/repositories/user_repository.dart';
import 'package:safe_scales/services/user_state_service.dart';
import 'package:safe_scales/utils/supabase_errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

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
        data: {
          'username': username,
          'auth_password_confirmed_at': DateTime.now().toUtc().toIso8601String(),
          'must_set_password': false,
        },
      );

      if (authResponse.user != null) {
        // Ensure username/email are set on the profile (trigger may race).
        await userRepository.ensureProfileAfterSignUp(
          authResponse.user!.id,
          username,
          email,
        );

        _userState.setUser(authResponse.user);
        await _userState.loadUserProfile(required: true);

        // New signups already chose a password — mark confirmed (best-effort).
        try {
          await _userState.markPasswordConfirmed();
        } catch (e) {
          print('Could not mark password confirmed after signup: $e');
        }
      }

      return authResponse;
    } catch (e) {
      throw Exception(getErrorMessage(e, 'Sign up failed'));
    }
  }

  // ---------------- READ ----------------

  /// Signs in with email/password and loads the linked Users profile.
  /// Throws with the real Auth / PostgREST message on failure.
  Future<void> signIn({required String email, required String password}) async {
    try {
      final authResponse = await supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('No session returned');
      }

      _userState.setUser(user);
      await _userState.loadUserProfile(required: true);
    } catch (e) {
      print('Error signing in: $e');
      _userState.setUser(null);
      _userState.setUserProfile(null);
      if (e is ProfileNotLinkedException) rethrow;
      throw Exception(getErrorMessage(e, 'Login failed'));
    }
  }

  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
      _userState.setUser(null);
      _userState.setUserProfile(null);
      _userState.setPasswordRecovery(false);
    } catch (e) {
      print('Error signing out: $e');
      _userState.setUser(null);
      _userState.setUserProfile(null);
      _userState.setPasswordRecovery(false);
    }
  }

  Future<bool> isUserInAnyClasses(String userId) async {
    List<dynamic> classes = await userRepository.getUsersJoinedClasses(userId);

    return classes.isNotEmpty;
  }

  /// Email a password-recovery / first-time Auth setup link.
  Future<void> requestPasswordSetupEmail(String email) async {
    final redirectTo = AuthRedirect.passwordResetRedirectTo();
    print('Password reset redirectTo=$redirectTo');
    try {
      await supabaseClient.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
    } catch (e) {
      throw Exception(
        getErrorMessage(e, 'Could not send password setup email'),
      );
    }
  }

  /// Update Auth password after recovery or forced setup, then mark profile.
  Future<void> setNewAuthPassword(String newPassword) async {
    if (newPassword.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    final userResponse = await supabaseClient.auth.getUser();
    final user = userResponse.user;
    if (user == null) {
      throw Exception('You must be signed in to set a password');
    }

    try {
      await supabaseClient.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception(getErrorMessage(e, 'Could not update password'));
    }

    // Profile settings update must not hang the UI if it fails.
    try {
      await _userState.markPasswordConfirmed();
    } catch (e) {
      print('Password updated in Auth; profile confirm failed: $e');
      throw Exception(
        getErrorMessage(
          e,
          'Password was updated, but saving profile confirmation failed',
        ),
      );
    }

    _userState.setPasswordRecovery(false);
  }

  // ---------------- UPDATE ----------------

  Future<bool> joinClass(String userId, String classId) async {
    return await userRepository.joinClass(userId, classId);
  }

  // ---------------- DELETE ----------------
}
