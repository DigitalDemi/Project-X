import 'package:flutter/material.dart';

enum EventSource {
  userCreated,
  icsFile,
  googleCalendar
}

enum EventCategory {
  general,
  work,
  personal,
  meeting,
  study,
  health,
  social,
  other
}

class CalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final EventSource source;
  final EventCategory category;
  final String? externalId;
  final Color color;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    required this.source,
    this.category = EventCategory.general,
    this.externalId,
    Color? color,
  }) : color = color ?? _getCategoryColor(category);

  static Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return Colors.blue;
      case EventCategory.personal:
        return Colors.purple;
      case EventCategory.meeting:
        return Colors.orange;
      case EventCategory.study:
        return Colors.green;
      case EventCategory.health:
        return Colors.red;
      case EventCategory.social:
        return Colors.pink;
      case EventCategory.other:
        return Colors.grey;
      case EventCategory.general:
      default:
        return Colors.blueGrey;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'description': description,
      'source': source.toString(),
      'category': category.toString(),
      'external_id': externalId,
      'color': color.value,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      description: map['description'] as String?,
      source: EventSource.values.firstWhere(
        (e) => e.toString() == map['source'],
        orElse: () => EventSource.userCreated,
      ),
      category: EventCategory.values.firstWhere(
        (c) => c.toString() == map['category'],
        orElse: () => EventCategory.general,
      ),
      externalId: map['external_id'] as String?,
      color: Color(map['color'] as int? ?? _getCategoryColor(EventCategory.general).value),
    );
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    EventSource? source,
    EventCategory? category,
    String? externalId,
    Color? color,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      source: source ?? this.source,
      category: category ?? this.category,
      externalId: externalId ?? this.externalId,
      color: color ?? this.color,
    );
  }
}