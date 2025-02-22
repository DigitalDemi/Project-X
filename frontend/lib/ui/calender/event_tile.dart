import 'package:flutter/material.dart';
import '../../models/calendar_event.dart';

class EventTile extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const EventTile({
    super.key,
    required this.event,
    this.onDelete,
    this.onEdit,
  });

  String _getCategoryName(EventCategory category) {
    return category.toString().split('.').last
        .split(RegExp(r'(?=[A-Z])'))
        .join(' ')
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: event.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (event.source == EventSource.userCreated) ...[
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.white70,
                              onPressed: onEdit,
                            ),
                          if (onDelete != null)
                          // lib/ui/calendar/event_tile.dart (continued)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: Colors.white70,
                              onPressed: onDelete,
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: event.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(event.category),
                                size: 14,
                                color: event.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getCategoryName(event.category),
                                style: TextStyle(
                                  color: event.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (event.source != EventSource.userCreated) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSourceIcon(event.source),
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getSourceName(event.source),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return Icons.work;
      case EventCategory.personal:
        return Icons.person;
      case EventCategory.meeting:
        return Icons.groups;
      case EventCategory.study:
        return Icons.school;
      case EventCategory.health:
        return Icons.favorite;
      case EventCategory.social:
        return Icons.people;
      case EventCategory.other:
        return Icons.category;
      case EventCategory.general:
      default:
        return Icons.event;
    }
  }

  IconData _getSourceIcon(EventSource source) {
    switch (source) {
      case EventSource.icsFile:
        return Icons.calendar_today;
      case EventSource.googleCalendar:
        return Icons.calendar_month;
      case EventSource.userCreated:
      default:
        return Icons.edit_calendar;
    }
  }

  String _getSourceName(EventSource source) {
    switch (source) {
      case EventSource.icsFile:
        return 'ICS';
      case EventSource.googleCalendar:
        return 'GOOGLE';
      case EventSource.userCreated:
      default:
        return 'USER';
    }
  }
}