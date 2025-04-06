// lib/models/reflection.dart
class Reflection {
  final String id;
  final DateTime date;
  final String content;
  final List<String> tags;
  final int? moodRating; // 1-5 scale
  final int? productivityRating; // 1-5 scale
  final String? focusArea;

  Reflection({
    required this.id,
    required this.date,
    required this.content,
    this.tags = const [],
    this.moodRating,
    this.productivityRating,
    this.focusArea,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'tags': tags.join(','),
      'mood_rating': moodRating,
      'productivity_rating': productivityRating,
      'focus_area': focusArea,
    };
  }

  factory Reflection.fromMap(Map<String, dynamic> map) {
    return Reflection(
      id: map['id'],
      date: DateTime.parse(map['date']),
      content: map['content'],
      tags: map['tags'] != null && map['tags'] != '' 
          ? map['tags'].split(',') 
          : [],
      moodRating: map['mood_rating'],
      productivityRating: map['productivity_rating'],
      focusArea: map['focus_area'],
    );
  }
}