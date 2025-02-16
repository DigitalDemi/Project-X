import 'package:flutter/material.dart';

class StatefulTaskNumber extends StatefulWidget {
  const StatefulTaskNumber({super.key});

  @override
  State<StatefulTaskNumber> createState() => _StatefulTaskNumberState();
}

class _StatefulTaskNumberState extends State<StatefulTaskNumber> {
  int completedTasks = 0;
  int totalTasks = 3;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$completedTasks',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            totalTasks,
            (index) => Icon(
              index < completedTasks ? Icons.check : Icons.remove,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}