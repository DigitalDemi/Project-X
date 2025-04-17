class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final String? energyLevel;
  final String? duration;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.energyLevel,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'energy_level': energyLevel,
      'duration': duration,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      energyLevel: map['energy_level'] as String?,
      duration: map['duration'] as String?,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    String? energyLevel,
    String? duration,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      energyLevel: energyLevel ?? this.energyLevel,
      duration: duration ?? this.duration,
    );
  }
}