// lib/models/focus_session.dart
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
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'topic': topic,
      'distractions': distractions != null ? distractions!.join(',') : null,
      'focus_rating': focusRating,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      durationMinutes: map['duration_minutes'],
      topic: map['topic'],
      distractions: map['distractions'] != null 
          ? map['distractions'].split(',') 
          : null,
      focusRating: map['focus_rating'],
      isCompleted: map['is_completed'] == 1,
    );
  }
}