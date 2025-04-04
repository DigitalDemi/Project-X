import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/content.dart';

class ContentService extends ChangeNotifier {
  final String baseUrl = 'http://localhost:8000';
  List<Content> _content = [];
  bool _isLoading = false;
  String? _error;

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
      final response = await http.get(
        Uri.parse('$baseUrl/content/'),
      );

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

  Future<List<Content>> getContentByTopic(String topicId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/content/by-topic/$topicId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).map((item) => Content.fromMap(item)).toList();
      } else {
        throw Exception('Failed to load content for topic');
      }
    } catch (e) {
      throw Exception('Error getting content: $e');
    }
  }
}