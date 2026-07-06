import 'dart:math';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class CalendarService {
  static const int idealReminderMinutes = 360;

  static int computeReminderMinutes(DateTime appointmentTime) {
    final delta = appointmentTime.difference(DateTime.now()).inMinutes;
    if (delta > 420) return 360;
    if (delta > 180) return 180;
    if (delta > 60) return 60;
    if (delta > 30) return 30;
    return max(15, delta - 5);
  }

  static Future<void> addAppointmentEvent({
    required String doctorName,
    required String timeFormatted,
    String? location,
    required DateTime startDate,
    required int durationMinutes,
    String? notes,
    int reminderMinutes = idealReminderMinutes,
  }) async {
    final title = 'Dr. $doctorName - $timeFormatted';
    final endDate = startDate.add(Duration(minutes: durationMinutes));

    final event = Event(
      title: title,
      description: notes ?? title,
      location: location ?? '',
      startDate: startDate,
      endDate: endDate,
      iosParams: IOSParams(reminder: Duration(minutes: reminderMinutes)),
    );

    if (kIsWeb) {
      await _launchIcs(event, reminderMinutes);
    } else {
      try {
        await Add2Calendar.addEvent2Cal(event);
      } catch (_) {
        await _launchIcs(event, reminderMinutes);
      }
    }
  }

  static Future<void> _launchIcs(Event event, int reminderMinutes) async {
    final icsContent = _generateIcs(event, reminderMinutes);
    final encoded = Uri.encodeComponent(icsContent);
    final uri = Uri.parse('data:text/calendar;charset=utf-8,$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static String _generateIcs(Event event, int reminderMinutes) {
    final dateFormat = (DateTime dt) =>
        '${dt.year}${_pad(dt.month)}${_pad(dt.day)}T${_pad(dt.hour)}${_pad(dt.minute)}00';

    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'BEGIN:VEVENT',
      'SUMMARY:${event.title}',
      if (event.location != null && event.location!.isNotEmpty)
        'LOCATION:${event.location}',
      if (event.description != null) 'DESCRIPTION:${event.description}',
      'DTSTART:${dateFormat(event.startDate)}',
      'DTEND:${dateFormat(event.endDate)}',
      'BEGIN:VALARM',
      'TRIGGER:-PT${reminderMinutes}M',
      'ACTION:DISPLAY',
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR',
    ];

    return lines.join('\r\n');
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
