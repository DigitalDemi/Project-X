import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/profile_service.dart'; // Ensure this import path is correct
import 'dart:io'; // Required for File

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Use listen: false in initState as we only need the initial value
    final profileService = Provider.of<ProfileService>(context, listen: false);
    _nameController = TextEditingController(text: profileService.name);

    // Add listener to focus node to trigger UI updates (like save icon visibility)
    _nameFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // Clean up resources
    _nameController.dispose();
    _nameFocusNode.removeListener(_onFocusChange);
    _nameFocusNode.dispose();
    super.dispose();
  }

  // Listener callback for focus changes on the name field
  void _onFocusChange() {
     // Trigger a rebuild when focus changes to update UI elements
     // dependent on the focus state (e.g., the save icon).
     if (mounted) { // Ensure the widget is still in the tree
        setState(() {});
     }
  }

  // --- Image Picking Logic ---
  Future<void> _pickImage() async {
    // Use listen: false for one-off actions
    final profileService = Provider.of<ProfileService>(context, listen: false);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image slightly
      );

      if (image != null) {
        // Save the path using the service
        await profileService.saveImagePath(image.path);

        // Show confirmation only if the widget is still mounted
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile image updated'),
              duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      // Handle potential errors during image picking
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            duration: const Duration(seconds: 3)),
      );
    }
  }

  // --- Name Saving Logic ---
  Future<void> _saveName() async {
    // Use listen: false for one-off actions
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final newName = _nameController.text.trim(); // Get trimmed name

    // Validation: Ensure name is not empty
    if (newName.isEmpty) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
       // Optionally reset the field to the currently saved name
       _nameController.text = profileService.name;
      return; // Stop execution if invalid
    }

    // Optimization: Only save if the name has actually changed
    if (newName != profileService.name) {
      await profileService.saveName(newName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name updated'), duration: Duration(seconds: 2)),
      );
    }

    // Dismiss the keyboard after attempting to save
    FocusScope.of(context).unfocus();
  }

  // --- "Coming Soon" Snackbar Logic ---
  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Base background color
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar blend with background
        elevation: 0, // Remove shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Standard back navigation
        ),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      // Use Consumer to rebuild parts of the UI when ProfileService changes
      body: Consumer<ProfileService>(
        builder: (context, profileService, child) {

          // --- Sync Controller with Service State ---
          if (_nameController.text != profileService.name && !_nameFocusNode.hasFocus) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                 _nameController.text = profileService.name;
              }
            });
          }

          // --- Determine Profile Image ---
          ImageProvider imageProvider;
          final String? currentImagePath = profileService.imagePath;
          if (currentImagePath != null && File(currentImagePath).existsSync()) {
             imageProvider = FileImage(File(currentImagePath));
          } else {
            imageProvider = const AssetImage('lib/ui/assets/default_image.png'); // Verify path
          }

          // --- Main Content Layout ---
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView( // Allows content to scroll if it exceeds screen height
              children: [
                const SizedBox(height: 20), // Spacing from AppBar

                // --- Profile Picture Section ---
                Center(
                  child: Stack(
                    clipBehavior: Clip.none, // Allow edit button to slightly overflow
                    children: [
                      // Display the profile image in a circle
                      CircleAvatar(
                        radius: 60, // Size of the avatar
                        backgroundColor: Colors.grey[700], // BG if image fails
                        backgroundImage: imageProvider,
                         onBackgroundImageError: (exception, stackTrace) {
                           debugPrint("Error loading settings avatar image: $exception");
                         },
                      ),
                      // Edit button positioned over the avatar
                      Positioned(
                        bottom: 0,
                        right: -5, // Slight offset for visual appeal
                        child: GestureDetector(
                          onTap: _pickImage, // Trigger image picker
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.deepPurpleAccent, // Button color
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
                const SizedBox(height: 40), // Spacing after avatar

                // --- Name Editing Section ---
                Text( // Label for the text field
                  'Display Name',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[850],
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    // Dynamic Save Icon
                    suffixIcon: (_nameFocusNode.hasFocus || _nameController.text != profileService.name)
                        ? IconButton(
                            icon: const Icon(Icons.save_alt_outlined, color: Colors.deepPurpleAccent),
                            tooltip: 'Save Name',
                            onPressed: _saveName,
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveName(),
                  onTapOutside: (event) {
                    if (_nameFocusNode.hasFocus) {
                      _nameFocusNode.unfocus();
                    }
                  },
                ),
                const SizedBox(height: 30), // Spacing

                // --- Divider ---
                 Divider(color: Colors.grey[800], height: 1),
                 const SizedBox(height: 10),

                // --- Login Option ---
                ListTile(
                  leading: const Icon(Icons.login, color: Colors.white),
                  title: const Text('Login / Account', style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  onTap: _showComingSoon,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),

                 Divider(color: Colors.grey[800], height: 1), // Divider after Login

                // The commented-out Logout Button Section has been fully removed.
                const SizedBox(height: 20), // Add some padding at the bottom

              ], // End of ListView children
            ), // End of Padding
          ); // End of Padding -> ListView
        }, // End of Consumer builder
      ), // End of Consumer
    ); // End of Scaffold
  } // End of build method
} // End of _SettingsPageState class