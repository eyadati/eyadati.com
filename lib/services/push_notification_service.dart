import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:eyadati/firebase_options.dart';
import 'package:eyadati/core/utils/supabase_client.dart';

class PushNotificationService {
  static PushNotificationService? _instance;
  static FirebaseMessaging? _messaging;
  static bool _initialized = false;

  static PushNotificationService get instance =>
      _instance ??= PushNotificationService._();

  PushNotificationService._();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (kIsWeb) {
        await _initWeb();
      } else {
        await _initMobile();
      }
    } catch (e) {
      debugPrint('PushNotificationService: init failed: $e');
    }
  }

  Future<void> _initWeb() async {
    if (!AppFirebaseConfig.isWebSupported) {
      debugPrint('PushNotificationService: Firebase not configured for web');
      return;
    }
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: AppFirebaseConfig.apiKey,
        projectId: AppFirebaseConfig.projectId,
        messagingSenderId: AppFirebaseConfig.messagingSenderId,
        appId: AppFirebaseConfig.appId,
      ),
    );
    _messaging = FirebaseMessaging.instance;
    await _messaging!.requestPermission();
    final token = await _messaging!.getToken(
      vapidKey: AppFirebaseConfig.vapidKey,
    );
    if (token != null) {
      await _registerToken(token);
    }
    _messaging!.onTokenRefresh.listen((token) {
      _registerToken(token);
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.data['title'] ?? 'Eyadati';
      final body = message.data['body'] ?? '';
      debugPrint('Foreground message: $title - $body');
    });
  }

  Future<void> _initMobile() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      debugPrint('PushNotificationService: no Firebase config for mobile');
      return;
    }
    _messaging = FirebaseMessaging.instance;
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging!.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    }
    _messaging!.onTokenRefresh.listen((token) {
      _registerToken(token);
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.data['title'] ?? 'Eyadati';
      final body = message.data['body'] ?? '';
      debugPrint('Foreground message: $title - $body');
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      final user = SupabaseInitializer.client.auth.currentUser;
      if (user == null) return;

      await SupabaseInitializer.client.from('push_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': kIsWeb ? 'web' : 'mobile',
        },
        onConflict: 'token',
      );
    } catch (e) {
      debugPrint('PushNotificationService: token registration failed: $e');
    }
  }

  Future<void> unregisterToken() async {
    try {
      final user = SupabaseInitializer.client.auth.currentUser;
      final token = await _messaging?.getToken();
      if (user != null && token != null) {
        await SupabaseInitializer.client
            .from('push_tokens')
            .delete()
            .eq('token', token);
      }
    } catch (e) {
      debugPrint('PushNotificationService: token removal failed: $e');
    }
  }

}
