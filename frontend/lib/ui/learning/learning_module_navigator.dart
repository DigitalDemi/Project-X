// lib/ui/learning/learning_module_navigator.dart
import 'package:flutter/material.dart';
import 'package:frontend/ui/pages/learning_dashboard.dart';
import 'package:frontend/ui/content/learning_resources_page.dart';
import 'package:frontend/ui/learning/progress_visualisation_page.dart';
import 'package:frontend/ui/learning/session_planner_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/learning_service.dart';

class LearningModuleNavigator extends StatefulWidget {
  const LearningModuleNavigator({super.key});

  @override
  State<LearningModuleNavigator> createState() => _LearningModuleNavigatorState();
}

class _LearningModuleNavigatorState extends State<LearningModuleNavigator> {
  int _currentIndex = 0;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabItem(0, 'Topic Explorer', Icons.account_tree),
                  _buildTabItem(1, 'Resources', Icons.menu_book),
                  _buildTabItem(2, 'Session Planner', Icons.schedule),
                  _buildTabItem(3, 'Progress', Icons.insights),
                ],
              ),
            ),
          ),
          
          // Body content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // Topic Explorer (Learning Dashboard)
                Navigator(
                  key: _navigatorKey,
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => const LearningDashboard(),
                    );
                  },
                ),
                
                // Resources
                const LearningResourcesPage(),
                
                // Session Planner
                const SessionPlannerPage(),
                
                // Progress Visualization
                const ProgressVisualizationPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurpleAccent : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.deepPurpleAccent : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}