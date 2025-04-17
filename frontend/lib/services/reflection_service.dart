import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/reflection.dart';
import 'sync_service.dart';
import 'package:uuid/uuid.dart';

class ReflectionService extends ChangeNotifier {
  final SyncService _syncService;
  List<Reflection> _reflections = [];
  
  ReflectionService(this._syncService) {
    _loadReflections();
  }

  List<Reflection> get reflections => _reflections;
  
  bool get hasTodayReflection {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _reflections.any((r) => 
      r.date.year == today.year && 
      r.date.month == today.month && 
      r.date.day == today.day
    );
  }

  Future<void> _loadReflections() async {
    try {
      final db = await _syncService.database;
      final data = await db.query('reflections', orderBy: 'date DESC');
      _reflections = data.map((e) => Reflection.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reflections: $e');
      }
    }
  }

  Future<void> addReflection({
    required String content,
    List<String> tags = const [],
    int? moodRating,
    int? productivityRating,
    String? focusArea,
  }) async {
    try {
      final id = const Uuid().v4();
      
      final reflection = Reflection(
        id: id,
        date: DateTime.now(),
        content: content,
        tags: tags,
        moodRating: moodRating,
        productivityRating: productivityRating,
        focusArea: focusArea,
      );

      final db = await _syncService.database;
      await db.insert(
        'reflections',
        reflection.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _reflections.insert(0, reflection);
      notifyListeners();

      _syncService.queueChange({
        'type': 'reflection',
        'action': 'create',
        'data': reflection.toMap(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding reflection: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteReflection(String reflectionId) async {
    try {
      final db = await _syncService.database;
      await db.delete(
        'reflections',
        where: 'id = ?',
        whereArgs: [reflectionId],
      );

      _reflections.removeWhere((r) => r.id == reflectionId);
      notifyListeners();

      _syncService.queueChange({
        'type': 'reflection',
        'action': 'delete',
        'data': {'id': reflectionId},
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting reflection: $e');
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> getMoodTrend() {
    // Group by day and calculate average mood
    final Map<String, List<int>> moodsByDay = {};
    
    for (final reflection in _reflections) {
      if (reflection.moodRating != null) {
        final dateKey = '${reflection.date.year}-${reflection.date.month}-${reflection.date.day}';
        moodsByDay.putIfAbsent(dateKey, () => []).add(reflection.moodRating!);
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
      
      final avgMood = moods.reduce((a, b) => a + b) / moods.length;
      
      trend.add({
        'date': date,
        'mood': avgMood,
      });
    });
    
    // Sort by date
    trend.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    return trend;
  }

  Map<String, int> getCommonTags() {
    final Map<String, int> tagCount = {};
    
    for (final reflection in _reflections) {
      for (final tag in reflection.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    
    return tagCount;
  }
}