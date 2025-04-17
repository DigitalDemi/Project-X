// lib/services/content_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/content.dart';

class ContentService extends ChangeNotifier {
  final String baseUrl = 'http://100.84.155.122:8000';
  List<Content> _content = [];
  bool _isLoading = false;
  String? _error;

  // Add this to cache content by topic
  final Map<String, List<Content>> _contentByTopic = {};

  ContentService() {
    fetchAllContent();
  }

  bool get isLoading => _isLoading;
  List<Content> get content => _content;
  String? get error => _error;

  Future<void> fetchAllContent() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl/content/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _content = (data as List).map((item) => Content.fromMap(item)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Failed to load content: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // lib/services/content_service.dart
  Future<List<Content>> getContentByTopic(String topicId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/content/by-topic/$topicId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final contentList =
            (data as List).map((item) => Content.fromMap(item)).toList();

        // Cache the content
        _contentByTopic[topicId] = contentList;

        return contentList;
      } else {
        throw Exception(
          'Failed to load content for topic: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting content: $e');
      }
      throw Exception('Error getting content: $e');
    }
  }

  // Add these new methods

  List<Content> getContentByType(String type) {
    return _content.where((item) => item.type == type).toList();
  }

  List<Content> searchContent(String query) {
    return _content
        .where(
          (item) =>
              item.title.toLowerCase().contains(query.toLowerCase()) ||
              item.content.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  List<String> getAvailableSubjects() {
    // Extract subjects from related topic IDs
    final Set<String> subjects = {};

    for (final content in _content) {
      for (final topicId in content.relatedTopicIds) {
        final parts = topicId.split(':');
        if (parts.isNotEmpty) {
          subjects.add(parts[0]);
        }
      }
    }

    return subjects.toList()..sort();
  }
}
