import 'package:flutter/material.dart';
import 'package:frontend/ui/topbar/greeting/greeting_text.dart'; // Adjust path
import 'profile_circle.dart'; // Adjust path

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ProfileCircle(), // Your profile picture widget
        SizedBox(width: 12), // Space between picture and text
        GreetingText(), // Your greeting text widget
      ],
    );
  }
}