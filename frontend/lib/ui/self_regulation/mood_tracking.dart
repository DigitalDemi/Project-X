import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mood_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_mood_entry_dialog.dart';

class MoodTrackingPage extends StatelessWidget {
  const MoodTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Mood Tracking'),
        elevation: 0,
      ),
      body: Consumer<MoodService>(
        builder: (context, moodService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMoodHeader(context, moodService),
                const SizedBox(height: 24),
                
                // 7-day mood trend
                _buildMoodTrendChart(moodService),
                const SizedBox(height: 24),
                
                // Hourly pattern
                _buildHourlyMoodChart(moodService),
                const SizedBox(height: 24),
                
                // Mood factors
                _buildMoodFactorsSection(moodService),
                const SizedBox(height: 24),
                
                // Recent entries
                _buildRecentEntries(moodService),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMoodDialog(context),
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMoodHeader(BuildContext context, MoodService moodService) {
    final averageMood = moodService.averageMoodToday;
    
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
                Icons.mood,
                color: Colors.deepPurpleAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Mood Tracker',
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
            'Today\'s average mood:',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          
          // Mood indicator
          Row(
            children: [
              if (averageMood > 0)
                _buildMoodIndicator(averageMood.round())
              else
                Text(
                  'No mood entries today',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _showAddMoodDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Log Mood'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrendChart(MoodService moodService) {
    final moodTrend = moodService.getMoodTrend();
    final hasData = moodTrend.any((entry) => entry['mood'] != null);
    
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
            '7-Day Mood Trend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          if (!hasData)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Not enough data to show trend',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            )
          else
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
                          if (value.toInt() >= moodTrend.length) return const Text('');
                          final date = moodTrend[value.toInt()]['date'] as DateTime;
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
                          if (value % 1 != 0) return const Text('');
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          );
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
                      spots: List.generate(moodTrend.length, (index) {
                        final mood = moodTrend[index]['mood'] as double?;
                        return FlSpot(
                          index.toDouble(), 
                          mood?.toDouble() ?? 0,
                        );
                      }),
                      isCurved: true,
                      color: Colors.deepPurpleAccent,
                      barWidth: 4,
                      dotData: FlDotData(show: true),
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

  Widget _buildHourlyMoodChart(MoodService moodService) {
    final hourlyData = moodService.getHourlyMoodPattern();
    final hasData = hourlyData.any((entry) => entry['mood'] != null);
    
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
            'Mood by Time of Day',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          if (!hasData)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Not enough data to show pattern',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: List.generate(hourlyData.length ~/ 3, (index) {
                    final i = index * 3; // Every 3 hours
                    final entry = hourlyData[i];
                    final hour = entry['hour'] as int;
                    final mood = entry['mood'] as double?;
                    
                    return BarChartGroupData(
                      x: hour,
                      barRods: [
                        BarChartRodData(
                          toY: mood?.toDouble() ?? 0,
                          color: Colors.deepPurpleAccent,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          if (hour % 3 != 0) return const Text('');
                          return Text(
                            '$hour:00',
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
                          if (value % 1 != 0) return const Text('');
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          );
                        },
                        reservedSize: 22,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoodFactorsSection(MoodService moodService) {
    final factors = moodService.getCommonFactors();
    final sortedFactors = factors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
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
            'Common Mood Factors',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (sortedFactors.isEmpty)
            Text(
              'No mood factors recorded yet',
              style: TextStyle(color: Colors.grey[400]),
            )
          else
            Column(
              children: sortedFactors.take(5).map((entry) {
                final factor = entry.key;
                final count = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          factor,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: count / (sortedFactors.first.value * 1.2),
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurpleAccent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        count.toString(),
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentEntries(MoodService moodService) {
    final entries = moodService.entries;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Entries',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                Icon(Icons.mood, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                const Text(
                  'No mood entries yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start tracking your mood to see patterns',
                  style: TextStyle(color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length.clamp(0, 5), // Show only the most recent 5
            itemBuilder: (context, index) {
              final entry = entries[index];
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildMoodIndicator(entry.rating),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTimestamp(entry.timestamp),
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          if (entry.note != null && entry.note!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              entry.note!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                          if (entry.factors.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: entry.factors.map((factor) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    factor,
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
            },
          ),
      ],
    );
  }

  Widget _buildMoodIndicator(int rating) {
    Color color;
    IconData icon;
    String label;
    
    switch (rating) {
      case 1:
        color = Colors.red;
        icon = Icons.sentiment_very_dissatisfied;
        label = 'Very Bad';
        break;
      case 2:
        color = Colors.orange;
        icon = Icons.sentiment_dissatisfied;
        label = 'Bad';
        break;
      case 3:
        color = Colors.yellow;
        icon = Icons.sentiment_neutral;
        label = 'Neutral';
        break;
      case 4:
        color = Colors.lightGreen;
        icon = Icons.sentiment_satisfied;
        label = 'Good';
        break;
      case 5:
        color = Colors.green;
        icon = Icons.sentiment_very_satisfied;
        label = 'Very Good';
        break;
      default:
        color = Colors.grey;
        icon = Icons.sentiment_neutral;
        label = 'Unknown';
    }
    
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (timestamp.year == today.year && timestamp.month == today.month && timestamp.day == today.day) {
      return 'Today at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (timestamp.year == yesterday.year && timestamp.month == yesterday.month && timestamp.day == yesterday.day) {
      return 'Yesterday at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showAddMoodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddMoodEntryDialog(),
    );
  }
}