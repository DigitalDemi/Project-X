import 'package:flutter/material.dart';

class FireIcon extends StatelessWidget {
  const FireIcon({super.key});

  @override
  Widget build(BuildContext context) {
    // Example implementation - customize as needed
    return Icon(
      Icons.local_fire_department_rounded, // Or Icons.whatshot
      color: Colors.orangeAccent[100], // Softer orange/yellow
      size: 20, // Adjust size as needed
    );
  }
}