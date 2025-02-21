// lib/services/calendar_service.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/meeting.dart';
import 'sync_service.dart';
import 'package:logging/logging.dart';

class CalendarService extends ChangeNotifier {
  final SyncService _syncService;
  final _logger = Logger('CalendarService');
  List<Meeting> _meetings = [];

  CalendarService(this._syncService) {
    _loadLocalMeetings();
  }

  List<Meeting> get meetings => _meetings;

  Future<void> _loadLocalMeetings() async {
    try {
      final db = await _syncService.database;
      final localMeetings = await db.query('meetings');
      _meetings = localMeetings.map((m) => Meeting.fromMap(m)).toList();
      notifyListeners();
    } catch (e) {
      _logger.warning('Error loading meetings: $e');
    }
  }

  Future<void> createMeeting(Map<String, dynamic> meetingData) async {
    try {
      final db = await _syncService.database;
      
      // Validate required fields
      if (!meetingData.containsKey('title') ||
          !meetingData.containsKey('start_time') ||
          !meetingData.containsKey('end_time')) {
        throw ArgumentError('Missing required meeting data');
      }

      final meeting = Meeting(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: meetingData['title'] as String,
        startTime: DateTime.parse(meetingData['start_time'] as String),
        endTime: DateTime.parse(meetingData['end_time'] as String),
        description: meetingData['description'] as String?,
      );

      await db.insert(
        'meetings',
        meeting.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _meetings.add(meeting);
      notifyListeners();

      _syncService.queueChange({
        'type': 'meeting',
        'action': 'create',
        'data': meeting.toMap(),
      });
    } catch (e) {
      _logger.warning('Error creating meeting: $e');
      rethrow;
    }
  }

  Future<void> deleteMeeting(String? id) async {
    if (id == null) return;

    try {
      final db = await _syncService.database;
      await db.delete(
        'meetings',
        where: 'id = ?',
        whereArgs: [id],
      );

      _meetings.removeWhere((m) => m.id == id);
      notifyListeners();

      _syncService.queueChange({
        'type': 'meeting',
        'action': 'delete',
        'data': {'id': id},
      });
    } catch (e) {
      _logger.warning('Error deleting meeting: $e');
      rethrow;
    }
  }

  List<Meeting> getMeetingsForDate(DateTime date) {
    return _meetings.where((meeting) {
      final meetingDate = meeting.startTime;
      return meetingDate.year == date.year &&
             meetingDate.month == date.month &&
             meetingDate.day == date.day;
    }).toList();
  }

  Future<void> updateMeeting(String id, Map<String, dynamic> updates) async {
    try {
      final index = _meetings.indexWhere((m) => m.id == id);
      if (index == -1) return;

      final oldMeeting = _meetings[index];
      final newMeeting = Meeting(
        id: id,
        title: updates['title'] as String? ?? oldMeeting.title,
        startTime: updates['start_time'] != null 
          ? DateTime.parse(updates['start_time'] as String)
          : oldMeeting.startTime,
        endTime: updates['end_time'] != null
          ? DateTime.parse(updates['end_time'] as String)
          : oldMeeting.endTime,
        description: updates['description'] as String? ?? oldMeeting.description,
      );

      final db = await _syncService.database;
      await db.update(
        'meetings',
        newMeeting.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      _meetings[index] = newMeeting;
      notifyListeners();

      _syncService.queueChange({
        'type': 'meeting',
        'action': 'update',
        'data': newMeeting.toMap(),
      });
    } catch (e) {
      _logger.warning('Error updating meeting: $e');
      rethrow;
    }
  }
}