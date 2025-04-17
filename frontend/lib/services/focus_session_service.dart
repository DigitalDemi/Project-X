import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart'; // For generating IDs

import '../models/focus_session.dart'; 
import 'sync_service.dart';

class FocusSessionService extends ChangeNotifier {
  final SyncService _dbService; 
  List<FocusSession> _sessions = [];
  final _uuid = const Uuid(); // UUID generator

  FocusSessionService(this._dbService) {
    _loadSessions();
  }

  // Return an unmodifiable view to prevent direct list modification from UI
  List<FocusSession> get sessions => List.unmodifiable(_sessions);


  Future<Database> get _db async => await _dbService.database; // Helper getter for DB

  Future<void> _loadSessions() async {
    debugPrint("--- FocusSessionService: _loadSessions called ---");
    try {
      final db = await _db;
      final data = await db.query('focus_sessions', orderBy: 'start_time DESC');
      debugPrint("Raw data loaded from DB: ${data.length} rows");
      if (data.isNotEmpty) {
         debugPrint("First raw row: ${data.first}");
      }

      // Safely map raw data to FocusSession objects
      final List<FocusSession> loadedSessions = [];
      for (final map in data) {
         try {
            debugPrint("Mapping row: $map");
            final session = FocusSession.fromMap(map); // Uses JSON decoding
            debugPrint("Mapped to session: ID=${session.id}, Completed=${session.isCompleted}, Distractions=${session.distractions}");
            loadedSessions.add(session);
         } catch (e, stackTrace) {
            debugPrint("!!!!!! Error converting map to FocusSession: $map \nError: $e\n$stackTrace");
         }
      }
      _sessions = loadedSessions;

      debugPrint("Sessions list populated: ${_sessions.length} sessions.");
      notifyListeners(); // Notify UI of changes
    } catch (e, stackTrace) {
      debugPrint('!!!!!! Error loading focus sessions from DB: $e\n$stackTrace');
    }
  }

  Future<String> startSession({
    required int durationMinutes,
    String? topic,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    debugPrint("--- FocusSessionService: startSession called ---");

    final session = FocusSession(
      id: id,
      startTime: now,
      endTime: now.add(Duration(minutes: durationMinutes)), // Planned end time
      durationMinutes: durationMinutes,
      topic: topic,
      distractions: [], // Start with empty list
      focusRating: 0,
      isCompleted: false, // Session starts as incomplete
    );

    try {
      final db = await _db;
      final dataToInsert = session.toMap(); // Use toMap for correct format
      debugPrint("Inserting session: $dataToInsert");
      await db.insert(
        'focus_sessions',
        dataToInsert,
        conflictAlgorithm: ConflictAlgorithm.replace, // Replace if ID exists
      );

      // Add to the beginning of the in-memory list for immediate UI update
      _sessions.insert(0, session);
      notifyListeners();
      debugPrint('Focus session started and saved: $id');
      return id; // Return the generated ID
    } catch (e, stackTrace) {
      debugPrint('!!!!!! Error starting and saving focus session: $e\n$stackTrace');
      rethrow; // Rethrow to indicate failure to the UI layer
    }
  }

  Future<void> completeSession({
    required String id,
    required int focusRating,
    List<String>? distractions,
    required bool wasCompleted, // Differentiates finish vs stop
  }) async {
    debugPrint("--- FocusSessionService: completeSession called for ID: $id ---");
    debugPrint("Was Completed: $wasCompleted");
    debugPrint("Distractions received: $distractions");
    debugPrint("Focus rating received: $focusRating");

    // Find the session in the current in-memory list
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) {
       debugPrint("Error: Session $id not found in memory list for update.");
       return;
    }

    final existingSession = _sessions[index];

    // Create the updated session data based on completion status
    final updatedSession = FocusSession(
      id: existingSession.id,
      startTime: existingSession.startTime,
      endTime: DateTime.now(), // Mark the actual end time
      durationMinutes: existingSession.durationMinutes, // Keep original duration
      topic: existingSession.topic,
      distractions: distractions, // Use the provided distractions
      focusRating: wasCompleted ? focusRating : 0, // Rating is 0 if stopped
      isCompleted: wasCompleted, // Set completion flag
    );

    debugPrint("Updated session object created: ID=${updatedSession.id}, Completed=${updatedSession.isCompleted}, Distractions=${updatedSession.distractions}");

    // Prepare data for database update using toMap (ensures JSON encoding)
    final Map<String, dynamic> dataToSave = updatedSession.toMap();
    debugPrint("Data prepared for DB update (using toMap()): $dataToSave");

    try {
      final db = await _db;
      int count = await db.update(
        'focus_sessions',
        dataToSave, // Use the map from toMap()
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint("Database update result count: $count for ID: $id");

      // If the database update was successful, update the in-memory list
      if (count > 0) {
         _sessions[index] = updatedSession;
         debugPrint("Session $id updated in memory and DB. Notifying listeners.");
         notifyListeners(); // Notify UI about the change

      } else {
         debugPrint("Warning: Database update reported 0 rows affected for ID: $id.");
       
      }

    } catch (e, stackTrace) {
      debugPrint('!!!!!! Error completing/updating focus session $id in DB: $e\n$stackTrace');
    }
  }


  // Calculates total focus minutes for *completed* sessions today
  int getTotalFocusMinutesToday() {
    final today = DateTime.now();
    // More robust date comparison
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _sessions
        .where((s) =>
            s.isCompleted && // Only count completed sessions for time
            s.startTime.isAfter(startOfDay) &&
            s.startTime.isBefore(endOfDay))
        .fold(0, (sum, session) => sum + session.durationMinutes);
  }

  // Calculates common distractions from *ALL* sessions (Option B)
  List<MapEntry<String, int>> getCommonDistractions() {
    debugPrint("--- FocusSessionService: getCommonDistractions called ---");
    debugPrint("Total sessions in memory: ${_sessions.length}");
    final distractionCount = <String, int>{};

    // Iterate over ALL sessions, regardless of completion status
    debugPrint("Processing ALL sessions for distractions.");
    for (final session in _sessions) {
       debugPrint("Processing session ID: ${session.id}, Completed=${session.isCompleted}, Distractions: ${session.distractions}");
       // Safely check and process distractions list
       if (session.distractions != null && session.distractions!.isNotEmpty) {
          for (final distraction in session.distractions!) {
             // Normalize for accurate counting (trim whitespace, lowercase)
             final normalizedDistraction = distraction.trim().toLowerCase();
             if (normalizedDistraction.isNotEmpty) {
                distractionCount[normalizedDistraction] = (distractionCount[normalizedDistraction] ?? 0) + 1;
             }
          }
       }
    }

    debugPrint("Calculated distraction counts (from ALL sessions): $distractionCount");

    // Sort distractions by frequency (most frequent first)
    final entries = distractionCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort descending by count

    // Return the top 5 entries
    final top5 = entries.take(5).toList();
    debugPrint("Returning top 5 distractions: $top5");
    return top5;
  }
}