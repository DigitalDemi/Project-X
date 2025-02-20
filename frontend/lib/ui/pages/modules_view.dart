import 'package:flutter/material.dart';

class ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.deepPurpleAccent, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModulesView extends StatelessWidget {
  const ModulesView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modules',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ModuleCard(
            title: 'Task Management',
            icon: Icons.task_alt,
            description: 'Organize and track your daily tasks and projects effectively',
            onTap: () {
              // Navigate to task management view
            },
          ),
          const SizedBox(height: 12),
          ModuleCard(
            title: 'Self Regulation',
            icon: Icons.psychology,
            description: 'Monitor and improve your self-regulation skills',
            onTap: () {
              // Navigate to self regulation view
            },
          ),
          const SizedBox(height: 12),
          ModuleCard(
            title: 'Learning',
            icon: Icons.school,
            description: 'Track your learning progress and manage study materials',
            onTap: () {
              // Navigate to learning view
            },
          ),
        ],
      ),
    );
  }
}