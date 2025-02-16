import 'package:flutter/material.dart';
import 'package:frontend/ui/navigation/shared/top_bar.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar()
               // top bar
               // Date Scroller
               // Show Calender events block
               // Show tasks based on block
               // Tasks list
               // Next time block
            ],
          ),
        ),
      ),
    );
  }
}