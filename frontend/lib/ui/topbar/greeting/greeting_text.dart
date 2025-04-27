import 'package:flutter/material.dart';
import 'package:frontend/services/profile_service.dart'; // Adjust path
import 'package:provider/provider.dart';

class GreetingText extends StatelessWidget {
  const GreetingText({super.key});

  @override
  Widget build(BuildContext context) {
    // Use context.watch to listen for changes in the ProfileService
    final profileService = context.watch<ProfileService>();
    final displayName = profileService.name; // Get name from service

    return Text(
      // Display the dynamic name from the service
      'Hi $displayName',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white, // Ensure text color contrasts with background
      ),
    );
  }
}