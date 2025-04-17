import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/profile_service.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
  final profileService = Provider.of<ProfileService>(context, listen: false);

  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      await profileService.saveImagePath(image.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated')),
      );
    }
  } catch (e) {
    debugPrint('Error picking image: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileService>(
      builder: (context, profileService, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Settings', style: TextStyle(color: Colors.white)),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
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
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _pickImage(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.deepPurpleAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}