// lib/services/learning_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/topic.dart';

class LearningService extends ChangeNotifier {
  final String baseUrl = 'http://localhost:8000';
  List<Topic> _topics = [];
  bool _isLoading = false;
  String? _error;

  LearningService() {
    fetchTopics();
  }

  bool get isLoading => _isLoading;
  List<Topic> get topics => _topics;
  String? get error => _error;

  Future<void> fetchTopics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/topics/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Process graph data from backend
        _processGraphData(data);
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Failed to load topics: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processGraphData(Map<String, dynamic> graphData) {
    final List<Topic> topics = [];
    
    // Convert topics from the graph format to Topic objects
    for (var topicId in graphData['topics'].keys) {
      final topicData = graphData['topics'][topicId];
      
      final topic = Topic(
        id: topicId,
        subject: topicData['subject'],
        name: topicData['name'],
        status: topicData['status'],
        stage: topicData['stage'],
        createdAt: DateTime.parse(topicData['created_at']),
        nextReview: DateTime.parse(topicData['next_review']),
        reviewHistory: List<Map<String, dynamic>>.from(topicData['review_history'] ?? []),
      );
      
      topics.add(topic);
    }
    
    _topics = topics;
  }

  Future<void> createTopic(Map<String, dynamic> topicData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/topics/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(topicData),
      );

      if (response.statusCode == 200) {
        await fetchTopics(); // Refresh the list
      } else {
        _error = 'Failed to create topic: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error creating topic: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reviewTopic(String topicId, String difficulty) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/topics/$topicId/review'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'difficulty': difficulty}),
      );

      if (response.statusCode == 200) {
        await fetchTopics(); // Refresh with updated data
      } else {
        _error = 'Failed to review topic: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error reviewing topic: $e';
      notifyListeners();
    }
  }

  Map<String, int> getStagesDistribution() {
    final distribution = <String, int>{
      'first_time': 0,
      'early_stage': 0,
      'mid_stage': 0,
      'late_stage': 0,
      'mastered': 0,
    };
    
    for (var topic in _topics) {
      if (topic.status == 'active' && distribution.containsKey(topic.stage)) {
        distribution[topic.stage] = distribution[topic.stage]! + 1;
      }
    }
    
    return distribution;
  }

  List<Topic> getDueTopics() {
    final now = DateTime.now();
    return _topics.where((topic) => 
      topic.status == 'active' && 
      topic.nextReview.isBefore(now)
    ).toList();
  }
}