import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      // Try to load .env file
      debugPrint('Attempting to load .env file...');
      await dotenv.load(fileName: ".env");
      debugPrint('.env file loaded successfully');

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      debugPrint(
        'Supabase URL: ${supabaseUrl != null ? 'Found' : 'Not found'}',
      );
      debugPrint(
        'Supabase Anon Key: ${supabaseAnonKey != null ? 'Found' : 'Not found'}',
      );

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Missing Supabase credentials in .env file');
      }

      debugPrint('Initializing Supabase...');
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      // You might want to show a user-friendly error message here
      rethrow;
    }
  }

  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('Error getting Supabase client: $e');
      rethrow;
    }
  }
}
