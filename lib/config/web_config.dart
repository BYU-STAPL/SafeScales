import 'dart:js' as js;

Future<Map<String, String>> getWebConfig() async {
  if (!js.context.hasProperty('env')) {
    throw Exception(
      'window.env is not defined. Make sure env.js is loaded before Flutter.',
    );
  }

  final env = js.context['env'];
  if (env == null) {
    throw Exception(
      'window.env is null. Make sure env.js is loaded before Flutter.',
    );
  }

  final supabaseUrl = env['SUPABASE_URL'] as String?;
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] as String?;

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Missing Supabase credentials in window.env');
  }

  return {'SUPABASE_URL': supabaseUrl, 'SUPABASE_ANON_KEY': supabaseAnonKey};
}
