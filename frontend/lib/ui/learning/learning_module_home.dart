// lib/ui/learning/learning_module_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models and Services
import 'package:frontend/models/topic.dart'; // Still needed for service type
import 'package:frontend/services/learning_service.dart';

// Pages for Navigation
import 'package:frontend/ui/pages/add_topic_page.dart';
import 'package:frontend/ui/learning/session_planner_page.dart';
import 'package:frontend/ui/learning/progress_visualisation_page.dart';
import 'package:frontend/ui/learning/topic_explorer.dart'; // Import the new page

// --- Main Learning Module Widget ---
class LearningModuleHome extends StatelessWidget {
  const LearningModuleHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider remains here, providing the service down the tree
    return ChangeNotifierProvider(
      create: (_) => LearningService()..fetchTopics(), // Create and fetch initial data
      // Use the StatelessWidget for content now
      child: const _LearningModuleHomeContent(),
    );
  }
}

// --- Content Display Widget (Now StatelessWidget) ---
class _LearningModuleHomeContent extends StatelessWidget {
  const _LearningModuleHomeContent(); // No state needed here anymore

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Learning Module'), // Title matches the image
        elevation: 0, // No shadow to match image style
         actions: [ // Keep refresh action
           Consumer<LearningService>( // Use Consumer to access service for refresh
             builder: (context, learningService, _) => IconButton(
               icon: const Icon(Icons.refresh),
               tooltip: 'Refresh Data',
               onPressed: learningService.isLoading ? null : () => learningService.fetchTopics(),
             ),
           ),
         ],
      ),
      body: SafeArea(
        child: Consumer<LearningService>( // Consume service for stats and status
          builder: (context, learningService, child) {
            // Show loading indicator only on initial load
            if (learningService.isLoading && learningService.topics.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                ),
              );
            }
            // Show simple error if initial load fails
             if (learningService.error != null && learningService.topics.isEmpty) {
               return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Failed to load data: ${learningService.error}',
                      style: TextStyle(color: Colors.red[300]),
                      textAlign: TextAlign.center,
                    ),
                  )
                );
             }

            // Get stats needed for the summary card
            final topicCount = learningService.topics.length;
            final dueTopicsCount = learningService.getDueTopics().length;

            // Main layout matching the image
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Stats Summary Card ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850], // Match card color from image
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatWidget(
                          context,
                          Icons.book, // Or Icons.library_books if preferred
                          topicCount.toString(),
                          'Total Topics',
                          Colors.blue.shade400, // Adjusted blue color
                        ),
                        _buildStatWidget(
                          context,
                          Icons.access_time,
                          dueTopicsCount.toString(),
                          'Due for Review',
                          Colors.orange.shade600, // Adjusted orange color
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Navigation Cards ---
                  _buildModuleCard(
                    context,
                    'Topic Explorer',
                    'Manage your learning topics and subjects',
                    Icons.account_tree, // Icon from image
                    Colors.deepPurpleAccent, // Color from image
                    () => Navigator.push(
                      context,
                      // Ensure the provider is available to the pushed route
                      MaterialPageRoute(builder: (_) => const TopicExplorerPage()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildModuleCard(
                    context,
                    'Session Planner',
                    'Create optimized study sessions',
                    Icons.schedule, // Icon from image
                    Colors.green.shade500, // Adjusted green color
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
                    Icons.insights, // Icon from image (show_chart could also work)
                    Colors.blue.shade400, // Adjusted blue color
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
                    Icons.add_circle_outline, // Icon from image
                    Colors.amber.shade700, // Adjusted amber/yellow color
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddTopicPage()),
                    ).then((_) {
                       // Refresh data after potentially adding a topic
                       // Use the service from the provider
                       Provider.of<LearningService>(context, listen: false).fetchTopics();
                     }),
                  ),
                  const SizedBox(height: 24), // Extra space at the bottom
                ],
              ),
            );
          },
        ),
      ),
      // --- Removed Bottom Navigation Bar ---
      // bottomNavigationBar: BottomNavigationBar(...),
    );
  }

  // --- Helper Function for Stats Widgets ---
  Widget _buildStatWidget(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28), // Adjusted size
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26, // Adjusted size
            fontWeight: FontWeight.w600,
          ),
        ),
         const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 13), // Adjusted size
        ),
      ],
    );
  }


  // --- Helper Function for Navigation Cards ---
  Widget _buildModuleCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.grey[850], // Card background color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0, // No shadow
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: color.withAlpha(30), // Subtle splash effect
        highlightColor: color.withAlpha(20), // Subtle highlight effect
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container( // Circular background for icon
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(51), // Icon background with opacity
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded( // Text takes remaining space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17, // Adjusted size
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
                      maxLines: 2, // Allow description to wrap if needed
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]), // Navigation arrow
            ],
          ),
        ),
      ),
    );
  }
}