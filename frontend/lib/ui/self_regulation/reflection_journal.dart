// lib/ui/self_regulation/reflection_journal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/reflection_service.dart';
import '../../models/reflection.dart';
import 'add_reflection_dialog.dart';
import 'package:fl_chart/fl_chart.dart';

class ReflectionJournalPage extends StatelessWidget {
  const ReflectionJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Reflection Journal'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddReflectionDialog(context),
          ),
        ],
      ),
      body: Consumer<ReflectionService>(
        builder: (context, reflectionService, child) {
          final reflections = reflectionService.reflections;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJournalHeader(context, reflectionService),
                const SizedBox(height: 24),
                
                // Mood trends chart
                if (reflectionService.getMoodTrend().isNotEmpty)
                  _buildMoodTrendChart(reflectionService),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Journal Entries',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (reflections.isEmpty)
                  _buildEmptyState()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reflections.length,
                    itemBuilder: (context, index) {
                      return ReflectionCard(
                        reflection: reflections[index],
                        onDelete: () => _confirmDeleteReflection(
                          context, 
                          reflectionService, 
                          reflections[index].id,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<ReflectionService>(
        builder: (context, reflectionService, child) {
          // Only show FAB if no reflection for today
          if (reflectionService.hasTodayReflection) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: () => _showAddReflectionDialog(context),
            backgroundColor: Colors.deepPurpleAccent,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildJournalHeader(
    BuildContext context, 
    ReflectionService reflectionService,
  ) {
    final hasTodayReflection = reflectionService.hasTodayReflection;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: Colors.deepPurpleAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Reflection Journal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasTodayReflection
                ? 'You\'ve already reflected today.'
                : 'Take a moment to reflect on your day.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          if (!hasTodayReflection)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showAddReflectionDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Write Today\'s Reflection'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoodTrendChart(ReflectionService reflectionService) {
    final moodData = reflectionService.getMoodTrend();
    
    // Only show last 7 days
    final recentData = moodData.length > 7 
        ? moodData.sublist(moodData.length - 7) 
        : moodData;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood Trends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= recentData.length) return const Text('');
                        final date = recentData[value.toInt()]['date'] as DateTime;
                        return Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        );
                        // lib/ui/self_regulation/reflection_journal.dart (continued)
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(recentData.length, (index) {
                      return FlSpot(
                        index.toDouble(), 
                        (recentData[index]['mood'] as double),
                      );
                    }),
                    isCurved: true,
                    color: Colors.deepPurpleAccent,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.deepPurpleAccent.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text(
            'No Journal Entries Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start reflecting on your day to build self-awareness',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddReflectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddReflectionDialog(),
    );
  }

  void _confirmDeleteReflection(
    BuildContext context,
    ReflectionService reflectionService,
    String reflectionId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Entry', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this reflection? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              reflectionService.deleteReflection(reflectionId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ReflectionCard extends StatelessWidget {
  final Reflection reflection;
  final VoidCallback onDelete;

  const ReflectionCard({
    super.key,
    required this.reflection,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(reflection.date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? Colors.deepPurpleAccent : Colors.grey[800]!,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _formatDate(reflection.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isToday)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                if (reflection.moodRating != null)
                  _buildMoodIndicator(reflection.moodRating!),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reflection.content,
                  style: const TextStyle(color: Colors.white),
                ),
                
                if (reflection.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reflection.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodIndicator(int rating) {
    Color color;
    IconData icon;
    
    switch (rating) {
      case 1:
        color = Colors.red;
        icon = Icons.sentiment_very_dissatisfied;
        break;
      case 2:
        color = Colors.orange;
        icon = Icons.sentiment_dissatisfied;
        break;
      case 3:
        color = Colors.yellow;
        icon = Icons.sentiment_neutral;
        break;
      case 4:
        color = Colors.lightGreen;
        icon = Icons.sentiment_satisfied;
        break;
      case 5:
        color = Colors.green;
        icon = Icons.sentiment_very_satisfied;
        break;
      default:
        color = Colors.grey;
        icon = Icons.sentiment_neutral;
    }
    
    return Icon(icon, color: color, size: 20);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}