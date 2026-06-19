import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class CalendarService {
  static Future<void> addAppointmentEvent({
    required String doctorName,
    required String timeFormatted,
    String? location,
    required DateTime startDate,
    required int durationMinutes,
    String? notes,
  }) async {
    final title = 'Dr. $doctorName - $timeFormatted';
    final endDate = startDate.add(Duration(minutes: durationMinutes));

    final event = Event(
      title: title,
      description: notes ?? title,
      location: location ?? '',
      startDate: startDate,
      endDate: endDate,
      iosParams: const IOSParams(reminder: Duration(minutes: 180)),
    );

    if (kIsWeb) {
      await _launchIcs(event);
    } else {
      try {
        await Add2Calendar.addEvent2Cal(event);
      } catch (_) {
        await _launchIcs(event);
      }
    }
  }

  static Future<void> _launchIcs(Event event) async {
    final icsContent = _generateIcs(event);
    final encoded = Uri.encodeComponent(icsContent);
    final uri = Uri.parse('data:text/calendar;charset=utf-8,$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static String _generateIcs(Event event) {
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
      'TRIGGER:-PT180M',
      'ACTION:DISPLAY',
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR',
    ];

    return lines.join('\r\n');
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
