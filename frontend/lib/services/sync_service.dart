// lib/services/sync_service.dart
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

  Future<Database> get database => _localDb.database;

  void _initializeSync() {
    _startPeriodicSync();
    // Initialize logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // In production, you might want to use a proper logging service
      // For now, we'll just print to console in debug mode
      if (record.level >= Level.WARNING) {
        print('${record.level.name}: ${record.time}: ${record.message}');
      }
    });
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_config.syncInterval, (_) => syncData());
  }

  void queueChange(Map<String, dynamic> change) {
    _syncQueue.add(change);
    _scheduleBatchSync();
  }

  void _scheduleBatchSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 5), () async {
      if (_syncQueue.isEmpty || _isSyncing) return;
      
      final batch = List<Map<String, dynamic>>.from(_syncQueue);
      _syncQueue.clear();
      
      try {
        _isSyncing = true;
        await _apiService.syncBatch(batch);
        _failedAttempts = 0; // Reset counter on success
      } catch (e) {
        _logger.warning('Sync failed: $e');
        _syncQueue.addAll(batch);
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
    
    _logger.info('Scheduling retry in ${delay.inSeconds} seconds');
    
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (_syncQueue.isNotEmpty) {
        _scheduleBatchSync();
      }
    });
  }

  Future<void> syncData() async {
    if (_isSyncing) {
      _logger.info('Sync already in progress, skipping');
      return;
    }

    try {
      _isSyncing = true;
      final db = await database;
      
      final queries = <Future>[];
      
      if (_config.syncTasks) {
        queries.add(_syncType(db, 'tasks'));
      }
      if (_config.syncCalendar) {
        queries.add(_syncType(db, 'meetings'));
      }
      if (_config.syncTopics) {
        queries.add(_syncType(db, 'topics'));
      }

      await Future.wait(queries);
      _logger.info('Sync completed successfully');
    } catch (e) {
      _logger.severe('Sync failed: $e');
      _handleSyncFailure();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncType(Database db, String table) async {
    try {
      final unsynced = await db.query(
        table,
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        limit: _config.batchSize,
      );

      if (unsynced.isEmpty) return;

      final result = await _apiService.syncBatch(unsynced);
      await _processServerChanges(result['server_changes']);
      
      await db.update(
        table,
        {'sync_status': 'synced'},
        where: 'id IN (${unsynced.map((_) => '?').join(', ')})',
        whereArgs: unsynced.map((d) => d['id']).toList(),
      );

      _logger.info('Successfully synced $table: ${unsynced.length} items');
    } catch (e) {
      _logger.warning('Error syncing $table: $e');
      rethrow;
    }
  }

  Future<void> _processServerChanges(List<Map<String, dynamic>> changes) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final change in changes) {
        final table = _getTableForType(change['type']);
        if (table != null) {
          try {
            await txn.insert(
              table,
              change['data'],
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            _logger.warning('Error processing change for $table: $e');
          }
        }
      }
    });
  }

  String? _getTableForType(String type) {
    switch (type) {
      case 'task':
        return 'tasks';
      case 'meeting':
        return 'meetings';
      case 'topic':
        return 'topics';
      default:
        _logger.warning('Unknown type: $type');
        return null;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _retryTimer?.cancel();
  }
}