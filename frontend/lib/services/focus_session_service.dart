// lib/services/focus_session_service.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/focus_session.dart';
import 'sync_service.dart';
import 'package:uuid/uuid.dart';

class FocusSessionService extends ChangeNotifier {
  final SyncService _syncService;
  List<FocusSession> _sessions = [];
  
  FocusSessionService(this._syncService) {
    _loadSessions();
  }

  List<FocusSession> get sessions => _sessions;
  
  Future<void> _loadSessions() async {
    try {
      final db = await _syncService.database;
      final data = await db.query('focus_sessions', orderBy: 'start_time DESC');
      _sessions = data.map((e) => FocusSession.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading focus sessions: $e');
    }
  }

  Future<String> startSession({
    required int durationMinutes,
    String? topic,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();
      
      final session = FocusSession(
        id: id,
        startTime: now,
        endTime: now.add(Duration(minutes: durationMinutes)),
        durationMinutes: durationMinutes,
        topic: topic,
        distractions: [],
        focusRating: 0,
        isCompleted: false,
      );

      final db = await _syncService.database;
      await db.insert(
        'focus_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _sessions.insert(0, session);
      notifyListeners();
      
      return id;
    } catch (e) {
      print('Error starting focus session: $e');
      rethrow;
    }
  }

  Future<void> completeSession(
    String id, {
    required int focusRating,
    List<String>? distractions,
  }) async {
    try {
      final index = _sessions.indexWhere((s) => s.id == id);
      if (index == -1) return;
      
      final session = _sessions[index];
      final updatedSession = FocusSession(
        id: session.id,
        startTime: session.startTime,
        endTime: DateTime.now(),
        durationMinutes: session.durationMinutes,
        topic: session.topic,
        distractions: distractions,
        focusRating: focusRating,
        isCompleted: true,
      );

      final db = await _syncService.database;
      await db.update(
        'focus_sessions',
        updatedSession.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      _sessions[index] = updatedSession;
      notifyListeners();

      _syncService.queueChange({
        'type': 'focus_session',
        'action': 'update',
        'data': updatedSession.toMap(),
      });
    } catch (e) {
      print('Error completing focus session: $e');
      rethrow;
    }
  }

  int getTotalFocusMinutesToday() {
    final today = DateTime.now();
    return _sessions
        .where((s) => 
            s.isCompleted && 
            s.startTime.day == today.day &&
            s.startTime.month == today.month &&
            s.startTime.year == today.year)
        .fold(0, (sum, session) => sum + session.durationMinutes);
  }

  List<MapEntry<String, int>> getCommonDistractions() {
    final distractionCount = <String, int>{};
    
    for (final session in _sessions.where((s) => s.isCompleted)) {
      if (session.distractions != null) {
        for (final distraction in session.distractions!) {
          distractionCount[distraction] = (distractionCount[distraction] ?? 0) + 1;
        }
      }
    }
    
    final entries = distractionCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return entries.take(5).map((e) => MapEntry(e.key, e.value)).toList();
  }
}