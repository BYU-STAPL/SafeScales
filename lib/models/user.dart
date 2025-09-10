import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class User {
  final String id;
  final String? email;
  final String? createdAt;
  final Map<String, dynamic> appMetadata;
  final Map<String, dynamic> userMetadata;
  final String aud;
  final String role;
  final Map<String, dynamic>? quizzes;
  final Map<String, dynamic>? modules;

  User({
    required this.id,
    this.email,
    this.createdAt,
    required this.appMetadata,
    required this.userMetadata,
    required this.aud,
    required this.role,
    this.quizzes,
    this.modules,
  });

  factory User.fromSupabaseUser(
    supabase.User supabaseUser, {
    Map<String, dynamic>? quizzes,
    Map<String, dynamic>? modules,
  }) {
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email,
      createdAt: supabaseUser.createdAt,
      appMetadata: Map<String, dynamic>.from(supabaseUser.appMetadata),
      userMetadata: Map<String, dynamic>.from(supabaseUser.userMetadata ?? {}),
      aud: supabaseUser.aud ?? 'authenticated',
      role: supabaseUser.role ?? 'authenticated',
      quizzes: quizzes,
      modules: modules,
    );
  }
}
