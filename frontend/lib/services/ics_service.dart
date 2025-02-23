// lib/services/ics_service.dart
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_event.dart';
import 'package:logging/logging.dart';

class IcsService {
  static const String _icsUrlKey = 'ics_calendar_url';
  final _prefs = SharedPreferences.getInstance();
  final _logger = Logger('IcsService');

  Future<String?> getIcsUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_icsUrlKey);
  }

  Future<void> setIcsUrl(String? url) async {
    final prefs = await _prefs;
    if (url == null || url.isEmpty) {
      await prefs.remove(_icsUrlKey);
    } else {
      await prefs.setString(_icsUrlKey, url);
    }
  }

  DateTime _convertToDateTime(dynamic date) {
    if (date is DateTime) {
      return date;
    } else if (date is String) {
      return DateTime.parse(date);
    } else if (date is IcsDateTime) {
      // Convert IcsDateTime format (e.g., "20250223T210000Z")
      try {
        final dt = date.dt;
        if (dt == null) return DateTime.now();

        // Parse the date string
        final year = int.parse(dt.substring(0, 4));
        final month = int.parse(dt.substring(4, 6));
        final day = int.parse(dt.substring(6, 8));
        final hour = int.parse(dt.substring(9, 11));
        final minute = int.parse(dt.substring(11, 13));
        final second = dt.length > 13 ? int.parse(dt.substring(13, 15)) : 0;

        // Handle UTC ('Z' suffix)
        if (dt.endsWith('Z')) {
          return DateTime.utc(year, month, day, hour, minute, second);
        } else {
          return DateTime(year, month, day, hour, minute, second);
        }
      } catch (e) {
        _logger.warning('Error parsing IcsDateTime: $e\nDate data: $date');
        return DateTime.now();
      }
    } else if (date is Map && date['dt'] != null) {
      // Handle raw date data
      return DateTime.parse(date['dt']);
    }

    // If we can't convert it, log and return current time as fallback
    _logger.warning('Could not parse date: $date (${date.runtimeType})');
    return DateTime.now();
  }

  Future<List<CalendarEvent>> fetchAndParseIcsEvents() async {
    final url = await getIcsUrl();
    if (url == null) return [];

    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
          
      if (response.statusCode != 200) {
        _logger.warning('Failed to fetch ICS file: ${response.statusCode}');
        throw Exception('Failed to fetch ICS file (${response.statusCode})');
      }

      final icsData = response.body;
      
      if (!icsData.toUpperCase().contains('BEGIN:VCALENDAR')) {
        _logger.severe('Invalid ICS format: not a calendar file');
        
        if (icsData.contains('doctype html') || 
            icsData.contains('accounts.google.com')) {
          throw Exception(
            'Received login page instead of calendar data. '
            'Make sure you\'re using the "Secret address in iCal format" '
            'from Google Calendar settings.'
          );
        }
        
        throw Exception('Invalid calendar format');
      }

      final calendar = ICalendar.fromString(icsData);
      final List<CalendarEvent> events = [];

      for (final event in calendar.data) {
        if (event['type'] == 'VEVENT') {
          try {
            final dynamic startDt = event['dtstart'];
            final dynamic endDt = event['dtend'];
            
            if (startDt != null) {
              final DateTime start = _convertToDateTime(startDt);
              final DateTime end = endDt != null 
                  ? _convertToDateTime(endDt)
                  : start.add(const Duration(hours: 1));

              events.add(CalendarEvent(
                id: event['uid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: event['summary'] ?? 'Untitled Event',
                startTime: start,
                endTime: end,
                description: event['description']?.toString(),
                source: EventSource.icsFile,
              ));
            }
          } catch (e, stackTrace) {
            _logger.warning(
              'Error parsing ICS event: $e\nEvent data: ${event.toString()}\n$stackTrace'
            );
            continue;
          }
        }
      }

      // Sort events by start time
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      _logger.info('Successfully parsed ${events.length} events');
      return events;
      
    } catch (e, stackTrace) {
      _logger.severe('Error fetching ICS events: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<CalendarEvent>> getUpcomingEvents({int daysAhead = 30}) async {
    final events = await fetchAndParseIcsEvents();
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: daysAhead));

    return events.where((event) {
      return event.startTime.isAfter(now) && 
             event.startTime.isBefore(cutoff);
    }).toList();
  }

  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final events = await fetchAndParseIcsEvents();
    return events.where((event) {
      return event.startTime.year == date.year &&
             event.startTime.month == date.month &&
             event.startTime.day == date.day;
    }).toList();
  }

  Future<void> refreshEvents() async {
    try {
      await fetchAndParseIcsEvents();
    } catch (e) {
      _logger.severe('Error refreshing ICS events: $e');
      rethrow;
    }
  }
}