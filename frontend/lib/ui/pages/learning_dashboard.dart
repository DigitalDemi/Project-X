import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';

class LearningDashboard extends StatelessWidget {
  const LearningDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Learning Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Text('Total Topics: 3'),
                      SizedBox(width: 8),
                      Text('Due for Review: 0'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Add New Topic Button
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement add topic
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Topic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Knowledge Graph
            const KnowledgeGraphCard(),
            const SizedBox(height: 24),

            // Due for Review
            const DueForReviewCard(),
            const SizedBox(height: 24),

            // Charts Grid
            const ChartGrid(),
          ],
        ),
      ),
    );
  }
}

class KnowledgeGraphCard extends StatelessWidget {
  const KnowledgeGraphCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_tree_outlined),
                SizedBox(width: 8),
                Text(
                  'Knowledge Graph',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: CustomPaint(
                painter: KnowledgeGraphPainter(),
                size: const Size(double.infinity, 300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KnowledgeGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw nodes and connections for Mathematics, Programming, etc.
    // This is a simplified version - you'd want to make this more dynamic
    // Draw connections
    canvas.drawLine(
      const Offset(200, 150),
      const Offset(150, 100),
      paint,
    );
    canvas.drawLine(
      const Offset(200, 150),
      const Offset(250, 100),
      paint,
    );

    // Draw nodes
    final nodePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(200, 150), 20, nodePaint);
    canvas.drawCircle(const Offset(150, 100), 15, Paint()..color = Colors.green);
    canvas.drawCircle(const Offset(250, 100), 15, Paint()..color = Colors.lightBlue);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DueForReviewCard extends StatelessWidget {
  const DueForReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Due for Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'No topics due for review!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartGrid extends StatelessWidget {
  const ChartGrid({super.key});

  @override
  Widget build(BuildContext context) {
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
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: 0.75,
                            color: Colors.purple[200],
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: 0.75,
                            color: Colors.purple[200],
                          ),
                        ],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return const Text('first_time');
                              case 1:
                                return const Text('early_stage');
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChart(
                'Review Difficulty',
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: 2.0,
                            color: Colors.green[300],
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: 1.0,
                            color: Colors.green[300],
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: 3.0,
                            color: Colors.green[300],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildChart(
                'Learning Stage Distribution',
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: 50,
                        color: Colors.red[200],
                        title: 'first_time',
                      ),
                      PieChartSectionData(
                        value: 50,
                        color: Colors.green[200],
                        title: 'early_stage',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChart(
                'Review Timeline',
                LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 0),
                          FlSpot(1, 0),
                          FlSpot(2, 0),
                        ],
                        isCurved: true,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(String title, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}