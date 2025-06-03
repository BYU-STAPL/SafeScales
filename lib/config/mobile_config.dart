import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<Map<String, String>> getWebConfig() async {
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Missing Supabase credentials in .env file');
  }

  return {'SUPABASE_URL': supabaseUrl, 'SUPABASE_ANON_KEY': supabaseAnonKey};
}
