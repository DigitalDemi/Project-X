class Meeting {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;

  Meeting({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'description': description,
    };
  }

  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      description: map['description'] as String?,
    );
  }
}