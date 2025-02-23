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
      
      // Remove old ICS events
      await _db.delete('events', where: 'source = ?', whereArgs: [EventSource.icsFile.toString()]);
      _events.removeWhere((event) => event.source == EventSource.icsFile);
      
      // Add new ICS events
      for (final icsEvent in calendar.data) {
        if (icsEvent['type'] == 'VEVENT') {
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
      await _db.delete('events', where: 'source = ?', whereArgs: [EventSource.googleCalendar.toString()]);
      _events.removeWhere((event) => event.source == EventSource.googleCalendar);

      // Add new Google events
      for (final googleEvent in events.items ?? []) {
        final start = googleEvent.start?.dateTime ?? DateTime.now();
        final end = googleEvent.end?.dateTime ?? start.add(const Duration(hours: 1));

        final event = CalendarEvent(
          id: googleEvent.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: googleEvent.summary ?? 'Untitled Event',
          startTime: start,
          endTime: end,
          description: googleEvent.description,
          source: EventSource.googleCalendar,
          externalId: googleEvent.id,
        );

        _events.add(event);
        await _db.insert('events', event.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      notifyListeners();
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
        category: eventData['category'] ?? EventCategory.general,
      );

      // Save to local database
      await _db.insert('events', event.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      // Add to memory
      _events.add(event);
      notifyListeners();

      // If Google Calendar is connected, create event there
      if (_googleCalendarApi != null) {
        try {
          final startDateTime = google_calendar.EventDateTime()
            ..dateTime = event.startTime
            ..timeZone = 'UTC';

          final endDateTime = google_calendar.EventDateTime()
            ..dateTime = event.endTime
            ..timeZone = 'UTC';

          final googleEvent = google_calendar.Event()
            ..summary = event.title
            ..description = event.description
            ..start = startDateTime
            ..end = endDateTime;

          final createdEvent = await _googleCalendarApi!.events.insert(
            googleEvent,
            'primary',
          );

          // Update local event with Google Calendar ID
          if (createdEvent.id != null) {
            final updatedEvent = event.copyWith(externalId: createdEvent.id);
            await _db.update(
              'events',
              updatedEvent.toMap(),
              where: 'id = ?',
              whereArgs: [event.id],
            );

            // Update in memory
            final index = _events.indexWhere((e) => e.id == event.id);
            if (index != -1) {
              _events[index] = updatedEvent;
              notifyListeners();
            }
          }
        } catch (e) {
          _logger.warning('Failed to create event in Google Calendar: $e');
          // Continue even if Google Calendar sync fails
        }
      }
    } catch (e) {
      _logger.warning('Error creating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      final event = _events.firstWhere((e) => e.id == id);
      
      // Only allow deleting user-created events
      if (event.source != EventSource.userCreated) {
        throw Exception('Can only delete user-created events');
      }

      // Delete from local database
      await _db.delete('events', where: 'id = ?', whereArgs: [id]);
      
      // Remove from memory
      _events.removeWhere((e) => e.id == id);
      notifyListeners();

      // If Google Calendar is connected, delete from there
      if (_googleCalendarApi != null && event.externalId != null) {
        try {
          await _googleCalendarApi!.events.delete(
            'primary',
            event.externalId!,
          );
        } catch (e) {
          _logger.warning('Failed to delete event from Google Calendar: $e');
          // Continue even if Google Calendar sync fails
        }
      }

    } catch (e) {
      _logger.warning('Error deleting event: $e');
      rethrow;
    }
  }

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
        externalId: existingEvent.externalId,
      );

      // Update in local database
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

      // If Google Calendar is connected and event has externalId, update there
      if (_googleCalendarApi != null && updatedEvent.externalId != null) {
        try {
          final startDateTime = google_calendar.EventDateTime()
            ..dateTime = updatedEvent.startTime
            ..timeZone = 'UTC';

          final endDateTime = google_calendar.EventDateTime()
            ..dateTime = updatedEvent.endTime
            ..timeZone = 'UTC';

          final googleEvent = google_calendar.Event()
            ..summary = updatedEvent.title
            ..description = updatedEvent.description
            ..start = startDateTime
            ..end = endDateTime;

          await _googleCalendarApi!.events.update(
            googleEvent,
            'primary',
            updatedEvent.externalId!,
          );
        } catch (e) {
          _logger.warning('Failed to update event in Google Calendar: $e');
          // Continue even if Google Calendar sync fails
        }
      }

    } catch (e) {
      _logger.warning('Error updating event: $e');
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
}