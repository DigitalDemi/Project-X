// lib/ui/calendar/calendar_view.dart
import 'package:flutter/material.dart';
import 'package:frontend/services/calender_service.dart';
import 'package:provider/provider.dart';
import '../../models/calendar_event.dart';
import 'event_tile.dart';
import 'add_event_dialog.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime selectedDate = DateTime.now();

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(selectedDate: selectedDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500, // Fixed height for the entire calendar view
      child: Column(
        children: [
          // Date selector - fixed height
          Container(
            height: 80,
            color: Colors.grey[900],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index - 3));
                final isSelected = date.year == selectedDate.year &&
                                 date.month == selectedDate.month &&
                                 date.day == selectedDate.day;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _DateChip(
                    date: date,
                    isSelected: isSelected,
                    onTap: () => _onDateSelected(date),
                  ),
                );
              },
            ),
          ),

          // Events list - takes remaining height
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  Consumer<CalendarService>(
                    builder: (context, service, child) {
                      final events = service.getEventsForDate(selectedDate);

                      if (events.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No events scheduled',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return EventTile(
                            event: event,
                            onDelete: event.source == EventSource.userCreated
                                ? () => service.deleteEvent(event.id)
                                : null,
                          );
                        },
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: _showAddEventDialog,
                      backgroundColor: Colors.deepPurpleAccent,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurpleAccent : Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getDayName(date),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1: return 'MON';
      case 2: return 'TUE';
      case 3: return 'WED';
      case 4: return 'THU';
      case 5: return 'FRI';
      case 6: return 'SAT';
      case 7: return 'SUN';
      default: return '';
    }
  }
}