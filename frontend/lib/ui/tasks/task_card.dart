import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String duration;
  final String energyLevel;
  final bool showTimer;

  const TaskCard({
    super.key,
    this.title = 'CREATING CV', // Default value
    this.duration = '1HR 30MIN',
    this.energyLevel = 'HIGH ENERGY',
    this.showTimer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTimer) ...[
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            duration,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            energyLevel,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Example usage with custom data:
class TaskCardList extends StatelessWidget {
  final List<Map<String, String>> tasks;

  const TaskCardList({
    super.key,
    this.tasks = const [
      {
        'title': 'CREATING CV',
        'duration': '1HR 30MIN',
        'energyLevel': 'HIGH ENERGY'
      },
      {
        'title': 'WORKOUT',
        'duration': '45MIN',
        'energyLevel': 'HIGH ENERGY'
      },
      {
        'title': 'READING',
        'duration': '1HR',
        'energyLevel': 'LOW ENERGY'
      },
    ],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            title: task['title'] ?? '',
            duration: task['duration'] ?? '',
            energyLevel: task['energyLevel'] ?? '',
          );
        },
      ),
    );
  }
}