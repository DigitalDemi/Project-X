import 'dart:convert';

import 'package:uuid/uuid.dart'; // For JSON encoding/decoding

class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String? topic;
  final List<String>? distractions;
  final int focusRating; // 1-5 rating of focus quality
  final bool isCompleted;

  FocusSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.topic,
    this.distractions,
    required this.focusRating,
    required this.isCompleted, // Ensure this is required
  });

  // Convert FocusSession to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'topic': topic,
      // Encode list to JSON string for storage in TEXT column
      'distractions': distractions == null ? null : jsonEncode(distractions),
      'focus_rating': focusRating,
      'is_completed': isCompleted ? 1 : 0, // Store boolean as integer (0 or 1)
    };
  }

  // Create FocusSession from Map retrieved from database
  factory FocusSession.fromMap(Map<String, dynamic> map) {
    List<String>? decodedDistractions;
    final rawDistractions = map['distractions'];

    // Decode JSON string if it's a non-empty string
    if (rawDistractions != null && rawDistractions is String && rawDistractions.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(rawDistractions);
        // Convert to List<String>, filtering out nulls/empties robustly
        decodedDistractions = decodedList
            .map((e) => e?.toString()) // Convert item to string safely
            .where((s) => s != null && s.isNotEmpty).cast<String>() // Filter out null or empty strings
            .toList();
        // Optional: Handle case where filtering results in an empty list
        // if (decodedDistractions.isEmpty) decodedDistractions = null;
      } catch (e) {
        print('!!!!!! Error decoding distractions JSON: "$rawDistractions" - $e');
        decodedDistractions = null; // Handle decoding error
      }
    } else {
      // Handle cases where it's null, already a list (unlikely), or other types
      decodedDistractions = null;
    }

    // Safely parse other fields, providing defaults for null safety
    return FocusSession(
      id: map['id'] as String? ?? const Uuid().v4(), // Provide default ID if null
      startTime: map['start_time'] != null ? DateTime.parse(map['start_time'] as String) : DateTime.now(), // Provide default time
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : DateTime.now(), // Provide default time
      durationMinutes: map['duration_minutes'] as int? ?? 0, // Default if null
      topic: map['topic'] as String?,
      distractions: decodedDistractions, // Use the safely decoded list
      focusRating: map['focus_rating'] as int? ?? 0, // Default if null
      isCompleted: (map['is_completed'] as int? ?? 0) == 1, // Safely convert from int
    );
  }

  // Optional: copyWith for easier updates if needed elsewhere
   FocusSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? topic,
    List<String>? distractions,
    int? focusRating,
    bool? isCompleted,
  }) {
    return FocusSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      topic: topic ?? this.topic,
      distractions: distractions ?? this.distractions,
      focusRating: focusRating ?? this.focusRating,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}