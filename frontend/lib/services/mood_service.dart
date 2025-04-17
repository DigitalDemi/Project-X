import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/mood_entry.dart';
import 'sync_service.dart';
import 'package:uuid/uuid.dart';

class MoodService extends ChangeNotifier {
  final SyncService _syncService;
  List<MoodEntry> _entries = [];
  
  MoodService(this._syncService) {
    _loadEntries();
  }

  List<MoodEntry> get entries => _entries;
  
  double get averageMoodToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todayEntries = _entries.where((e) => 
      e.timestamp.year == today.year && 
      e.timestamp.month == today.month && 
      e.timestamp.day == today.day
    ).toList();
    
    if (todayEntries.isEmpty) return 0;
    
    final sum = todayEntries.fold(0, (sum, entry) => sum + entry.rating);
    return sum / todayEntries.length;
  }

  Future<void> _loadEntries() async {
    try {
      final db = await _syncService.database;
      final data = await db.query('mood_entries', orderBy: 'timestamp DESC');
      _entries = data.map((e) => MoodEntry.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading mood entries: $e');
      }
    }
  }

  Future<void> addEntry({
    required int rating,
    String? note,
    List<String> factors = const [],
  }) async {
    try {
      final id = const Uuid().v4();
      
      final entry = MoodEntry(
        id: id,
        timestamp: DateTime.now(),
        rating: rating,
        note: note,
        factors: factors,
      );

      final db = await _syncService.database;
      await db.insert(
        'mood_entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _entries.insert(0, entry);
      notifyListeners();

      _syncService.queueChange({
        'type': 'mood_entry',
        'action': 'create',
        'data': entry.toMap(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding mood entry: $e');
      }
      rethrow;
    }
  }

  Map<String, int> getCommonFactors() {
    final Map<String, int> factorCount = {};
    
    for (final entry in _entries) {
      for (final factor in entry.factors) {
        factorCount[factor] = (factorCount[factor] ?? 0) + 1;
      }
    }
    
    return factorCount;
  }

  List<Map<String, dynamic>> getMoodTrend({int days = 7}) {
    // Group by day and calculate average mood
    final Map<String, List<int>> moodsByDay = {};
    final now = DateTime.now();
    
    // Include past 'days' days
    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      moodsByDay[dateKey] = [];
    }
    
    for (final entry in _entries) {
      final date = entry.timestamp;
      if (now.difference(date).inDays < days) {
        final dateKey = '${date.year}-${date.month}-${date.day}';
        moodsByDay.putIfAbsent(dateKey, () => []).add(entry.rating);
      }
    }
    
    // Calculate averages
    final List<Map<String, dynamic>> trend = [];
    
    moodsByDay.forEach((dateKey, moods) {
      final parts = dateKey.split('-');
      final date = DateTime(
        int.parse(parts[0]), 
        int.parse(parts[1]), 
        int.parse(parts[2]),
      );
      
      final avgMood = moods.isEmpty 
          ? null 
          : moods.reduce((a, b) => a + b) / moods.length;
      
      trend.add({
        'date': date,
        'mood': avgMood,
      });
    });
    
    // Sort by date
    trend.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    return trend;
  }

  List<Map<String, dynamic>> getHourlyMoodPattern() {
    // Group by hour and calculate average mood
    final Map<int, List<int>> moodsByHour = {};
    
    // Initialize all hours
    for (var hour = 0; hour < 24; hour++) {
      moodsByHour[hour] = [];
    }
    
    // Add data
    for (final entry in _entries) {
      final hour = entry.timestamp.hour;
      moodsByHour[hour]!.add(entry.rating);
    }
    
    // Calculate averages
    final List<Map<String, dynamic>> hourlyPattern = [];
    
    moodsByHour.forEach((hour, moods) {
      final avgMood = moods.isEmpty 
          ? null 
          : moods.reduce((a, b) => a + b) / moods.length;
      
      hourlyPattern.add({
        'hour': hour,
        'mood': avgMood,
      });
    });
    
    return hourlyPattern;
  }
}