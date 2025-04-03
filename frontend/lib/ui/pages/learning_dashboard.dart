// lib/ui/pages/learning_dashboard.dart
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/learning_service.dart';
import 'package:frontend/ui/pages/add_topic_page.dart';
import 'package:frontend/models/topic.dart';

class LearningDashboard extends StatelessWidget {
  const LearningDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LearningService(),
      child: const _LearningDashboardContent(),
    );
  }
}

class _LearningDashboardContent extends StatelessWidget {
  const _LearningDashboardContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<LearningService>(
          builder: (context, learningService, child) {
            if (learningService.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                ),
              );
            }

            if (learningService.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${learningService.error}',
                      style: TextStyle(color: Colors.red[400]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => learningService.fetchTopics(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final totalTopics = learningService.topics.length;
            final dueTopics = learningService.getDueTopics();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[900]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Learning Dashboard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Total Topics: ',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '$totalTopics',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddTopicPage(),
                                ),
                              ).then((_) => learningService.fetchTopics());
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Add New Topic',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KnowledgeGraphCard(topics: learningService.topics),
                        const SizedBox(height: 24),
                        DueForReviewCard(dueTopics: dueTopics, onReview: (topicId, difficulty) {
                          learningService.reviewTopic(topicId, difficulty);
                        }),
                        const SizedBox(height: 24),
                        ChartGrid(learningService: learningService),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class KnowledgeGraphCard extends StatelessWidget {
  final List<Topic> topics;

  const KnowledgeGraphCard({super.key, required this.topics});

  @override
  Widget build(BuildContext context) {
    // Group topics by subject
    final Map<String, List<Topic>> topicsBySubject = {};
    for (final topic in topics) {
      if (!topicsBySubject.containsKey(topic.subject)) {
        topicsBySubject[topic.subject] = [];
      }
      topicsBySubject[topic.subject]!.add(topic);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                color: Colors.deepPurpleAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Knowledge Graph',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            width: double.infinity,
            child: topics.isEmpty
                ? Center(
                    child: Text(
                      'No topics yet. Add your first topic!',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : CustomPaint(
                    painter: KnowledgeGraphPainter(topicsBySubject),
                  ),
          ),
        ],
      ),
    );
  }
}

class KnowledgeGraphPainter extends CustomPainter {
  final Map<String, List<Topic>> topicsBySubject;

  KnowledgeGraphPainter(this.topicsBySubject);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurpleAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final nodeFillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final center = Offset(size.width / 2, size.height / 2);
    
    // Only show visualization if there are subjects
    if (topicsBySubject.isEmpty) return;
    
    // Draw main subjects as nodes
    final subjects = topicsBySubject.keys.toList();
    final subjectRadius = 40.0;
    final orbitRadius = 120.0;
    
    for (var i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      final angle = (i * 2 * 3.14159 / subjects.length) - 3.14159 / 4;
      final x = center.dx + orbitRadius * 0.8 * Math.cos(angle);
      final y = center.dy + orbitRadius * 0.8 * Math.sin(angle);
      final nodeCenter = Offset(x, y);
      
      // Node
      canvas.drawCircle(nodeCenter, subjectRadius, nodeFillPaint);
      canvas.drawCircle(nodeCenter, subjectRadius, paint);
      _drawText(canvas, textPainter, subject, nodeCenter, Colors.white70);
      
      // Draw topics around subject
      final topics = topicsBySubject[subject]!;
      
      if (topics.isNotEmpty) {
        final topicRadius = 20.0;
        final topicOrbitRadius = subjectRadius * 2.0;
        
        for (var j = 0; j < topics.length; j++) {
          final topic = topics[j];
          final topicAngle = angle + (j * 2 * 3.14159 / topics.length) - 3.14159 / 4;
          
          final tx = x + topicOrbitRadius * Math.cos(topicAngle);
          final ty = y + topicOrbitRadius * Math.sin(topicAngle);
          final topicCenter = Offset(tx, ty);
          
          // Connection line
          canvas.drawLine(nodeCenter, topicCenter, paint);
          
          // Topic node with color based on stage
          final topicFillPaint = Paint()
            ..color = _getStageColor(topic.stage)
            ..style = PaintingStyle.fill;
            
          canvas.drawCircle(topicCenter, topicRadius, topicFillPaint);
          canvas.drawCircle(topicCenter, topicRadius, paint);
          _drawText(canvas, textPainter, topic.name, topicCenter, Colors.black);
        }
      }
    }
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'first_time': return Colors.red.withOpacity(0.7);
      case 'early_stage': return Colors.orange.withOpacity(0.7);
      case 'mid_stage': return Colors.yellow.withOpacity(0.7);
      case 'late_stage': return Colors.green.withOpacity(0.7);
      case 'mastered': return Colors.blue.withOpacity(0.7);
      default: return Colors.grey.withOpacity(0.7);
    }
  }

  void _drawText(Canvas canvas, TextPainter textPainter, String text, Offset center, Color color) {
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout(maxWidth: 80);
    textPainter.paint(
      canvas,
      center + Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DueForReviewCard extends StatelessWidget {
  final List<Topic> dueTopics;
  final Function(String, String) onReview;

  const DueForReviewCard({
    super.key, 
    required this.dueTopics,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.deepPurpleAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Due for Review',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          dueTopics.isEmpty
              ? const Text(
                  'No topics due for review!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                )
              : Column(
                  children: dueTopics.map((topic) => _buildReviewItem(context, topic)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Topic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${topic.subject} - ${topic.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stage: ${topic.stage}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDifficultyButton(
                context, 
                'Hard', 
                Colors.red[400]!, 
                () => onReview(topic.id, 'hard')
              ),
              _buildDifficultyButton(
                context, 
                'Normal', 
                Colors.amber, 
                () => onReview(topic.id, 'normal')
              ),
              _buildDifficultyButton(
                context, 
                'Easy', 
                Colors.green[400]!, 
                () => onReview(topic.id, 'easy')
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context, 
    String label, 
    Color color, 
    VoidCallback onPressed
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}

class ChartGrid extends StatelessWidget {
  final LearningService learningService;

  const ChartGrid({super.key, required this.learningService});

  Widget _buildChart(String title, Widget chart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: chart,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stagesDistribution = learningService.getStagesDistribution();
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildChart(
                'Learning Stages',
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final stages = ['first_time', 'early_stage', 'mid_stage', 'late_stage', 'mastered'];
                            if (value.toInt() < stages.length) {
                              return Text(
                                stages[value.toInt()].split('_').join(' ').capitalize(),
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    barGroups: _createBarGroups(stagesDistribution),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChart(
                'Learning Stage Distribution',
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: _createPieSections(stagesDistribution),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<BarChartGroupData> _createBarGroups(Map<String, int> stagesDistribution) {
    final stages = ['first_time', 'early_stage', 'mid_stage', 'late_stage', 'mastered'];
    final maxValue = stagesDistribution.values.fold(0, (max, value) => value > max ? value : max);
    
    return List.generate(stages.length, (index) {
      final stage = stages[index];
      final value = stagesDistribution[stage] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: maxValue > 0 ? value.toDouble() : 0.1,
            color: Colors.deepPurpleAccent.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  List<PieChartSectionData> _createPieSections(Map<String, int> stagesDistribution) {
    final stages = ['first_time', 'early_stage', 'mid_stage', 'late_stage', 'mastered'];
    final colors = [
      Colors.red.withOpacity(0.7),
      Colors.orange.withOpacity(0.7),
      Colors.yellow.withOpacity(0.7),
      Colors.green.withOpacity(0.7),
      Colors.blue.withOpacity(0.7),
    ];
    
    final total = stagesDistribution.values.fold(0, (sum, value) => sum + value);
    
    if (total == 0) {
      // If no data, show placeholder
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.withOpacity(0.3),
          title: 'No data',
          radius: 50,
          titleStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ];
    }
    
    return List.generate(stages.length, (index) {
      final stage = stages[index];
      final value = stagesDistribution[stage] ?? 0;
      return PieChartSectionData(
        value: value.toDouble(),
        color: colors[index],
        title: value > 0 ? '${(value / total * 100).round()}%' : '',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    });
  }
}

// Extension to capitalize first letter of each word
extension StringExtension on String {
  String capitalize() {
    return split(' ').map((word) => word.isNotEmpty 
      ? '${word[0].toUpperCase()}${word.substring(1)}' 
      : '').join(' ');
  }
}