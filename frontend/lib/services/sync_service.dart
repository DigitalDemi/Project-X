import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'local_database.dart';
import 'api_service.dart';     
import 'package:logging/logging.dart';

class SyncConfig {
  final Duration syncInterval;
  final bool syncTasks;
  final bool syncCalendar;
  final bool syncTopics;
  final int batchSize;
  final Duration retryDelay;

  const SyncConfig({
    this.syncInterval = const Duration(minutes: 15),
    this.syncTasks = true,
    this.syncCalendar = true,
    this.syncTopics = true,
    this.batchSize = 50,
    this.retryDelay = const Duration(seconds: 30),
  });
}

class SyncService {
  final LocalDatabase _localDb; 
  final ApiService _apiService;
  final SyncConfig _config;
  final List<Map<String, dynamic>> _syncQueue = [];
  final _logger = Logger('SyncService');
  Timer? _syncTimer;
  Timer? _retryTimer;
  bool _isSyncing = false;
  int _failedAttempts = 0;

  SyncService(this._localDb, this._apiService, [this._config = const SyncConfig()]) {
    _initializeSync();
  }

  // Expose the database getter from LocalDatabase
  Future<Database> get database => _localDb.database;

  void _initializeSync() {
    _startPeriodicSync();
    Logger.root.level = Level.INFO; // Adjust level as needed
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
       if (record.error != null) {
         debugPrint('Error: ${record.error}');
       }
       if (record.stackTrace != null) {
          debugPrint('StackTrace: ${record.stackTrace}');
       }
    });
    _logger.info("SyncService initialized.");
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_config.syncInterval, (_) => syncData());
     _logger.info("Periodic sync started with interval: ${_config.syncInterval}");
  }


  void queueChange(Map<String, dynamic> change) {
    _logger.fine("Queueing change: $change");
    _syncQueue.add(change);
    _scheduleBatchSync();  
  }

  void _scheduleBatchSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 10), () async { 
      if (_syncQueue.isEmpty) {
         _logger.fine("Sync queue is empty, skipping batch sync.");
         _startPeriodicSync(); 
         return;
      }
      if (_isSyncing) {
         _logger.info("Sync already in progress, rescheduling batch sync check.");
         _scheduleBatchSync(); 
         return;
      }

      final batch = List<Map<String, dynamic>>.unmodifiable(_syncQueue); // Take immutable copy
      _syncQueue.clear(); 
      _logger.info("Attempting to sync batch of ${batch.length} changes.");

      try {
        _isSyncing = true;
        await _apiService.syncBatch(batch); 
        _logger.info("Sync batch successful.");
        _failedAttempts = 0; 
        _startPeriodicSync();
      } catch (e, stackTrace) {
        _logger.warning('Sync batch failed: $e', e, stackTrace);
        _syncQueue.insertAll(0, batch); 
        _handleSyncFailure(); 
      } finally {
        _isSyncing = false;
      }
    });
  }

  void _handleSyncFailure() {
    _failedAttempts++;
    final delay = Duration(
      seconds: (_config.retryDelay.inSeconds * _failedAttempts).clamp(30, 300)
    );

    _logger.info('Sync failure count: $_failedAttempts. Scheduling retry in ${delay.inSeconds} seconds.');

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (_syncQueue.isNotEmpty && !_isSyncing) {
        _logger.info("Retrying sync...");
        _scheduleBatchSync(); // Retry the sync process
      } else {
         _logger.info("Retry timer fired, but queue is empty or sync in progress.");
         _startPeriodicSync(); // Ensure periodic sync restarts if retry isn't needed
      }
    });
     // Also ensure periodic sync doesn't run immediately after failure
     _syncTimer?.cancel();
  }


 
  Future<void> syncData() async {
    if (_isSyncing) {
      _logger.info('Full sync triggered, but already in progress, skipping.');
      return;
    }
     _logger.info("Starting full data sync...");

    // Cancel any pending retry timers since we're doing a full sync now
    _retryTimer?.cancel();

    try {
      _isSyncing = true;
      final db = await database;

      final queries = <Future>[];
      if (_config.syncTasks) queries.add(_syncType(db, 'tasks'));
      if (_config.syncCalendar) queries.add(_syncType(db, 'meetings'));
      if (_config.syncTopics) queries.add(_syncType(db, 'topics'));
     
      await Future.wait(queries);

      if (_syncQueue.isNotEmpty) {
         _logger.info("Processing queued changes after full sync attempt.");
         _scheduleBatchSync(); 
      } else {
         _logger.info('Full sync completed successfully.');
         _failedAttempts = 0;
         _startPeriodicSync();
      }

    } catch (e, stackTrace) {
      _logger.severe('Full sync failed: $e', e, stackTrace);
      _handleSyncFailure();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncType(Database db, String table) async {
     _logger.info("Checking sync status for table: $table");
    try {
      // Check if table exists and has 'sync_status' column before querying
      final unsynced = await db.query(
        table,
        where: 'sync_status = ?', // Assumes 'pending' status exists
        whereArgs: ['pending'],
        limit: _config.batchSize,
      );

      if (unsynced.isEmpty) {
         _logger.fine("No pending items found for table: $table");
         return;
      }
      _logger.info("Found ${unsynced.length} pending items for table: $table");

      // Assuming syncBatch sends these items and gets back changes
      final result = await _apiService.syncBatch(unsynced);

      // Process changes received from the server
      if (result['server_changes'] != null && result['server_changes'] is List) {
         _logger.info("Processing ${result['server_changes'].length} server changes.");
         await _processServerChanges(List<Map<String, dynamic>>.from(result['server_changes']));
      }

      // Update local status for successfully sent items
      final List<dynamic> sentIds = unsynced.map((d) => d['id']).toList();
      if (sentIds.isNotEmpty) {
         int updatedCount = await db.update(
           table,
           {'sync_status': 'synced'}, // Mark as synced
           where: 'id IN (${List.filled(sentIds.length, '?').join(', ')})',
           whereArgs: sentIds,
         );
         _logger.info('Marked $updatedCount items as synced in table: $table');
      }

    } catch (e, stackTrace) {
      _logger.warning('Error syncing type $table: $e', e, stackTrace);
      rethrow;
    }
  }

  // Process changes coming *from* the server (inserts/updates locally)
  Future<void> _processServerChanges(List<Map<String, dynamic>> changes) async {
    if (changes.isEmpty) return;

    final db = await database;
    int successCount = 0;
    await db.transaction((txn) async {
      for (final change in changes) {
        // Assuming change format: {'type': 'task', 'data': {task_map}}
        final type = change['type'] as String?;
        final data = change['data'] as Map<String, dynamic>?;

        if (type == null || data == null) {
           _logger.warning("Invalid server change format received: $change");
           continue;
        }

        final table = _getTableForType(type);
        if (table != null) {
          try {
            // Use insert with replace to handle both new and updated items
            await txn.insert(
              table,
              data, // Assuming 'data' is the map to insert
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            successCount++;
          } catch (e, stackTrace) {
            _logger.warning('Error processing server change for $table (ID: ${data['id']}): $e', e, stackTrace);
          }
        }
      }
    });
     _logger.info("Processed $successCount server changes successfully.");
  }

  // Map server type name to local table name
  String? _getTableForType(String type) {
    // Case-insensitive comparison might be safer
    switch (type.toLowerCase()) {
      case 'task':
        return 'tasks';
      case 'meeting':
        return 'meetings';
      case 'topic':
        return 'topics';
      case 'focus_session': // Add if focus sessions are synced from server
         return 'focus_sessions';
      default:
        _logger.warning('Unknown server change type received: $type');
        return null;
    }
  }

  // Dispose timers when service is no longer needed
  void dispose() {
    _logger.info("Disposing SyncService timers.");
    _syncTimer?.cancel();
    _retryTimer?.cancel();
  }
}