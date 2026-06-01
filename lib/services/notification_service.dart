import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:eyadati/core/utils/supabase_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final StreamController<RemoteMessage> _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  FirebaseMessaging? _messaging;
  bool _initialized = false;

  Future<void> init({required bool isMobile}) async {
    if (_initialized) return;
    _initialized = true;

    _messaging = FirebaseMessaging.instance;

    final permission = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (permission.authorizationStatus == AuthorizationStatus.denied ||
        permission.authorizationStatus == AuthorizationStatus.notDetermined) {
      return;
    }

    try {
      final token = await _messaging!.getToken(
        vapidKey: 'BE-a13FMcHWXi287vRmw6N0oNIOh9eoP6KOP71eIpTjjUc63Vmi7di_6X-CbT77zAF2-dhKytlE-XTnGIcr685k',
      );
      if (token != null) {
        await _saveToken(token, isMobile: isMobile);
      }
    } catch (_) {}

    _messaging!.onTokenRefresh.listen((token) {
      _saveToken(token, isMobile: isMobile);
    });

    FirebaseMessaging.onMessage.listen((message) {
      _messageController.add(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _messageController.add(message);
    });

    try {
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _messageController.add(initialMessage);
      }
    } catch (_) {}
  }

  Future<void> _saveToken(String token, {required bool isMobile}) async {
    final user = SupabaseInitializer.client.auth.currentUser;
    if (user == null) return;

    try {
      await SupabaseInitializer.client.from('push_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': isMobile ? 'web_mobile' : 'web_desktop',
        },
        onConflict: 'user_id, token',
      );
    } catch (_) {}
  }

  Future<void> deleteToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token != null) {
        final user = SupabaseInitializer.client.auth.currentUser;
        if (user != null) {
          await SupabaseInitializer.client
              .from('push_tokens')
              .delete()
              .eq('user_id', user.id)
              .eq('token', token);
        }
        await _messaging?.deleteToken();
      }
    } catch (_) {}
  }

  void dispose() {
    _messageController.close();
  }
}

final notificationService = NotificationService();
