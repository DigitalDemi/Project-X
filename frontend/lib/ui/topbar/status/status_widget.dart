import 'package:flutter/material.dart';
import 'fire_icon.dart';
import 'stateful_task_number.dart';

class StatusWidget extends StatelessWidget {
  const StatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FireIcon(),
        SizedBox(width: 4),
        StatefulTaskNumber(),
      ],
    );
  }
}