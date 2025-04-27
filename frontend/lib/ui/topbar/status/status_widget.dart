// lib/ui/topbar/status/status_widget.dart

import 'package:flutter/material.dart';
import 'fire_icon.dart';
import 'streak_display.dart'; // NEW: Import the streak display widget

class StatusWidget extends StatelessWidget {
  const StatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
      children: [
        FireIcon(), // Keep the fire icon
        SizedBox(width: 4), // Spacing between icon and number
        StreakDisplay(), // NEW: Use the StreakDisplay widget
      ],
    );
  }
}