// lib/models/habit.dart
class Habit {
  final String id;
  final String title;
  final String? description;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final List<DateTime> completionDates;
  final String frequency; // 'daily', 'weekly'
  final List<int>? weekdays; // For weekly habits (1-7, where 1 is Monday)
  final String? timeOfDay; // 'morning', 'afternoon', 'evening', 'anytime'

  Habit({
    required this.id,
    required this.title,
    this.description,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.createdAt,
    this.completionDates = const [],
    required this.frequency,
    this.weekdays,
    this.timeOfDay,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'created_at': createdAt.toIso8601String(),
      'completion_dates': completionDates.map((date) => date.toIso8601String()).join(','),
      'frequency': frequency,
      'weekdays': weekdays?.join(','),
      'time_of_day': timeOfDay,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      currentStreak: map['current_streak'],
      longestStreak: map['longest_streak'],
      createdAt: DateTime.parse(map['created_at']),
      completionDates: map['completion_dates'] != null && map['completion_dates'] != '' 
          ? map['completion_dates'].split(',').map<DateTime>((date) => DateTime.parse(date)).toList() 
          : [],
      frequency: map['frequency'],
      weekdays: map['weekdays'] != null && map['weekdays'] != '' 
          ? map['weekdays'].split(',').map<int>((day) => int.parse(day)).toList() 
          : null,
      timeOfDay: map['time_of_day'],
    );
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    int? currentStreak,
    int? longestStreak,
    DateTime? createdAt,
    List<DateTime>? completionDates,
    String? frequency,
    List<int>? weekdays,
    String? timeOfDay,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt ?? this.createdAt,
      completionDates: completionDates ?? this.completionDates,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      timeOfDay: timeOfDay ?? this.timeOfDay,
    );
  }

  bool isCompletedToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return completionDates.any((date) => 
      date.year == today.year && 
      date.month == today.month && 
      date.day == today.day
    );
  }

  bool isDueToday() {
    if (frequency == 'daily') return true;
    
    final now = DateTime.now();
    final weekday = now.weekday; // 1-7 (Monday-Sunday)
    
    return weekdays != null && weekdays!.contains(weekday);
  }
}