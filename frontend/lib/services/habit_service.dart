// lib/services/habit_service.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/habit.dart';
import 'sync_service.dart';
import 'package:uuid/uuid.dart';

class HabitService extends ChangeNotifier {
  final SyncService _syncService;
  List<Habit> _habits = [];
  
  HabitService(this._syncService) {
    _loadHabits();
  }

  List<Habit> get habits => _habits;
  
  List<Habit> get todayHabits => _habits.where((h) => h.isDueToday()).toList();
  
  int get completedTodayCount => todayHabits.where((h) => h.isCompletedToday()).length;
  
  double get todayCompletionRate => 
      todayHabits.isEmpty ? 0 : completedTodayCount / todayHabits.length;

  Future<void> _loadHabits() async {
    try {
      final db = await _syncService.database;
      final data = await db.query('habits');
      _habits = data.map((e) => Habit.fromMap(e)).toList();
      
      // Update streaks for all habits
      for (var i = 0; i < _habits.length; i++) {
        _habits[i] = _calculateStreaks(_habits[i]);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading habits: $e');
    }
  }

  Future<void> createHabit({
    required String title,
    String? description,
    required String frequency,
    List<int>? weekdays,
    String? timeOfDay,
  }) async {
    try {
      final id = const Uuid().v4();
      
      final habit = Habit(
        id: id,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        frequency: frequency,
        weekdays: weekdays,
        timeOfDay: timeOfDay,
      );

      final db = await _syncService.database;
      await db.insert(
        'habits',
        habit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _habits.add(habit);
      notifyListeners();

      _syncService.queueChange({
        'type': 'habit',
        'action': 'create',
        'data': habit.toMap(),
      });
    } catch (e) {
      print('Error creating habit: $e');
      rethrow;
    }
  }

  Future<void> toggleHabit(String habitId) async {
    try {
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index == -1) return;
      
      final habit = _habits[index];
      final completionDates = List<DateTime>.from(habit.completionDates);
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if already completed today
      final isCompletedToday = habit.isCompletedToday();
      
      if (isCompletedToday) {
        // Remove today's completion
        completionDates.removeWhere((date) => 
          date.year == today.year && 
          date.month == today.month && 
          date.day == today.day
        );
      } else {
        // Add today's completion
        completionDates.add(today);
      }
      
      // Calculate new streaks
      final updatedHabit = habit.copyWith(
        completionDates: completionDates,
      );
      
      final finalHabit = _calculateStreaks(updatedHabit);

      final db = await _syncService.database;
      await db.update(
        'habits',
        finalHabit.toMap(),
        where: 'id = ?',
        whereArgs: [habitId],
      );

      _habits[index] = finalHabit;
      notifyListeners();

      _syncService.queueChange({
        'type': 'habit',
        'action': 'update',
        'data': finalHabit.toMap(),
      });
    } catch (e) {
      print('Error toggling habit: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      final db = await _syncService.database;
      await db.delete(
        'habits',
        where: 'id = ?',
        whereArgs: [habitId],
      );

      _habits.removeWhere((h) => h.id == habitId);
      notifyListeners();

      _syncService.queueChange({
        'type': 'habit',
        'action': 'delete',
        'data': {'id': habitId},
      });
    } catch (e) {
      print('Error deleting habit: $e');
      rethrow;
    }
  }

  Habit _calculateStreaks(Habit habit) {
    if (habit.completionDates.isEmpty) {
      return habit.copyWith(currentStreak: 0, longestStreak: 0);
    }
    
    // Sort dates in ascending order
    final dates = List<DateTime>.from(habit.completionDates)
      ..sort((a, b) => a.compareTo(b));
    
    // Initialize variables
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? previousDate;
    
    for (final date in dates) {
      // Clean date (remove time)
      final cleanDate = DateTime(date.year, date.month, date.day);
      
      if (previousDate == null) {
        tempStreak = 1;
      } else {
        // Check if consecutive day
        final difference = cleanDate.difference(previousDate!).inDays;
        
        if (difference == 1) {
          // Consecutive day
          tempStreak += 1;
        } else if (difference == 0) {
          // Same day, ignore
          continue;
        } else {
          // Streak broken
          tempStreak = 1;
        }
      }
      
      previousDate = cleanDate;
      longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
    }
    
    // Check if the streak is still active (last completion was yesterday or today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (previousDate != null && (
        previousDate == today || previousDate == yesterday)) {
      currentStreak = tempStreak;
    } else {
      currentStreak = 0;
    }
    
    return habit.copyWith(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }
}