import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Platform-specific imports
import 'web_config.dart'
    if (dart.library.io) 'mobile_config.dart'
    as platform_config;

class SupabaseConfig {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Supabase already initialized, skipping...');
      return;
    }

    try {
      String? supabaseUrl;
      String? supabaseAnonKey;

      if (kIsWeb) {
        debugPrint('Web environment detected, loading web configuration...');
        final config = await platform_config.getWebConfig();
        supabaseUrl = config['SUPABASE_URL'];
        supabaseAnonKey = config['SUPABASE_ANON_KEY'];
      } else {
        // In non-web environment, load from .env file
        debugPrint('Non-web environment detected, loading .env file...');
        await dotenv.load(fileName: ".env");
        supabaseUrl = dotenv.env['SUPABASE_URL'];
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      }

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Failed to get Supabase credentials');
      }

      debugPrint('Initializing Supabase with URL: $supabaseUrl');
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true, // Enable debug mode for more detailed logs
      );
      _isInitialized = true;

    } catch (e) {
      debugPrint('❌ Error initializing Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('❌ Error getting Supabase client: $e');
      rethrow;
    }
  }
}
