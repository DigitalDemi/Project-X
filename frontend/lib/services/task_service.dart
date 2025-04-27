// lib/services/task_service.dart

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart'; // Ensure sqflite types (Database) are available
// Make sure this path points correctly to your Task model definition
// and that the Task model has the toJson() and fromJson() methods.
import '../models/task.dart';
import 'sync_service.dart'; // Assuming this service exists and provides the database
import 'package:logging/logging.dart'; // For logging

// Manages task data, interacts with local storage, and queues changes for synchronization.
class TaskService extends ChangeNotifier {
  final SyncService _syncService; // Service to handle synchronization logic
  final _logger = Logger('TaskService'); // Logger instance for this service
  List<Task> _tasks = []; // In-memory list of tasks

  // Constructor: Initializes the service and loads initial data.
  TaskService(this._syncService) {
    _loadLocalTasks();
  }

  // --- Getters for accessing task lists ---
  List<Task> get tasks => List.unmodifiable(_tasks); // Read-only view of all tasks
  List<Task> get completedTasks => List.unmodifiable(_tasks.where((task) => task.isCompleted)); // Read-only view of completed tasks
  List<Task> get pendingTasks => List.unmodifiable(_tasks.where((task) => !task.isCompleted)); // Read-only view of pending tasks

  // --- Core Methods ---

  // Loads tasks from the local SQLite database into the in-memory list.
  Future<void> _loadLocalTasks() async {
    try {
      // Get database instance from SyncService (ensure it returns Future<Database>)
      final Database db = await _syncService.database;
      // Query the 'tasks' table, order by ID descending (newest first)
      final List<Map<String, Object?>> localTasksMaps = await db.query('tasks', orderBy: 'id DESC');
      // Convert map data from DB into Task objects using the fromJson factory
      _tasks = localTasksMaps.map((map) => Task.fromJson(map)).toList();
      notifyListeners(); // Notify UI that tasks have been loaded/updated
      _logger.info('Loaded ${_tasks.length} tasks from local database.');
    } catch (e, stackTrace) {
      _logger.severe('Error loading tasks from local database: $e', e, stackTrace);
      // Consider how to handle loading errors (e.g., show error message to user)
    }
  }

  // Creates a new task, saves it locally, and queues for sync.
  Future<void> createTask(Map<String, dynamic> taskData) async {
    try {
      // --- Input Validation ---
      final String? title = taskData['title'] as String?;
      final String? duration = taskData['duration'] as String?;
      final String? energyLevel = taskData['energyLevel'] as String?;

      // Ensure required fields are present and not empty
      if (title == null || title.trim().isEmpty) throw ArgumentError('Task title required.');
      if (duration == null || duration.trim().isEmpty) throw ArgumentError('Task duration required.');
      if (energyLevel == null || energyLevel.trim().isEmpty) throw ArgumentError('Task energy level required.');
      // --- End Validation ---

      final Database db = await _syncService.database;
      // Create Task object using its constructor
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple local ID generation
        title: title.trim(),
        duration: duration.trim(),
        energyLevel: energyLevel.trim(),
        // isCompleted defaults to false in the Task model constructor
      );

      // Insert the new task into the database, using toJson() for the data map
      await db.insert(
        'tasks', // Ensure this table name is correct
        newTask.toJson(), // Correct method call
        conflictAlgorithm: ConflictAlgorithm.replace, // How to handle ID conflicts
      );

      _tasks.insert(0, newTask); // Add to the start of the in-memory list
      notifyListeners(); // Update UI
      _logger.info('Task created locally: ${newTask.id}');

      // Queue this creation action for the SyncService
      _syncService.queueChange({
        'type': 'task',
        'action': 'create',
        'data': newTask.toJson(), // Pass the task data
      });
    } catch (e, stackTrace) {
      _logger.severe('Error creating task: $e', e, stackTrace);
      rethrow; // Allow higher layers (UI) to potentially catch and handle
    }
  }

  // Toggles the 'isCompleted' status of a task.
  Future<void> toggleTask(String? id) async {
    if (id == null) {
       _logger.warning('Toggle task: null ID provided.');
       return; // Cannot proceed without an ID
    }

    try {
      // Find the task in the in-memory list
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index == -1) {
         _logger.warning('Toggle task $id: Task not found in memory.');
         return;
      }

      final task = _tasks[index];
      // Create an updated task object with the flipped completion status
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

      final Database db = await _syncService.database;
      // Update the task in the database
      final int rowsAffected = await db.update(
        'tasks',
        updatedTask.toJson(), // Data to update
        where: 'id = ?',      // Condition to find the right row
        whereArgs: [id],      // Arguments for the where clause
      );

       // Log whether the database update was successful
       if (rowsAffected == 0) { _logger.warning('Toggle task $id: No rows updated in DB.'); }
       else { _logger.info('Task $id completion toggled to ${updatedTask.isCompleted}.'); }

      // Update the task in the in-memory list
      _tasks[index] = updatedTask;
      notifyListeners(); // Update UI

      // Queue this update action for the SyncService
      _syncService.queueChange({
        'type': 'task',
        'action': 'update', // Toggling is considered an update
        'data': updatedTask.toJson(), // Pass the updated task data
      });
    } catch (e, stackTrace) {
      _logger.severe('Error toggling task $id: $e', e, stackTrace);
      rethrow;
    }
  }

  // Updates specific fields of an existing task.
  Future<void> updateTask(String? id, Map<String, dynamic> updates) async {
    if (id == null) {
       _logger.warning('Update task: null ID provided.');
       return;
    }

    try {
      // Find the task in the in-memory list
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index == -1) {
         _logger.warning('Update task $id: Task not found in memory.');
         return;
      }

      final existingTask = _tasks[index];
      // Create updated task using copyWith, applying only provided updates
      // Falls back to existing values if an update field is missing/null
      final updatedTask = existingTask.copyWith(
        title: updates['title'] as String? ?? existingTask.title,
        energyLevel: updates['energyLevel'] as String? ?? existingTask.energyLevel,
        duration: updates['duration'] as String? ?? existingTask.duration,
        imagePath: updates['imagePath'] as String? ?? existingTask.imagePath,
        // Optionally include isCompleted if it can be updated via this method
        // isCompleted: updates['isCompleted'] as bool? ?? existingTask.isCompleted,
      );

      final Database db = await _syncService.database;
      // Update the task in the database
      final int rowsAffected = await db.update(
        'tasks',
        updatedTask.toJson(), // Updated data
        where: 'id = ?',
        whereArgs: [id],
      );

      // Log whether the update was successful
      if (rowsAffected == 0) { _logger.warning('Update task $id: No rows updated in DB.'); }
      else { _logger.info('Task $id updated.'); }

      // Update the task in the in-memory list
      _tasks[index] = updatedTask;
      notifyListeners(); // Update UI

      // Queue this update action for the SyncService
      _syncService.queueChange({
        'type': 'task',
        'action': 'update',
        'data': updatedTask.toJson(), // Pass the full updated task data
      });
    } catch (e, stackTrace) {
      _logger.severe('Error updating task $id: $e', e, stackTrace);
      rethrow;
    }
  }

  // Deletes a task from local storage and queues the deletion for sync.
  Future<void> deleteTask(String id) async {
    try {
      final Database db = await _syncService.database;
      // Delete the task from the database and get the number of rows affected
      // **Explicitly type the result as int** to resolve analyzer issues
      final int rowsAffected = await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Log whether the deletion was successful in the DB
      if (rowsAffected == 0) {
        _logger.warning('Delete task $id: No rows deleted from DB (already deleted?).');
      } else {
        _logger.info('Task $id deleted locally from DB.');
      }

      // Check the length before removal
      final lengthBefore = _tasks.length;
      // Remove the task from the in-memory list
      _tasks.removeWhere((t) => t.id == id);
      // Check if any task was actually removed
      final removed = _tasks.length < lengthBefore;
      // Only notify listeners if a task was actually removed from the list
      if(removed){
          notifyListeners(); // Update UI
          _logger.info('Task $id removed from in-memory list.');
      } else {
           _logger.warning('Task $id was not found in the in-memory list during deletion.');
      }

      // Queue this delete action for the SyncService
      _syncService.queueChange({
        'type': 'task',
        'action': 'delete',
        'data': {'id': id}, // Only the ID is typically needed for deletion sync
      });
    } catch (e, stackTrace) {
      _logger.severe('Error deleting task $id: $e', e, stackTrace);
      rethrow;
    }
  }

  // --- Helper Methods ---

  // Filters tasks by energy level (example).
  List<Task> getTasksByEnergyLevel(String energyLevel) {
    // Use toUpperCase for case-insensitive comparison
    return List.unmodifiable(_tasks.where((task) => task.energyLevel.toUpperCase() == energyLevel.toUpperCase()));
  }

  // --- Potentially add other methods like: ---
  // Future<void> syncTasks() async { ... } // Method to trigger manual sync
  // Task? getTaskById(String id) { ... } // Method to find a single task
}