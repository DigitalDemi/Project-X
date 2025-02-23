import 'package:flutter/material.dart';
import '../../models/calendar_event.dart';
import '../../services/calender_service.dart';
import 'package:provider/provider.dart';

class EventTile extends StatelessWidget {
  final CalendarEvent event;

  const EventTile({
    super.key,
    required this.event,
  });

  void _showEventActions(BuildContext context) {
    final calendarService = Provider.of<CalendarService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Event title header
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Only show edit/delete for user-created events
            if (event.source == EventSource.userCreated) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white70),
                title: const Text('Edit Event', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // Show edit dialog
                  // TODO: Implement edit dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Event', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  // Show confirmation dialog
                  final delete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Delete Event?', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'This will remove the event from your calendar. This action cannot be undone.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (delete == true) {
                    await calendarService.deleteEvent(event.id);
                  }
                },
              ),
            ],
            
            // Show source information for all events
            const SizedBox(height: 8),
            Text(
              'Source: ${_getSourceName(event.source)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _getSourceName(EventSource source) {
    switch (source) {
      case EventSource.icsFile:
        return 'ICS Calendar';
      case EventSource.googleCalendar:
        return 'Google Calendar';
      case EventSource.userCreated:
        return 'User Created';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () => _showEventActions(context),
      child: Container(
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
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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
                            child: Text(
                              _getCategoryName(event.category),
                              style: TextStyle(
                                color: event.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getCategoryName(EventCategory category) {
    return category.toString().split('.').last
        .split(RegExp(r'(?=[A-Z])'))
        .join(' ')
        .toUpperCase();
  }
}