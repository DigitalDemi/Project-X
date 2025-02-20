// lib/ui/navigation/shared/body.dart
import 'package:flutter/material.dart';
import 'package:frontend/ui/calender/calendar_view.dart';
import 'package:frontend/ui/navigation/shared/bottom_navigation.dart';
import 'package:frontend/ui/navigation/shared/top_bar.dart';
import 'package:frontend/ui/tasks/task_card.dart';
import 'package:frontend/ui/tasks/task_list.dart';
import 'package:frontend/ui/pages/learning_dashboard.dart';
import 'package:frontend/ui/pages/modules_view.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildCurrentView() {
    switch (_currentIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(),
              const SizedBox(height: 24),
              const CalendarView(),
              const SizedBox(height: 24),
              const TaskCardList(),
              const SizedBox(height: 24),
              const TaskListSection(),
            ],
          ),
        );
      case 1:
        return const LearningDashboard();
      case 2:
        return const ModulesView();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildCurrentView(),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}