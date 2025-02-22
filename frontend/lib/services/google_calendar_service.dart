// lib/services/google_calendar_service.dart
import 'package:frontend/models/calendar_event.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleCalendarService {
  static const _scopes = [google_calendar.CalendarApi.calendarReadonlyScope];
  final _prefs = SharedPreferences.getInstance();
  google_calendar.CalendarApi? _calendarApi;

  // Your Google Cloud project credentials
  final _clientId = ClientId(
    'YOUR_CLIENT_ID',
    'YOUR_CLIENT_SECRET',
  );

  Future<bool> isConnected() async {
    final prefs = await _prefs;
    return prefs.getString('google_access_token') != null;
  }

  Future<void> connect() async {
    try {
      final client = await clientViaUserConsent(
        _clientId,
        _scopes,
        (url) async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            throw Exception('Could not launch $url');
          }
        },
      );

      _calendarApi = google_calendar.CalendarApi(client);
      
      // Save access token
      final prefs = await _prefs;
      await prefs.setString('google_access_token', client.credentials.accessToken.data);
    } catch (e) {
      print('Error connecting to Google Calendar: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    final prefs = await _prefs;
    await prefs.remove('google_access_token');
    _calendarApi = null;
  }

  Future<List<CalendarEvent>> fetchEvents({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (_calendarApi == null) {
      throw Exception('Not connected to Google Calendar');
    }

    try {
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: startTime?.toUtc(),
        timeMax: endTime?.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      return _convertGoogleEventsToCalendarEvents(events.items ?? []);
    } catch (e) {
      print('Error fetching Google Calendar events: $e');
      return [];
    }
  }

  List<CalendarEvent> _convertGoogleEventsToCalendarEvents(
    List<google_calendar.Event> googleEvents,
  ) {
    return googleEvents.map((googleEvent) {
      final start = googleEvent.start?.dateTime ?? DateTime.now();
      final end = googleEvent.end?.dateTime ?? start.add(const Duration(hours: 1));

      return CalendarEvent(
        id: googleEvent.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: googleEvent.summary ?? 'Untitled Event',
        startTime: start,
        endTime: end,
        description: googleEvent.description,
        source: EventSource.googleCalendar,
        externalId: googleEvent.id,
      );
    }).toList();
  }
}