import 'package:flutter/foundation.dart' show kIsWeb;

/// Password-recovery redirect targets for Supabase Auth.
///
/// These URLs must be allowlisted under Supabase → Authentication → URL
/// Configuration → Redirect URLs. Prefer the current web origin in production
/// so Auth does not fall back to a localhost Site URL.
class AuthRedirect {
  /// Custom scheme used by the Android app (see AndroidManifest intent-filter).
  static const String mobileDeepLink = 'com.safescales.byu://set-password';

  /// Local Flutter web default during `flutter run -d chrome`.
  static const String localWebOrigin = 'http://localhost:3000';

  /// Build redirectTo for [resetPasswordForEmail].
  ///
  /// Web: current origin + path (no hash/query — Supabase appends tokens).
  /// Mobile: deep link that opens this app on the set-password flow.
  static String passwordResetRedirectTo() {
    if (kIsWeb) {
      final base = Uri.base;
      var path = base.path;
      if (path.isEmpty) path = '/';
      if (!path.endsWith('/')) path = '$path/';
      return '${base.origin}$path';
    }
    return mobileDeepLink;
  }
}
