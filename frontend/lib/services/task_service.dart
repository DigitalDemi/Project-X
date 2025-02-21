// lib/services/task_service.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import 'sync_service.dart';
import 'package:logging/logging.dart';

class TaskService extends ChangeNotifier {
  final SyncService _syncService;
  final _logger = Logger('TaskService');
  List<Task> _tasks = [];

  TaskService(this._syncService) {
    _loadLocalTasks();
  }

  List<Task> get tasks => _tasks;
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  List<Task> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();

  Future<void> _loadLocalTasks() async {
    try {
      final db = await _syncService.database;
      final localTasks = await db.query('tasks', orderBy: 'created_at DESC');
      _tasks = localTasks.map((t) => Task.fromMap(t)).toList();
      notifyListeners();
    } catch (e) {
      _logger.warning('Error loading tasks: $e');
    }
  }

  Future<void> createTask(Map<String, dynamic> taskData) async {
    try {
      // Validate required data
      if (!taskData.containsKey('title')) {
        throw ArgumentError('Task title is required');
      }

      final db = await _syncService.database;
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: taskData['title'] as String,
        createdAt: DateTime.now(),
        energyLevel: taskData['energy_level'] as String?,
        duration: taskData['duration'] as String?,
      );

      await db.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _tasks.insert(0, task); // Add to beginning of list
      notifyListeners();

      _syncService.queueChange({
        'type': 'task',
        'action': 'create',
        'data': task.toMap(),
      });
    } catch (e) {
      _logger.warning('Error creating task: $e');
      rethrow;
    }
  }

  Future<void> toggleTask(String? id) async {
    if (id == null) return;

    try {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index == -1) return;

      final task = _tasks[index];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

      final db = await _syncService.database;
      await db.update(
        'tasks',
        updatedTask.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      _tasks[index] = updatedTask;
      notifyListeners();

      _syncService.queueChange({
        'type': 'task',
        'action': 'update',
        'data': updatedTask.toMap(),
      });
    } catch (e) {
      _logger.warning('Error toggling task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(String? id, Map<String, dynamic> updates) async {
    if (id == null) return;

    try {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index == -1) return;

      final existingTask = _tasks[index];
      final updatedTask = existingTask.copyWith(
        title: updates['title'] as String?,
        energyLevel: updates['energy_level'] as String?,
        duration: updates['duration'] as String?,
      );

      final db = await _syncService.database;
      await db.update(
        'tasks',
        updatedTask.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      _tasks[index] = updatedTask;
      notifyListeners();

      _syncService.queueChange({
        'type': 'task',
        'action': 'update',
        'data': updatedTask.toMap(),
      });
    } catch (e) {
      _logger.warning('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final db = await _syncService.database;
      await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );

      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();

      _syncService.queueChange({
        'type': 'task',
        'action': 'delete',
        'data': {'id': id},
      });
    } catch (e) {
      _logger.warning('Error deleting task: $e');
      rethrow;
    }
  }

  List<Task> getTasksByEnergyLevel(String energyLevel) {
    return _tasks.where((task) => task.energyLevel == energyLevel).toList();
  }
}