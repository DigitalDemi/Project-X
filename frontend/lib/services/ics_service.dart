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

  Future<List<CalendarEvent>> fetchAndParseIcsEvents() async {
    final url = await getIcsUrl();
    if (url == null) return [];

    try {
      // Set a timeout to prevent hanging on invalid URLs
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
          
      if (response.statusCode != 200) {
        _logger.warning('Failed to fetch ICS file: ${response.statusCode}');
        throw Exception('Failed to fetch ICS file (${response.statusCode})');
      }

      final icsData = response.body;
      
      // Verify this is actually an ICS file
      if (!icsData.toUpperCase().contains('BEGIN:VCALENDAR')) {
        _logger.severe('Invalid ICS format: not a calendar file');
        
        // Check if we got a login page instead
        if (icsData.contains('doctype html') || 
            icsData.contains('accounts.google.com')) {
          throw Exception(
            'Received login page instead of calendar data. ' +
            'Make sure you\'re using the "Secret address in iCal format" ' +
            'from Google Calendar settings.'
          );
        }
        
        throw Exception('Invalid calendar format');
      }

      final calendar = ICalendar.fromString(icsData);
      final List<CalendarEvent> events = [];

      // Parse events from the calendar data
      for (final event in calendar.data) {
        if (event['type'] == 'VEVENT') {
          try {
            final startDt = event['dtstart'] as DateTime?;
            final endDt = event['dtend'] as DateTime?;
            
            if (startDt != null) {
              events.add(CalendarEvent(
                id: event['uid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: event['summary'] ?? 'Untitled Event',
                startTime: startDt,
                endTime: endDt ?? startDt.add(const Duration(hours: 1)),
                description: event['description'],
                source: EventSource.icsFile,
              ));
            }
          } catch (e) {
            _logger.warning('Error parsing ICS event: $e');
            continue;
          }
        }
      }

      _logger.info('Successfully parsed ${events.length} events');
      return events;
      
    } catch (e) {
      _logger.severe('Error fetching ICS events: $e');
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