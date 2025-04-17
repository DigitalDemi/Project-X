import 'package:flutter/material.dart';

class GreetingText extends StatelessWidget {
  const GreetingText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Hi Demi',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}