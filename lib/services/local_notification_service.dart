import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: false,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: false,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        sound: true,
        badge: false,
      );
    }
  }

  static Future<void> scheduleAppointmentReminders({
    required String appointmentId,
    required DateTime scheduledAt,
  }) async {
    final delta = scheduledAt.difference(DateTime.now());

    final id6h = appointmentId.hashCode & 0x7FFFFFFF;
    final id2h = (appointmentId.hashCode ^ 1) & 0x7FFFFFFF;

    await _plugin.cancel(id: id6h);
    await _plugin.cancel(id: id2h);

    final androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Rappels de rendez-vous',
      channelDescription: 'Notifications de rappel de rendez-vous',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final sixHoursInMinutes = 6 * 60;
    final twoHoursInMinutes = 2 * 60;
    final deltaMinutes = delta.inMinutes;

    if (deltaMinutes > sixHoursInMinutes) {
      final sixHBefore = tz.TZDateTime.from(
        scheduledAt.subtract(const Duration(hours: 6)),
        tz.local,
      );
      await _plugin.zonedSchedule(
        id: id6h,
        title: 'Rappel de rendez-vous',
        body: 'Vous avez rendez-vous dans 6 heures',
        scheduledDate: sixHBefore,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    if (deltaMinutes > twoHoursInMinutes) {
      final twoHBefore = tz.TZDateTime.from(
        scheduledAt.subtract(const Duration(hours: 2)),
        tz.local,
      );
      await _plugin.zonedSchedule(
        id: id2h,
        title: 'Rappel de rendez-vous',
        body: 'Vous avez rendez-vous dans 2 heures',
        scheduledDate: twoHBefore,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
