import 'package:flutter/material.dart';
import 'package:frontend/ui/topbar/greeting/greeting_text.dart';
import 'profile_circle.dart';

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ProfileCircle(),
        SizedBox(width: 12),
        GreetingText(),
      ],
    );
  }
}