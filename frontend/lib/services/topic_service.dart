// lib/services/topic_service.dart
import 'package:flutter/foundation.dart';
import '../models/topic.dart';
import 'sync_service.dart';
import 'package:sqflite/sqflite.dart';

class TopicService extends ChangeNotifier {
  final SyncService _syncService;
  List<Topic> _topics = [];

  TopicService(this._syncService) {
    _loadLocalTopics();
  }

  List<Topic> get topics => _topics;

  Future<void> _loadLocalTopics() async {
    try {
      final db = await _syncService.database;
      final localTopics = await db.query('topics');
      _topics = localTopics.map((t) => Topic.fromMap(t)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading topics: $e');
    }
  }

  Future<void> createTopic(Map<String, dynamic> topicData) async {
    try {
      // Create locally
      final db = await _syncService.database;
      final topic = Topic.fromMap({
        ...topicData,
        'created_at': DateTime.now().toIso8601String(),
        'next_review': DateTime.now().toIso8601String(),
        'stage': 'first_time',
        'review_history': [],
      });

      await db.insert(
        'topics',
        topic.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update local state
      _topics.add(topic);
      notifyListeners();

      // Queue for sync
      _syncService.queueChange({
        'type': 'topic',
        'action': 'create',
        'data': topic.toMap(),
      });
    } catch (e) {
      print('Error creating topic: $e');
      rethrow;
    }
  }

  Future<void> updateTopic(String? id, Map<String, dynamic> updates) async {
    if (id == null) return;

    try {
      final db = await _syncService.database;
      final topic = Topic.fromMap({
        ...updates,
        'id': id,
        'last_modified': DateTime.now().toIso8601String(),
      });

      await db.update(
        'topics',
        topic.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      // Update local state
      final index = _topics.indexWhere((t) => t.id == id);
      if (index != -1) {
        _topics[index] = topic;
        notifyListeners();
      }

      // Queue for sync
      _syncService.queueChange({
        'type': 'topic',
        'action': 'update',
        'data': topic.toMap(),
      });
    } catch (e) {
      print('Error updating topic: $e');
      rethrow;
    }
  }

  Future<void> deleteTopic(String? id) async {
    if (id == null) return;

    try {
      final db = await _syncService.database;
      await db.delete(
        'topics',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Update local state
      _topics.removeWhere((t) => t.id == id);
      notifyListeners();

      // Queue for sync
      _syncService.queueChange({
        'type': 'topic',
        'action': 'delete',
        'data': {'id': id},
      });
    } catch (e) {
      print('Error deleting topic: $e');
      rethrow;
    }
  }
}