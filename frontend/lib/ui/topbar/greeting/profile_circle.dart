import 'package:flutter/material.dart';
import 'package:frontend/ui/pages/settings_page.dart'; // Ensure this import path is correct
import 'package:provider/provider.dart';
import 'package:frontend/services/profile_service.dart'; // Ensure this import path is correct
import 'dart:io'; // Required for File and FileImage

class ProfileCircle extends StatelessWidget {
  const ProfileCircle({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in ProfileService
    return Consumer<ProfileService>(
      builder: (context, profileService, child) {

        // --- 1. Handle Loading State ---
        // Show a placeholder with a centered loading indicator while initial data is fetched.
        if (profileService.isLoading) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[600], // Placeholder background during load
            ),
            // Center the progress indicator within the container
            child: const Center(
              child: SizedBox(
                width: 24, // Constrain indicator size
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          );
        }

        // --- 2. Determine the Image Provider ---
        ImageProvider imageProvider;
        final String? currentImagePath = profileService.imagePath;

        // Check if a path is saved AND if the file actually exists at that path
        if (currentImagePath != null && File(currentImagePath).existsSync()) {
          // Use FileImage if the path is valid and file exists.
          // FIX: Removed the 'key' parameter from FileImage
          imageProvider = FileImage(File(currentImagePath));
        } else {
          // Fallback to the default asset image if no path is set or the file is missing.
          imageProvider = const AssetImage('lib/ui/assets/default_image.png'); // Verify this path in pubspec.yaml
        }

        // --- 3. Build the Clickable Circle ---
        return GestureDetector(
          onTap: () {
            // Navigate to SettingsPage when tapped
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          child: Container(
            // Optionally add a key HERE if needed, e.g., if the Container itself needs identification
            // key: ValueKey(currentImagePath ?? 'default'),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[400], // Background color shown if image fails to load
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover, // Cover the circle area
                // onError callback handles errors during the image decoding/loading process
                onError: (exception, stackTrace) {
                  debugPrint("Error loading profile image data: $exception");
                },
              ),
            ),
          ),
        );
      },
    );
  }
}