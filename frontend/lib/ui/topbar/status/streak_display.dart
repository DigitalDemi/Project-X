// lib/ui/topbar/status/streak_display.dart
import 'package:flutter/material.dart';
import 'package:frontend/services/profile_service.dart'; // Import ProfileService
import 'package:provider/provider.dart';          // Import Provider

// NEW: Widget to display the streak count
class StreakDisplay extends StatelessWidget {
  const StreakDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for changes in ProfileService using context.watch<T>()
    // This ensures the widget rebuilds when streakCount changes in ProfileService
    final profileService = context.watch<ProfileService>();

    // Use a Visibility widget to only show the text if the streak is > 0
    // Or adjust as needed (e.g., always show 0 if streak is 0)
    return Visibility(
       visible: profileService.streakCount > 0 || !profileService.isLoading, // Show if streak > 0 or loading is done
       replacement: const SizedBox(width: 8), // Or a placeholder if needed when hidden
       child: Text(
        '${profileService.streakCount}', // Display the streak count
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold, // Make it bold to stand out
        ),
      ),
    );
  }
}