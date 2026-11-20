import 'package:supabase_flutter/supabase_flutter.dart';

/// Extract a human-readable message from Auth / Postgrest / plain objects.
///
/// JS PostgREST errors are plain `{ message, code, details, hint }` objects.
/// Dart usually throws typed exceptions, but FunctionException / Maps still appear.
String getErrorMessage(Object? err, [String fallback = 'Something went wrong']) {
  if (err == null) return fallback;

  if (err is AuthException) {
    final message = err.message.trim();
    if (message.isNotEmpty) return message;
  }

  if (err is PostgrestException) {
    final message = err.message.trim();
    if (message.isNotEmpty) return message;
  }

  if (err is FunctionException) {
    final details = err.details;
    if (details is Map) {
      final nested =
          details['error'] ?? details['message'] ?? details['msg'];
      if (nested is String && nested.trim().isNotEmpty) return nested.trim();
    }
    if (details is String && details.trim().isNotEmpty) return details.trim();
    final reason = err.reasonPhrase?.trim();
    if (reason != null && reason.isNotEmpty) return reason;
  }

  if (err is Map) {
    final message = err['message'] ?? err['error_description'] ?? err['error'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
  }

  if (err is ProfileNotLinkedException) {
    return err.message;
  }

  final asString = err.toString().trim();
  if (asString.isEmpty || asString == 'null') return fallback;

  // Strip common Dart "Exception: " / "Error: " prefixes for UI.
  final stripped = asString
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^Error:\s*'), '')
      .trim();
  return stripped.isNotEmpty ? stripped : fallback;
}

bool isMissingProfileError(Object? err) {
  if (err is ProfileNotLinkedException) return true;
  if (err is PostgrestException) {
    return err.code == 'PGRST116';
  }
  final message = getErrorMessage(err, '');
  return message.contains('PGRST116') ||
      message.contains('0 rows') ||
      message.contains('No Users profile is linked');
}

/// Thrown when Auth succeeded but public."Users".id does not match auth.users.id.
class ProfileNotLinkedException implements Exception {
  final String message;

  ProfileNotLinkedException([
    this.message =
        'No Users profile is linked to this Auth account. In Supabase SQL, Users.id must equal auth.users.id for your email.',
  ]);

  @override
  String toString() => message;
}
