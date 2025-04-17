class MoodEntry {
  final String id;
  final DateTime timestamp;
  final int rating; // 1-5
  final String? note;
  final List<String> factors; // What influenced the mood

  MoodEntry({
    required this.id,
    required this.timestamp,
    required this.rating,
    this.note,
    this.factors = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'rating': rating,
      'note': note,
      'factors': factors.join(','),
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      rating: map['rating'],
      note: map['note'],
      factors: map['factors'] != null && map['factors'] != '' 
          ? map['factors'].split(',') 
          : [],
    );
  }
}