// lib/services/calendar_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/calendar_event.dart';
import 'package:logging/logging.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as google_calendar;

class CalendarService extends ChangeNotifier {
  final Database _db;
  final _logger = Logger('CalendarService');
  final _prefs = SharedPreferences.getInstance();
  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _icsUrl;
  google_calendar.CalendarApi? _googleCalendarApi;

  CalendarService(this._db) {
    _initializeCalendar();
  }

  bool get isLoading => _isLoading;
  List<CalendarEvent> get events => List.unmodifiable(_events);

  Future<void> _initializeCalendar() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadSettings();
      await _loadLocalEvents();
      await _syncAllSources();
    } catch (e) {
      _logger.severe('Error initializing calendar: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    _icsUrl = prefs.getString('ics_url');
  }

  Future<void> _loadLocalEvents() async {
    try {
      final localEvents = await _db.query('events');
      _events = localEvents.map((e) => CalendarEvent.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      _logger.warning('Error loading local events: $e');
    }
  }

  Future<void> _syncAllSources() async {
    if (_icsUrl != null) {
      await _syncIcsEvents();
    }
    if (_googleCalendarApi != null) {
      await _syncGoogleEvents();
    }
  }

  Future<void> _syncIcsEvents() async {
    if (_icsUrl == null) return;

    try {
      final response = await http.get(Uri.parse(_icsUrl!));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch ICS file');
      }

      final icsData = response.body;
      final calendar = ICalendar.fromString(icsData);
      final icsEvents = calendar.data;  // Use data instead of events
      
      // Remove old ICS events
      _events.removeWhere((event) => event.source == EventSource.icsFile);
      
      // Add new ICS events
      for (final icsEvent in icsEvents) {
        if (icsEvent['type'] == 'VEVENT') {  // Check if it's an event
          final startDt = icsEvent['dtstart'] as DateTime? ?? DateTime.now();
          final endDt = icsEvent['dtend'] as DateTime? ?? startDt.add(const Duration(hours: 1));

          final event = CalendarEvent(
            id: icsEvent['uid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: icsEvent['summary'] ?? 'Untitled Event',
            startTime: startDt,
            endTime: endDt,
            description: icsEvent['description'],
            source: EventSource.icsFile,
          );

          _events.add(event);

          // Update database
          await _db.insert('events', event.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      notifyListeners();
    } catch (e) {
      _logger.warning('Error syncing ICS events: $e');
    }
  }

  Future<void> _syncGoogleEvents() async {
    if (_googleCalendarApi == null) return;

    try {
      final now = DateTime.now();
      final events = await _googleCalendarApi!.events.list(
        'primary',
        timeMin: now.subtract(const Duration(days: 30)).toUtc(),
        timeMax: now.add(const Duration(days: 90)).toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      // Remove old Google events
      _events.removeWhere((event) => event.source == EventSource.googleCalendar);

      // Add new Google events
      final googleEvents = events.items?.map((googleEvent) {
        final start = googleEvent.start?.dateTime ?? DateTime.now();
        final end = googleEvent.end?.dateTime ?? start.add(const Duration(hours: 1));

        return CalendarEvent(
          id: googleEvent.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: googleEvent.summary ?? 'Untitled Event',
          startTime: start,
          endTime: end,
          description: googleEvent.description,
          source: EventSource.googleCalendar,
        );
      }).toList() ?? [];

      _events.addAll(googleEvents);
      notifyListeners();

      // Update database
      for (final event in googleEvents) {
        await _db.insert('events', event.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      _logger.warning('Error syncing Google events: $e');
    }
  }

  Future<void> setIcsUrl(String? url) async {
    _icsUrl = url;
    final prefs = await _prefs;
    if (url != null) {
      await prefs.setString('ics_url', url);
    } else {
      await prefs.remove('ics_url');
    }
    await _syncIcsEvents();
  }

  void setGoogleCalendarApi(google_calendar.CalendarApi? api) {
    _googleCalendarApi = api;
    _syncGoogleEvents();
  }

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    try {
      final event = CalendarEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: eventData['title'],
        startTime: DateTime.parse(eventData['start_time']),
        endTime: DateTime.parse(eventData['end_time']),
        description: eventData['description'],
        source: EventSource.userCreated,
        category: eventData['category'] != null 
            ? EventCategory.values.firstWhere(
                (c) => c.toString() == eventData['category'],
                orElse: () => EventCategory.general,
              )
            : EventCategory.general,
      );

      await _db.insert('events', event.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      _events.add(event);
      notifyListeners();
    } catch (e) {
      _logger.warning('Error creating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      final event = _events.firstWhere((e) => e.id == id);
      if (event.source != EventSource.userCreated) {
        throw Exception('Can only delete user-created events');
      }

      await _db.delete('events', where: 'id = ?', whereArgs: [id]);
      _events.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _logger.warning('Error deleting event: $e');
      rethrow;
    }
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    return _events.where((event) {
      final eventDate = event.startTime;
      return eventDate.year == date.year &&
             eventDate.month == date.month &&
             eventDate.day == date.day;
    }).toList();
  }

  @override
  void dispose() {
    _googleCalendarApi = null;
    super.dispose();
  }
  // Add this method to your CalendarService class

  Future<void> updateEvent(String id, Map<String, dynamic> eventData) async {
    try {
      // Find the existing event
      final existingEvent = _events.firstWhere((e) => e.id == id);
      
      // Only allow updating user-created events
      if (existingEvent.source != EventSource.userCreated) {
        throw Exception('Can only update user-created events');
      }

      // Create updated event
      final updatedEvent = CalendarEvent(
        id: id,
        title: eventData['title'] ?? existingEvent.title,
        startTime: eventData['start_time'] != null 
            ? DateTime.parse(eventData['start_time'])
            : existingEvent.startTime,
        endTime: eventData['end_time'] != null
            ? DateTime.parse(eventData['end_time'])
            : existingEvent.endTime,
        description: eventData['description'] ?? existingEvent.description,
        source: EventSource.userCreated,
        category: eventData['category'] != null 
            ? EventCategory.values.firstWhere(
                (c) => c.toString() == eventData['category'],
                orElse: () => existingEvent.category,
              )
            : existingEvent.category,
      );

      // Update in database
      await _db.update(
        'events',
        updatedEvent.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      // Update in memory
      final index = _events.indexWhere((e) => e.id == id);
      _events[index] = updatedEvent;
      notifyListeners();

    } catch (e) {
      _logger.warning('Error updating event: $e');
      rethrow;
    }
  }
}