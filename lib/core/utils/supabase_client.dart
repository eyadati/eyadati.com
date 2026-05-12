import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseInitializer {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? AppConstants.supabaseUrl;
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? AppConstants.supabaseAnonKey;

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase credentials not configured');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
