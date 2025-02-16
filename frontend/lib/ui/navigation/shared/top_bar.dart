// ui/navigation/shared/top_bar.dart
import 'package:flutter/material.dart';
import 'package:frontend/ui/topbar/greeting/greeting_widget.dart';
import 'package:frontend/ui/topbar/status/status_widget.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GreetingWidget(),
        StatusWidget(),
      ],
    );
  }
}