import 'package:flutter/material.dart';

class StatefulTaskNumber extends StatefulWidget {
  const StatefulTaskNumber({super.key});

  @override
  State<StatefulTaskNumber> createState() => _StatefulTaskNumberState();
}

class _StatefulTaskNumberState extends State<StatefulTaskNumber> {
  int completedTasks = 1;
  int totalTasks = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, color: Colors.white, size: 16),
        ...List.generate(
          totalTasks - completedTasks,
          (index) => const Icon(Icons.remove, color: Colors.white, size: 16),
        ),
      ],
    );
  }
}