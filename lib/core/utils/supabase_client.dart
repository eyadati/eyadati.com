import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';

class SupabaseInitializer {
  static SupabaseClient? _client;
  static bool _isInitializing = false;

  static Future<void> initialize() async {
    if (_client != null) return;
    if (_isInitializing) {
      while (_client == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;

    try {
      String supabaseUrl;
      String supabaseAnonKey;

      if (kDebugMode) {
        await dotenv.load(fileName: '.env');
        supabaseUrl = dotenv.env['SUPABASE_URL'] ?? Environments.production.supabaseUrl;
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? Environments.production.supabaseAnonKey;
      } else {
        supabaseUrl = Environments.production.supabaseUrl;
        supabaseAnonKey = Environments.production.supabaseAnonKey;
      }

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Supabase credentials not configured');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      _client = Supabase.instance.client;
    } finally {
      _isInitializing = false;
    }
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseInitializer.initialize() first.');
    }
    return _client!;
  }
}
