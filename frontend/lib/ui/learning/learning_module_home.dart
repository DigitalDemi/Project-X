// lib/ui/learning/learning_module_home.dart
import 'package:flutter/material.dart';
import 'package:frontend/ui/pages/learning_dashboard.dart';
import 'package:frontend/ui/learning/progress_visualisation_page.dart';
import 'package:frontend/ui/learning/session_planner_page.dart';
import 'package:frontend/ui/pages/add_topic_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/learning_service.dart';

class LearningModuleHome extends StatelessWidget {
  const LearningModuleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Learning Module'),
        elevation: 0,
      ),
      body: Consumer<LearningService>(
        builder: (context, learningService, child) {
          final topicCount = learningService.topics.length;
          final dueTopics = learningService.getDueTopics().length;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatWidget(
                        context, 
                        Icons.book, 
                        topicCount.toString(), 
                        'Total Topics',
                        Colors.blue,
                      ),
                      _buildStatWidget(
                        context, 
                        Icons.access_time, 
                        dueTopics.toString(), 
                        'Due for Review',
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Module cards
                _buildModuleCard(
                  context,
                  'Topic Explorer',
                  'Manage your learning topics and subjects',
                  Icons.account_tree,
                  Colors.deepPurpleAccent,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LearningDashboard()),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildModuleCard(
                  context,
                  'Session Planner',
                  'Create optimized study sessions',
                  Icons.schedule,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SessionPlannerPage()),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildModuleCard(
                  context,
                  'Learning Progress',
                  'Visualize your learning journey',
                  Icons.insights,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProgressVisualizationPage()),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildModuleCard(
                  context,
                  'Add New Topic',
                  'Expand your knowledge graph',
                  Icons.add_circle_outline,
                  Colors.amber,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddTopicPage()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatWidget(
    BuildContext context, 
    IconData icon, 
    String value, 
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}