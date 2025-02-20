// lib/ui/navigation/shared/bottom_navigation.dart
import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatefulWidget {
  final Function(int) onTabSelected;
  final int currentIndex;

  const CustomBottomNavigation({
    super.key,
    required this.onTabSelected,
    this.currentIndex = 0,
  });

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny_outlined),
            activeIcon: Icon(Icons.wb_sunny),
            label: 'Day',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_outlined),
            activeIcon: Icon(Icons.account_tree),
            label: 'Learning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Modules',
          ),
        ],
      ),
    );
  }
}