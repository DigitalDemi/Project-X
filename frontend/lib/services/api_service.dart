// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';

class ApiService {
  final String baseUrl = 'http://localhost:8000';
  final _logger = Logger('ApiService');
  
  Future<Map<String, dynamic>> syncBatch(List<Map<String, dynamic>> changes) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'changes': changes,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        _logger.warning('Sync failed with status: ${response.statusCode}');
        throw Exception('Failed to sync data');
      }
    } catch (e) {
      _logger.severe('Error during sync: $e');
      throw Exception('Network error during sync');
    }
  }

  Future<Map<String, dynamic>> createTopic(Map<String, dynamic> topicData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/topics/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(topicData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        _logger.warning('Failed to create topic: ${response.statusCode}');
        throw Exception('Failed to create topic');
      }
    } catch (e) {
      _logger.severe('Error creating topic: $e');
      throw Exception('Network error while creating topic');
    }
  }

  Future<Map<String, dynamic>> getChanges(int lastSyncVersion) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/changes').replace(
          queryParameters: {'since': lastSyncVersion.toString()}
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        _logger.warning('Failed to get changes: ${response.statusCode}');
        throw Exception('Failed to get changes');
      }
    } catch (e) {
      _logger.severe('Error getting changes: $e');
      throw Exception('Network error while getting changes');
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedChanges(int limit) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/unsynced').replace(
          queryParameters: {'limit': limit.toString()}
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        _logger.warning('Failed to get unsynced changes: ${response.statusCode}');
        throw Exception('Failed to get unsynced changes');
      }
    } catch (e) {
      _logger.severe('Error getting unsynced changes: $e');
      throw Exception('Network error while getting unsynced changes');
    }
  }

  Future<void> confirmSync(List<String> changeIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'change_ids': changeIds}),
      );

      if (response.statusCode != 200) {
        _logger.warning('Failed to confirm sync: ${response.statusCode}');
        throw Exception('Failed to confirm sync');
      }
    } catch (e) {
      _logger.severe('Error confirming sync: $e');
      throw Exception('Network error while confirming sync');
    }
  }
}