// NOTE: THIS WILL BE BROKEN DOWN MORE LATER
import 'package:flutter/material.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime selectedDate = DateTime.now();
  
  // This will be changed later to pull information from data or ICS service
  final Map<String, List<Meeting>> eventsByDate = {
    '2025-02-16': [
      Meeting(
        startTime: '8:00',
        endTime: '9:00',
        title: 'Team Meeting',
      ),
    ],
    '2025-02-17': [
      Meeting(
        startTime: '10:00',
        endTime: '11:00',
        title: 'Client Call',
      ),
    ],
  };

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  List<DateTime> _generateDateList() {
    final List<DateTime> dates = [];
    final DateTime now = DateTime.now();
    
    // Generate dates for a week before and after
    for (int i = -3; i <= 3; i++) {
      dates.add(now.add(Duration(days: i)));
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final dates = _generateDateList();
    final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final events = eventsByDate[dateKey] ?? [];

    return Column(
      children: [
        // Date Scroller
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = date.day == selectedDate.day &&
                               date.month == selectedDate.month &&
                               date.year == selectedDate.year;
              
              return DateChip(
                date: date,
                isSelected: isSelected,
                onTap: () => _onDateSelected(date),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        
        // Events List
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: events.isEmpty
              ? const Center(
                  child: Text(
                    'No meetings scheduled',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Column(
                  children: events
                      .map((event) => MeetingTile(meeting: event))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const DateChip({
    super.key,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurpleAccent : Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getDayName(date),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              date.day.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}

// Meeting tile widget
class MeetingTile extends StatelessWidget {
  final Meeting meeting;

  const MeetingTile({
    super.key,
    required this.meeting,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '${meeting.startTime} - ${meeting.endTime}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Text(
            meeting.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Meeting model
class Meeting {
  final String startTime;
  final String endTime;
  final String title;

  Meeting({
    required this.startTime,
    required this.endTime,
    required this.title,
  });
}