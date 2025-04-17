import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/learning_service.dart';
import 'package:frontend/models/topic.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:frontend/ui/pages/add_topic_page.dart';

class ProgressVisualizationPage extends StatefulWidget {
  const ProgressVisualizationPage({super.key});

  @override
  State<ProgressVisualizationPage> createState() =>
      _ProgressVisualizationPageState();
}

class _ProgressVisualizationPageState extends State<ProgressVisualizationPage> {
  String _selectedView =
      'overview'; // 'overview', 'subjects', 'stages', 'retention'
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    // Force refresh topics when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LearningService>(context, listen: false).fetchTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Learning Progress'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildViewSelector(),
            const SizedBox(height: 24),

            // Selected visualization
            if (_selectedView == 'overview')
              _buildOverviewView()
            else if (_selectedView == 'subjects')
              _buildSubjectsView()
            else if (_selectedView == 'stages')
              _buildStagesView()
            else if (_selectedView == 'retention')
              _buildRetentionView(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildViewOption('Overview', 'overview'),
            _buildViewOption('Subjects', 'subjects'),
            _buildViewOption('Learning Stages', 'stages'),
            _buildViewOption('Retention', 'retention'),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(String label, String value) {
    final isSelected = _selectedView == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedView = value;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewView() {
    return Consumer<LearningService>(
      builder: (context, learningService, child) {
        final topics = learningService.topics;
        final stagesDistribution = learningService.getStagesDistribution();

        if (learningService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.deepPurpleAccent,
              ),
            ),
          );
        }

        if (learningService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (topics.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            _buildSummaryCards(topics),
            const SizedBox(height: 24),

            // Learning curve
            _buildLearningCurveChart(topics),
            const SizedBox(height: 24),

            // Stage distribution
            _buildStageDistributionChart(stagesDistribution),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(List<Topic> topics) {
    final activeTopics = topics.where((t) => t.status == 'active').toList();
    final completedTopics =
        topics.where((t) => t.status == 'completed').toList();
    final reviewHistory = topics.expand((t) => t.reviewHistory).toList();

    final avgReviews =
        activeTopics.isEmpty ? 0.0 : reviewHistory.length / activeTopics.length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Topics',
            topics.length.toString(),
            Icons.book,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Active Topics',
            activeTopics.length.toString(),
            Icons.play_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Completed',
            completedTopics.length.toString(),
            Icons.check_circle,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Avg Reviews',
            avgReviews.toStringAsFixed(1),
            Icons.repeat,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningCurveChart(List<Topic> topics) {
    // Group review history by date
    final reviewsByDate = <DateTime, int>{};
    // ignore: unused_local_variable
    int cumulativeReviews = 0;

    // Get all review dates
    final allDates = <DateTime>[];
    for (final topic in topics) {
      for (final review in topic.reviewHistory) {
        // Convert string dates to DateTime if needed
        final DateTime reviewDate =
            review['date'] is String
                ? DateTime.parse(review['date'] as String)
                : review['date'] as DateTime;

        allDates.add(reviewDate);
      }
    }

    // Sort dates
    allDates.sort();

    // Create cumulative data
    for (final date in allDates) {
      cumulativeReviews++;
      final key = DateTime(date.year, date.month, date.day);
      reviewsByDate[key] = (reviewsByDate[key] ?? 0) + 1;
    }

    // Convert to list for chart
    final chartData =
        reviewsByDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    if (chartData.isEmpty) {
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
              'Learning Curve',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No review data available yet',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

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
            'Learning Curve',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
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
                        if (value.toInt() % max(1, (chartData.length ~/ 5)) !=
                            0) {
                          return const SizedBox.shrink();
                        }
                        if (value.toInt() >= chartData.length) {
                          return const SizedBox.shrink();
                        }
                        final date = chartData[value.toInt()].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(chartData.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        chartData[index].value.toDouble(),
                      );
                    }),
                    isCurved: true,
                    color: Colors.deepPurpleAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
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

  Widget _buildStageDistributionChart(Map<String, int> stagesDistribution) {
    final total = stagesDistribution.values.fold(
      0,
      (sum, count) => sum + count,
    );

    if (total == 0) {
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
              'Learning Stages Distribution',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No active topics available',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

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
            'Learning Stages Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Pie chart
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _createPieSections(stagesDistribution),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),

              // Legend
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...stagesDistribution.entries.map((entry) {
                      final stage = entry.key;
                      final count = entry.value;
                      final percentage = total > 0 ? (count / total * 100) : 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getStageColor(stage),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatStageName(stage),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _createPieSections(
    Map<String, int> stagesDistribution,
  ) {
    final total = stagesDistribution.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final sections = <PieChartSectionData>[];

    if (total == 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: '',
          radius: 40,
        ),
      );
      return sections;
    }

    stagesDistribution.forEach((stage, count) {
      final percentage = (count / total * 100);

      sections.add(
        PieChartSectionData(
          color: _getStageColor(stage),
          value: count.toDouble(),
          title: percentage >= 10 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 50,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    });

    return sections;
  }

  Widget _buildSubjectsView() {
    return Consumer<LearningService>(
      builder: (context, learningService, child) {
        final topics = learningService.topics;

        if (topics.isEmpty) {
          return _buildEmptyState();
        }

        // Group topics by subject
        final subjects = <String>{};
        for (final topic in topics) {
          if (topic.status == 'active') {
            subjects.add(topic.subject);
          }
        }

        if (subjects.isEmpty) {
          return Center(
            child: Text(
              'No active topics available',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        // Subject selector
        final subjectsList = subjects.toList()..sort();
        _selectedSubject ??= subjectsList.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Subject',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          subjectsList.map((subject) {
                            final isSelected = _selectedSubject == subject;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(subject),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedSubject = subject;
                                    });
                                  }
                                },
                                backgroundColor: Colors.grey[800],
                                selectedColor: Colors.deepPurpleAccent,
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subject progress
            if (_selectedSubject != null)
              _buildSubjectProgress(topics, _selectedSubject!),
          ],
        );
      },
    );
  }

  Widget _buildSubjectProgress(List<Topic> allTopics, String subject) {
    final subjectTopics =
        allTopics
            .where((t) => t.subject == subject && t.status == 'active')
            .toList();

    if (subjectTopics.isEmpty) {
      return Center(
        child: Text(
          'No active topics in $subject',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    // Group by stage
    final Map<String, int> stageCount = {
      'first_time': 0,
      'early_stage': 0,
      'mid_stage': 0,
      'late_stage': 0,
      'mastered': 0,
    };

    for (final topic in subjectTopics) {
      stageCount[topic.stage] = (stageCount[topic.stage] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress in $subject',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Topics',
                      subjectTopics.length.toString(),
                      Icons.book,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Advanced',
                      (stageCount['late_stage']! + stageCount['mastered']!)
                          .toString(),
                      Icons.trending_up,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Mastered',
                      stageCount['mastered'].toString(),
                      Icons.verified,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Stage progress bars
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Learning Stage Breakdown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStageProgressBar('first_time', 'First Time', stageCount),
              const SizedBox(height: 12),
              _buildStageProgressBar('early_stage', 'Early Stage', stageCount),
              const SizedBox(height: 12),
              _buildStageProgressBar('mid_stage', 'Mid Stage', stageCount),
              const SizedBox(height: 12),
              _buildStageProgressBar('late_stage', 'Late Stage', stageCount),
              const SizedBox(height: 12),
              _buildStageProgressBar('mastered', 'Mastered', stageCount),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Topics list
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Topics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...subjectTopics.map((topic) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getStageColor(topic.stage).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            topic.reviewHistory.length.toString(),
                            style: TextStyle(
                              color: _getStageColor(topic.stage),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatStageName(topic.stage),
                              style: TextStyle(
                                color: _getStageColor(topic.stage),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Next: ${_formatDate(topic.nextReview)}',
                          style: const TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurpleAccent),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStageProgressBar(
    String stage,
    String label,
    Map<String, int> stageCount,
  ) {
    final total = stageCount.values.fold(0, (sum, count) => sum + count);
    final count = stageCount[stage] ?? 0;
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            Text(
              '$count topics',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progress
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _getStageColor(stage),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStagesView() {
    return Consumer<LearningService>(
      builder: (context, learningService, child) {
        final topics = learningService.topics;

        if (topics.isEmpty) {
          return _buildEmptyState();
        }

        // Group active topics by stage
        final Map<String, List<Topic>> topicsByStage = {
          'first_time': [],
          'early_stage': [],
          'mid_stage': [],
          'late_stage': [],
          'mastered': [],
        };

        for (final topic in topics) {
          if (topic.status == 'active') {
            topicsByStage[topic.stage]?.add(topic);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage cards
            _buildStageCards(topicsByStage),
            const SizedBox(height: 24),

            // Stage details
            _buildStageDetails(topicsByStage),
          ],
        );
      },
    );
  }

  Widget _buildStageCards(Map<String, List<Topic>> topicsByStage) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStageCard('first_time', 'First Time', topicsByStage),
        _buildStageCard('early_stage', 'Early Stage', topicsByStage),
        _buildStageCard('mid_stage', 'Mid Stage', topicsByStage),
        _buildStageCard('late_stage', 'Late Stage', topicsByStage),
        _buildStageCard('mastered', 'Mastered', topicsByStage),
      ],
    );
  }

  Widget _buildStageCard(
    String stage,
    String label,
    Map<String, List<Topic>> topicsByStage,
  ) {
    final topics = topicsByStage[stage] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStageColor(stage).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStageColor(stage).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                topics.length.toString(),
                style: TextStyle(
                  color: _getStageColor(stage),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${topics.length} topics',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStageDetails(Map<String, List<Topic>> topicsByStage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Topics by Learning Stage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // One section per stage
        ...topicsByStage.entries.map((entry) {
          final stage = entry.key;
          final topics = entry.value;

          if (topics.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStageColor(stage),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatStageName(stage),
                    style: TextStyle(
                      color: _getStageColor(stage),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${topics.length})',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Topic list for this stage
              Container(
                margin: const EdgeInsets.only(left: 20, bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStageColor(stage).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children:
                      topics.take(3).map((topic) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      topic.subject,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${topic.reviewHistory.length} reviews',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildRetentionView() {
    return Consumer<LearningService>(
      builder: (context, learningService, child) {
        final topics = learningService.topics;

        if (topics.isEmpty) {
          return _buildEmptyState();
        }

        // Calculate retention metrics
        final retentionData = _calculateRetentionMetrics(topics);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Retention metrics
            _buildRetentionMetricsCards(retentionData),
            const SizedBox(height: 24),

            // Difficulty distribution
            _buildDifficultyDistributionChart(retentionData),
            const SizedBox(height: 24),

            // Interval progression
            _buildIntervalProgressionChart(topics),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _calculateRetentionMetrics(List<Topic> topics) {
    int totalReviews = 0;
    int easyReviews = 0;
    int normalReviews = 0;
    int hardReviews = 0;

    final difficultyByDate = <DateTime, Map<String, int>>{};
    final Map<String, List<int>> intervalsByDifficulty = {
      'easy': [],
      'normal': [],
      'hard': [],
    };

    for (final topic in topics) {
      for (final review in topic.reviewHistory) {
        totalReviews++;
        final difficulty = review['difficulty'] as String;
        final interval = review['interval'] as int;

        final DateTime date =
            review['date'] is String
                ? DateTime.parse(review['date'] as String)
                : review['date'] as DateTime;

        // Count by difficulty
        if (difficulty == 'easy') {
          easyReviews++;
        } else if (difficulty == 'normal') {
          normalReviews++;
        } else if (difficulty == 'hard') {
          hardReviews++;
        }

        // Store intervals by difficulty
        intervalsByDifficulty[difficulty]?.add(interval);

        // Store difficulty by date
        final dateKey = DateTime(date.year, date.month, date.day);
        if (!difficultyByDate.containsKey(dateKey)) {
          difficultyByDate[dateKey] = {'easy': 0, 'normal': 0, 'hard': 0};
        }
        difficultyByDate[dateKey]![difficulty] =
            (difficultyByDate[dateKey]![difficulty] ?? 0) + 1;
      }
    }

    // Calculate average intervals
    final double avgEasyInterval =
        intervalsByDifficulty['easy']!.isEmpty
            ? 0
            : intervalsByDifficulty['easy']!.fold(
                  0,
                  (sum, interval) => sum + interval,
                ) /
                intervalsByDifficulty['easy']!.length;

    final double avgNormalInterval =
        intervalsByDifficulty['normal']!.isEmpty
            ? 0
            : intervalsByDifficulty['normal']!.fold(
                  0,
                  (sum, interval) => sum + interval,
                ) /
                intervalsByDifficulty['normal']!.length;

    final double avgHardInterval =
        intervalsByDifficulty['hard']!.isEmpty
            ? 0
            : intervalsByDifficulty['hard']!.fold(
                  0,
                  (sum, interval) => sum + interval,
                ) /
                intervalsByDifficulty['hard']!.length;

    return {
      'totalReviews': totalReviews,
      'easyReviews': easyReviews,
      'normalReviews': normalReviews,
      'hardReviews': hardReviews,
      'difficultyByDate': difficultyByDate,
      'avgEasyInterval': avgEasyInterval,
      'avgNormalInterval': avgNormalInterval,
      'avgHardInterval': avgHardInterval,
      'intervalsByDifficulty': intervalsByDifficulty,
    };
  }

  Widget _buildRetentionMetricsCards(Map<String, dynamic> retentionData) {
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
            'Retention Metrics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRetentionMetricCard(
                  'Total Reviews',
                  retentionData['totalReviews'].toString(),
                  Icons.repeat,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRetentionMetricCard(
                  'Avg. Interval (Easy)',
                  '${retentionData['avgEasyInterval'].toStringAsFixed(1)} days',
                  Icons.thumb_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRetentionMetricCard(
                  'Avg. Interval (Hard)',
                  '${retentionData['avgHardInterval'].toStringAsFixed(1)} days',
                  Icons.thumb_down,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyDistributionChart(Map<String, dynamic> retentionData) {
    final totalReviews = retentionData['totalReviews'] as int;
    final easyReviews = retentionData['easyReviews'] as int;
    final normalReviews = retentionData['normalReviews'] as int;
    final hardReviews = retentionData['hardReviews'] as int;

    if (totalReviews == 0) {
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
              'Difficulty Distribution',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No review data available yet',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

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
            'Difficulty Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: easyReviews.toDouble(),
                        color: Colors.green,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: normalReviews.toDouble(),
                        color: Colors.yellow,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: hardReviews.toDouble(),
                        color: Colors.red,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String title;
                        switch (value.toInt()) {
                          case 0:
                            title = 'Easy';
                            break;
                          case 1:
                            title = 'Normal';
                            break;
                          case 2:
                            title = 'Hard';
                            break;
                          default:
                            title = '';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPercentageIndicator(
                'Easy',
                easyReviews,
                totalReviews,
                Colors.green,
              ),
              const SizedBox(width: 24),
              _buildPercentageIndicator(
                'Normal',
                normalReviews,
                totalReviews,
                Colors.yellow,
              ),
              const SizedBox(width: 24),
              _buildPercentageIndicator(
                'Hard',
                hardReviews,
                totalReviews,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageIndicator(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0;

    return Column(
      children: [
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildIntervalProgressionChart(List<Topic> topics) {
    // Extract interval data from reviews
    final data = <MapEntry<DateTime, int>>[];

    for (final topic in topics) {
      for (final review in topic.reviewHistory) {
        // Convert string dates to DateTime if needed
        final DateTime date =
            review['date'] is String
                ? DateTime.parse(review['date'] as String)
                : review['date'] as DateTime;

        final interval = review['interval'] as int;
        data.add(MapEntry(date, interval));
      }
    }

    if (data.isEmpty) {
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
              'Interval Progression',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No review data available yet',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    // Sort by date
    data.sort((a, b) => a.key.compareTo(b.key));

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
            'Interval Progression',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How review intervals have changed over time',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: List.generate(data.length, (index) {
                  return ScatterSpot(
                    index.toDouble(),
                    data[index].value.toDouble(),
                    dotPainter: FlDotCirclePainter(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                      radius: 5,
                    ),
                  );
                }),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= data.length ||
                            index % (data.length ~/ 5 + 1) != 0) {
                          return const SizedBox.shrink();
                        }

                        final date = data[index].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 5 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${value.toInt()} days',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Each dot represents a review interval',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.book, size: 48, color: Colors.grey[600]),
        const SizedBox(height: 16),
        const Text(
          'No topics available',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Add topics in the Learning Dashboard',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            // Push the AddTopicPage
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTopicPage()),
            );
            // If this state got disposed (page popped) during the push, bail out
            if (!mounted) return;
            // Otherwise it's safe to re-fetch
            Provider.of<LearningService>(context, listen: false)
                .fetchTopics();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
          ),
          child: const Text('Add Your First Topic'),
        ),
      ],
    ),
  );
}


  Color _getStageColor(String stage) {
    switch (stage) {
      case 'first_time':
        return Colors.red;
      case 'early_stage':
        return Colors.orange;
      case 'mid_stage':
        return Colors.yellow;
      case 'late_stage':
        return Colors.green;
      case 'mastered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatStageName(String stage) {
    switch (stage) {
      case 'first_time':
        return 'First Time';
      case 'early_stage':
        return 'Early Stage';
      case 'mid_stage':
        return 'Mid Stage';
      case 'late_stage':
        return 'Late Stage';
      case 'mastered':
        return 'Mastered';
      default:
        return stage;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
