import 'dart:math' as math; // For trigonometric calculations in painter
import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart'; // Unused import removed
import 'package:provider/provider.dart';

// Models and Services
import 'package:frontend/models/topic.dart';
import 'package:frontend/services/learning_service.dart';

// Pages for Navigation
import 'package:frontend/ui/pages/add_topic_page.dart';
import 'package:frontend/ui/content/topic_content_page.dart';
import 'package:frontend/ui/learning/session_planner_page.dart';
import 'package:frontend/ui/learning/progress_visualisation_page.dart';

// Widgets
import 'package:frontend/ui/learning/widgets/knowledge_graph_legend.dart'; // Path to the legend file

// --- Main Merged Widget ---
class LearningModuleHome extends StatelessWidget {
  const LearningModuleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LearningService()..fetchTopics(),
      child: const _LearningModuleHomeContent(),
    );
  }
}

// --- Content Display Widget ---
class _LearningModuleHomeContent extends StatelessWidget {
  const _LearningModuleHomeContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        // Modified title to include topic count
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Learning Dashboard'),
            const SizedBox(width: 8),
            Consumer<LearningService>( // Need Consumer to get latest count
              builder: (context, learningService, _) => Chip(
                label: Text(
                  '${learningService.topics.length}', // Use service directly
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: -2),
                backgroundColor: Colors.deepPurpleAccent.withAlpha(128), // Fixed deprecation
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
              ),
            ),
          ],
        ),
        elevation: 1,
        actions: [
          Consumer<LearningService>(
            builder: (context, learningService, _) => IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: learningService.isLoading ? null : () => learningService.fetchTopics(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<LearningService>(
          builder: (context, learningService, child) {
            if (learningService.isLoading && learningService.topics.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                ),
              );
            }

            if (learningService.error != null && learningService.topics.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading learning data: ${learningService.error}',
                        style: TextStyle(color: Colors.red[400], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => learningService.fetchTopics(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              );
            }

            // final totalTopics = learningService.topics.length; // Variable removed as it's now used in AppBar
            final dueTopics = learningService.getDueTopics();

            return RefreshIndicator(
              onRefresh: () => learningService.fetchTopics(),
              color: Colors.deepPurpleAccent,
              backgroundColor: Colors.grey[900],
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTopicPage()))
                              .then((_) => learningService.fetchTopics());
                        },
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        label: const Text('Add New Topic', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    KnowledgeGraphCard(
                      topics: learningService.topics,
                      onTopicTap: (topic) {
                        debugPrint("Navigating to topic: ${topic.name}");
                        if (topic.id.startsWith('subject_')) {
                          debugPrint("Tapped on subject node: ${topic.name}");
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TopicContentPage(topic: topic)),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    DueForReviewCard(
                      dueTopics: dueTopics,
                      onReview: (topicId, difficulty) {
                        learningService.reviewTopic(topicId, difficulty);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Topic marked as "$difficulty".'),
                            backgroundColor: Colors.grey[800],
                            duration: const Duration(seconds: 2),
                          )
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // ChartGrid(learningService: learningService), // Placeholder
                    // const SizedBox(height: 24),

                    const Text(
                      'Tools & Features',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    _buildModuleCard(
                      context,
                      'Session Planner',
                      'Create optimized study sessions',
                      Icons.schedule,
                      Colors.green,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SessionPlannerPage())),
                    ),
                    const SizedBox(height: 16),

                    _buildModuleCard(
                      context,
                      'Learning Progress',
                      'Visualize your learning journey',
                      Icons.insights,
                      Colors.blue,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressVisualizationPage())),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
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
                  color: color.withAlpha(51), // Fixed deprecation (0.2 opacity)
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
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
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

// --- Knowledge Graph Card Widget ---
class KnowledgeGraphCard extends StatefulWidget {
  final List<Topic> topics;
  final Function(Topic topic)? onTopicTap;

  const KnowledgeGraphCard({super.key, required this.topics, this.onTopicTap});

  @override
  State<KnowledgeGraphCard> createState() => _KnowledgeGraphCardState();
}

class _KnowledgeGraphCardState extends State<KnowledgeGraphCard> {
  late KnowledgeGraphPainter _painter;
  // Use the now public NodeInfo type
  final List<NodeInfo> _nodeInfos = [];
  final GlobalKey _painterKey = GlobalKey(); // Key for tap handling

  @override
  void initState() {
    super.initState();
    // Pass the public list type
    _painter = KnowledgeGraphPainter(widget.topics, _nodeInfos);
  }

  @override
  void didUpdateWidget(covariant KnowledgeGraphCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topics != oldWidget.topics) {
      _nodeInfos.clear();
      // Pass the public list type
      _painter = KnowledgeGraphPainter(widget.topics, _nodeInfos);
    }
  }

  void _handleTap(TapUpDetails details) {
    final RenderBox? customPaintBox = _painterKey.currentContext?.findRenderObject() as RenderBox?;
    if (customPaintBox == null) {
       debugPrint("Knowledge Graph: Could not find RenderBox for CustomPaint.");
       return;
    }

    // Get tap position relative to the CustomPaint widget itself
    final Offset tapPositionInPainter = customPaintBox.globalToLocal(details.globalPosition);

    // final Offset painterOffset = cardPadding.topLeft + const Offset(0, 48); // Variable removed

    final Topic? tappedTopic = _findTappedTopic(tapPositionInPainter);

    if (tappedTopic != null) {
      debugPrint("Knowledge Graph: Tapped on Topic -> ${tappedTopic.name} (ID: ${tappedTopic.id})");
      widget.onTopicTap?.call(tappedTopic);
    } else {
      debugPrint("Knowledge Graph: Tap missed nodes at $tapPositionInPainter");
    }
  }

  Topic? _findTappedTopic(Offset tapPosition) {
    for (final nodeInfo in _nodeInfos) {
      final distanceSquared = (tapPosition - nodeInfo.center).distanceSquared;
      const tapRadiusBuffer = 5.0;
      if (distanceSquared <= math.pow(nodeInfo.radius + tapRadiusBuffer, 2)) {
        return nodeInfo.topic;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, color: Colors.deepPurpleAccent, size: 24),
              const SizedBox(width: 8),
              const Text('Knowledge Graph', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            width: double.infinity,
            child: widget.topics.isEmpty
                ? Center(child: Text('No topics yet. Add your first topic!', style: TextStyle(color: Colors.grey[400])))
                : GestureDetector(
                    onTapUp: _handleTap,
                    child: ClipRect(
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(80.0),
                        minScale: 0.2,
                        maxScale: 5.0,
                        child: CustomPaint(
                          key: _painterKey, // Assign key
                          size: Size.infinite,
                          painter: _painter,
                        ),
                      ),
                    ),
                  ),
          ),
          if (widget.topics.isNotEmpty) const KnowledgeGraphLegend(),
        ],
      ),
    );
  }
}

// --- Helper class (Now Public) ---
class NodeInfo { // Renamed from _NodeInfo
  final Topic topic;
  final Offset center;
  final double radius;
  NodeInfo({required this.topic, required this.center, required this.radius});
}

// --- Custom Painter for the Knowledge Graph ---
class KnowledgeGraphPainter extends CustomPainter {
  final List<Topic> topics;
  // Use the now public NodeInfo type
  final List<NodeInfo> nodeInfos;

  static const double subjectRadius = 35.0;
  static const double topicRadius = 18.0;
  static const double orbitRadiusMultiplier = 1.0;
  static const double topicOrbitMultiplier = 1.6;

  // Constructor uses public NodeInfo type
  KnowledgeGraphPainter(this.topics, this.nodeInfos);

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'first_time': return Colors.red[400]!;
      case 'early_stage': return Colors.orange[400]!;
      case 'mid_stage': return Colors.yellow[700]!;
      case 'late_stage': return Colors.green[400]!;
      case 'mastered': return Colors.blue[400]!;
      default: return Colors.grey[600]!;
    }
  }

  void _drawText(Canvas canvas, TextPainter textPainter, String text, Offset center, Color color, double maxWidth) {
    String displayText = text;
    if (text.length > 10) {
      displayText = '${text.substring(0, 8)}...';
    }
    textPainter.text = TextSpan(
      text: displayText,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w500),
    );
    textPainter.layout(maxWidth: maxWidth);
    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, -textPainter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    nodeInfos.clear();

    final subjectPaint = Paint()..color = Colors.deepPurpleAccent..strokeWidth = 1.5..style = PaintingStyle.stroke;
    // Fixed deprecation (0.5 opacity)
    final linePaint = Paint()..color = Colors.deepPurpleAccent.withAlpha(128)..strokeWidth = 1..style = PaintingStyle.stroke;
    final subjectFillPaint = Paint()..color = Colors.black..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);

    final center = Offset(size.width / 2, size.height / 2);

    if (topics.isEmpty) return;

    final Map<String, List<Topic>> topicsBySubject = {};
    for (final topic in topics) {
      final subjectKey = topic.subject.isNotEmpty ? topic.subject : "Uncategorized";
      topicsBySubject.putIfAbsent(subjectKey, () => []).add(topic);
    }

    final subjects = topicsBySubject.keys.toList();
    final baseOrbitRadius = math.min(size.width, size.height) / 3.0 * orbitRadiusMultiplier;

    for (var i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      final angle = (i * 2 * math.pi / subjects.length);
      final sx = center.dx + baseOrbitRadius * math.cos(angle);
      final sy = center.dy + baseOrbitRadius * math.sin(angle);
      final subjectCenter = Offset(sx, sy);

      canvas.drawCircle(subjectCenter, subjectRadius, subjectFillPaint);
      canvas.drawCircle(subjectCenter, subjectRadius, subjectPaint);
      _drawText(canvas, textPainter, subject, subjectCenter, Colors.white, subjectRadius * 1.6);

      final placeholderSubjectTopic = Topic(id: 'subject_$subject', name: subject, subject: subject, stage: '', createdAt: DateTime.now(), nextReview: DateTime.now(), status: '');
      // Use public NodeInfo constructor
      nodeInfos.add(NodeInfo(topic: placeholderSubjectTopic, center: subjectCenter, radius: subjectRadius));

      final currentSubjectTopics = topicsBySubject[subject]!;
      if (currentSubjectTopics.isNotEmpty) {
        final topicOrbitRadius = subjectRadius + topicRadius + 20.0;
        final angleStep = (2 * math.pi) / math.max(1, currentSubjectTopics.length);

        for (var j = 0; j < currentSubjectTopics.length; j++) {
          final topic = currentSubjectTopics[j];
          final topicAngle = angle + (j * angleStep * 1.1);
          final tx = subjectCenter.dx + topicOrbitRadius * math.cos(topicAngle);
          final ty = subjectCenter.dy + topicOrbitRadius * math.sin(topicAngle);
          final topicCenter = Offset(tx, ty);

          canvas.drawLine(subjectCenter, topicCenter, linePaint);

          final topicFillPaint = Paint()..color = _getStageColor(topic.stage)..style = PaintingStyle.fill;
          canvas.drawCircle(topicCenter, topicRadius, topicFillPaint);
          canvas.drawCircle(topicCenter, topicRadius, subjectPaint);
          _drawText(canvas, textPainter, topic.name, topicCenter, Colors.white, topicRadius * 1.7);

          // Use public NodeInfo constructor
          nodeInfos.add(NodeInfo(topic: topic, center: topicCenter, radius: topicRadius));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant KnowledgeGraphPainter oldDelegate) {
    return oldDelegate.topics != topics;
  }
}

// --- DueForReviewCard ---
class DueForReviewCard extends StatelessWidget {
  final List<Topic> dueTopics;
  final Function(String topicId, String difficulty) onReview;

  const DueForReviewCard({super.key, required this.dueTopics, required this.onReview});

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
              Icon(Icons.access_time, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 8),
              const Text('Due for Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              const Spacer(),
              Text('(${dueTopics.length})', style: TextStyle(fontSize: 16, color: Colors.grey[400], fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          dueTopics.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No topics due for review! Well done!', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                )
              // Fixed: Replaced Column with ListView.builder
              : ListView.builder(
                  itemCount: dueTopics.length,
                  // Required parameters when nesting a scrollable
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final topic = dueTopics[index];
                    return _buildReviewItem(context, topic);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Topic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('${topic.subject.isNotEmpty ? topic.subject : "Uncategorized"} - ${topic.name}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Icon(Icons.menu_book, color: Colors.deepPurpleAccent),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TopicContentPage(topic: topic))),
                tooltip: 'View Learning Resources', iconSize: 20, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Stage: ', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  // Fixed deprecation (0.3 opacity)
                  color: _getStageColor(topic.stage).withAlpha(77),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  topic.stage.capitalize(),
                  style: TextStyle(color: _getStageColor(topic.stage), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDifficultyButton(context, 'Hard', Colors.red[400]!, () => onReview(topic.id, 'hard')),
              _buildDifficultyButton(context, 'Normal', Colors.amber[600]!, () => onReview(topic.id, 'normal')),
              _buildDifficultyButton(context, 'Easy', Colors.green[400]!, () => onReview(topic.id, 'easy')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String label, Color color, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            elevation: 1,
          ),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'first_time': return Colors.red[400]!;
      case 'early_stage': return Colors.orange[400]!;
      case 'mid_stage': return Colors.yellow[700]!;
      case 'late_stage': return Colors.green[400]!;
      case 'mastered': return Colors.blue[400]!;
      default: return Colors.grey[600]!;
    }
  }
}

// --- ChartGrid (Placeholder) ---
class ChartGrid extends StatelessWidget {
  final LearningService learningService;
  const ChartGrid({super.key, required this.learningService});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
      child: const Text('Chart Area Placeholder', style: TextStyle(color: Colors.white54)),
    );
  }
}

// --- String Extension ---
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    if (!contains(RegExp(r'[_\s]+'))) { // Check if it contains space or underscore
      return '${this[0].toUpperCase()}${substring(1)}';
    }
    return split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}