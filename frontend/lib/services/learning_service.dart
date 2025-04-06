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

  // Enhanced methods for progress visualization

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

  List<MapEntry<DateTime, int>> getReviewTimeline() {
    // Group reviews by date
    final Map<DateTime, int> reviewsByDate = {};
    
    for (var topic in _topics) {
      for (var review in topic.reviewHistory) {
        final date = DateTime(
          review['date'].year,
          review['date'].month,
          review['date'].day,
        );
        
        reviewsByDate[date] = (reviewsByDate[date] ?? 0) + 1;
      }
    }
    
    // Convert to list of entries
    final entries = reviewsByDate.entries.toList();
    
    // Sort by date
    entries.sort((a, b) => a.key.compareTo(b.key));
    
    return entries;
  }
  
  List<MapEntry<String, int>> getDifficultyDistribution() {
    int easy = 0;
    int normal = 0;
    int hard = 0;
    
    for (var topic in _topics) {
      for (var review in topic.reviewHistory) {
        final difficulty = review['difficulty'] as String;
        
        if (difficulty == 'easy') {
          easy++;
        } else if (difficulty == 'normal') {
          normal++;
        } else if (difficulty == 'hard') {
          hard++;
        }
      }
    }
    
    return [
      MapEntry('easy', easy),
      MapEntry('normal', normal),
      MapEntry('hard', hard),
    ];
  }
  
  Map<String, List<Topic>> getTopicsBySubject() {
    final result = <String, List<Topic>>{};
    
    for (var topic in _topics) {
      if (topic.status == 'active') {
        if (!result.containsKey(topic.subject)) {
          result[topic.subject] = [];
        }
        
        result[topic.subject]!.add(topic);
      }
    }
    
    return result;
  }
  
  List<Topic> getRecommendedTopics({
    int count = 5,
    String? energyLevel,
    DateTime? forDate,
  }) {
    final now = DateTime.now();
    final dueTopics = getDueTopics();
    
    // Sort due topics by how overdue they are
    dueTopics.sort((a, b) => a.nextReview.compareTo(b.nextReview));
    
    if (dueTopics.isEmpty) {
      // If no due topics, recommend topics that will be due soon
      final upcomingTopics = _topics.where((t) => 
        t.status == 'active' && 
        t.nextReview.isAfter(now) &&
        t.nextReview.difference(now).inDays < 3
      ).toList();
      
      upcomingTopics.sort((a, b) => a.nextReview.compareTo(b.nextReview));
      
      if (energyLevel == 'high') {
        // For high energy, prioritize more difficult topics
        return upcomingTopics
          .where((t) => ['mid_stage', 'early_stage', 'first_time'].contains(t.stage))
          .take(count)
          .toList();
      } else if (energyLevel == 'low') {
        // For low energy, prioritize easier, more familiar topics
        return upcomingTopics
          .where((t) => ['mastered', 'late_stage'].contains(t.stage))
          .take(count)
          .toList();
      }
      
      return upcomingTopics.take(count).toList();
    }
    
    if (energyLevel == 'high') {
      // For high energy, prioritize more difficult topics
      return dueTopics
        .where((t) => ['first_time', 'early_stage', 'mid_stage'].contains(t.stage))
        .take(count)
        .toList();
    } else if (energyLevel == 'low') {
      // For low energy, prioritize easier, more familiar topics
      return dueTopics
        .where((t) => ['mastered', 'late_stage'].contains(t.stage))
        .take(count)
        .toList();
    }
    
    return dueTopics.take(count).toList();
  }
  
  // Calculate average interval for each difficulty rating
  Map<String, double> getAverageIntervals() {
    final Map<String, List<int>> intervalsByDifficulty = {
      'easy': [],
      'normal': [],
      'hard': [],
    };
    
    for (var topic in _topics) {
      for (var review in topic.reviewHistory) {
        final difficulty = review['difficulty'] as String;
        final interval = review['interval'] as int;
        
        intervalsByDifficulty[difficulty]?.add(interval);
      }
    }
    
    final Map<String, double> averages = {};
    
    intervalsByDifficulty.forEach((difficulty, intervals) {
      if (intervals.isEmpty) {
        averages[difficulty] = 0.0;
      } else {
        final sum = intervals.reduce((a, b) => a + b);
        averages[difficulty] = sum / intervals.length;
      }
    });
    
    return averages;
  }
}