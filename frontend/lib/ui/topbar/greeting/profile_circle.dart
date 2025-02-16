import 'package:flutter/material.dart';
import 'package:frontend/ui/pages/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/profile_service.dart';
import 'dart:io';

class ProfileCircle extends StatelessWidget {
  const ProfileCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileService>(
      builder: (context, profileService, child) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[400],
              image: profileService.imagePath != null
                  ? DecorationImage(
                      image: FileImage(File(profileService.imagePath!)),
                      fit: BoxFit.cover,
                    )
                  : const DecorationImage(
                      image: AssetImage('lib/ui/assets/default_image.png'),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        );
      },
    );
  }
}