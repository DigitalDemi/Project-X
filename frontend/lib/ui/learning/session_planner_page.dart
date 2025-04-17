// lib/ui/learning/session_planner_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:frontend/services/learning_service.dart';
import 'package:frontend/services/topic_service.dart';
import 'package:frontend/models/topic.dart';
import 'package:frontend/services/calender_service.dart';
import 'package:frontend/models/calendar_event.dart';
import 'package:frontend/services/energy_service.dart';
import 'dart:math';

class SessionPlannerPage extends StatefulWidget {
  const SessionPlannerPage({super.key});

  @override
  State<SessionPlannerPage> createState() => _SessionPlannerPageState();
}

class _SessionPlannerPageState extends State<SessionPlannerPage> {
  DateTime _selectedDate = DateTime.now();
  int _sessionDuration = 45; // Default duration in minutes
  String _selectedEnergyLevel = 'any'; // 'high', 'low', 'any'
  List<Topic> _selectedTopics = [];
  bool _isGenerating = false;
  List<SessionPlan>? _generatedPlans;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Learning Session Planner'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlannerCard(),
            const SizedBox(height: 24),

            // Generated plans or topic selection based on state
            if (_isGenerating)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.deepPurpleAccent,
                  ),
                ),
              )
            else if (_generatedPlans != null)
              _buildGeneratedPlans()
            else
              _buildTopicSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannerCard() {
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
            'Plan Your Learning Session',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Date picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today, color: Colors.deepPurpleAccent),
            title: const Text(
              'Session Date',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: _selectDate,
            ),
          ),

          // Duration selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.timer, color: Colors.deepPurpleAccent),
            title: const Text(
              'Session Duration',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '$_sessionDuration minutes',
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: DropdownButton<int>(
              value: _sessionDuration,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              underline: Container(height: 0),
              onChanged: (value) {
                setState(() {
                  _sessionDuration = value!;
                });
              },
              items:
                  [30, 45, 60, 90, 120].map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value min'),
                    );
                  }).toList(),
            ),
          ),

          // Energy level selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.bolt, color: Colors.deepPurpleAccent),
            title: const Text(
              'Energy Level',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _getEnergyLevelText(),
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: DropdownButton<String>(
              value: _selectedEnergyLevel,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              underline: Container(height: 0),
              onChanged: (value) {
                setState(() {
                  _selectedEnergyLevel = value!;
                });
              },
              items: const [
                DropdownMenuItem(value: 'high', child: Text('High Energy')),
                DropdownMenuItem(value: 'low', child: Text('Low Energy')),
                DropdownMenuItem(value: 'any', child: Text('Any')),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Generate plan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _selectedTopics.isEmpty && _generatedPlans == null
                      ? null
                      : _generateSessionPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                disabledBackgroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _generatedPlans != null
                    ? 'Regenerate Plan'
                    : 'Generate Session Plan',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicSelection() {
    return Consumer<TopicService>(
      builder: (context, topicService, child) {
        var topics = topicService.topics;
        print("TopicService topics: ${topics.length}");

        // Try also accessing LearningService
        final learningService = Provider.of<LearningService>(
          context,
          listen: false,
        );
        final learningTopics = learningService.topics;
        print("LearningService topics: ${learningTopics.length}");

        // If TopicService is empty but LearningService has data,
        // use the LearningService data instead
        final topicsToUse = topics.isEmpty ? learningTopics : topics;

        topics = learningTopics;
        
        if (topics.isEmpty) {
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
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Topics for Your Session',
                  style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedTopics.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTopics = [];
                      });
                    },
                    child: const Text('Clear Selection'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Group topics by subject
            ...groupTopicsBySubject(topics).entries.map(
              (entry) => _buildSubjectTopicGroup(entry.key, entry.value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectTopicGroup(String subject, List<Topic> topics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            subject,
            style: const TextStyle(
              color: Colors.deepPurpleAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              topics.map((topic) {
                final isSelected = _selectedTopics.contains(topic);

                return FilterChip(
                  label: Text(topic.name),
                  selected: isSelected,
                  checkmarkColor: Colors.white,
                  selectedColor: Colors.deepPurpleAccent,
                  backgroundColor: Colors.grey[800],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTopics.add(topic);
                      } else {
                        _selectedTopics.remove(topic);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        const Divider(color: Colors.grey),
      ],
    );
  }

  Widget _buildGeneratedPlans() {
    if (_generatedPlans == null || _generatedPlans!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Could not generate session plans',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting different topics or parameters',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _generatedPlans = null;
                });
              },
              child: const Text('Back to Topic Selection'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Suggested Session Plans',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _generatedPlans = null;
                });
              },
              child: const Text('Back to Topics'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Display each plan
        ...List.generate(_generatedPlans!.length, (index) {
          return _buildPlanCard(index + 1, _generatedPlans![index]);
        }),
      ],
    );
  }

  Widget _buildPlanCard(int planNumber, SessionPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plan $planNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                onPressed: () => _scheduleSession(plan),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Session overview
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[400], size: 16),
              const SizedBox(width: 8),
              Text(
                'Total: $_sessionDuration minutes',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.book, color: Colors.grey[400], size: 16),
              const SizedBox(width: 8),
              Text(
                '${plan.topics.length} topics',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Topic timeline
          ...List.generate(plan.topics.length, (index) {
            final topic = plan.topics[index];
            final duration = plan.durations[index];

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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _getStageColor(topic.stage).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: _getStageColor(topic.stage),
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
                          topic.subject,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$duration min',
                      style: const TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurpleAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF303030),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getEnergyLevelText() {
    switch (_selectedEnergyLevel) {
      case 'high':
        return 'High Energy Topics';
      case 'low':
        return 'Low Energy Topics';
      default:
        return 'Any Energy Level';
    }
  }

  Map<String, List<Topic>> groupTopicsBySubject(List<Topic> topics) {
    final Map<String, List<Topic>> grouped = {};

    for (final topic in topics) {
      if (topic.status == 'active') {
        if (!grouped.containsKey(topic.subject)) {
          grouped[topic.subject] = [];
        }
        grouped[topic.subject]!.add(topic);
      }
    }

    return grouped;
  }

  void _generateSessionPlan() async {
    setState(() {
      _isGenerating = true;
      _generatedPlans = null;
    });

    // // Simulate API call or complex calculation
    // await Future.delayed(const Duration(seconds: 1));

    List<Topic> topicsToUse =
        _selectedTopics.isEmpty
            ? Provider.of<TopicService>(
              context,
              listen: false,
            ).topics.where((t) => t.status == 'active').toList()
            : _selectedTopics;

    // Filter by energy level if specified
    if (_selectedEnergyLevel != 'any') {
      final isHighEnergy = _selectedEnergyLevel == 'high';
      topicsToUse =
          topicsToUse.where((topic) {
            final isAdvanced = ['late_stage', 'mastered'].contains(topic.stage);
            return isHighEnergy ? isAdvanced : !isAdvanced;
          }).toList();
    }

    if (topicsToUse.isEmpty) {
      setState(() {
        _isGenerating = false;
        _generatedPlans = [];
      });
      return;
    }

    // Create multiple plan options
    final plans = <SessionPlan>[];

    // Plan 1: Focus on due topics
    final dueTopics =
        Provider.of<LearningService>(context, listen: false)
            .getDueTopics()
            .where((t) => topicsToUse.any((selected) => selected.id == t.id))
            .toList();

    if (dueTopics.isNotEmpty) {
      final plan = _createPlanFromTopics(dueTopics, 'Due Topics');
      if (plan != null) plans.add(plan);
    }

    // Plan 2: Mix of difficulty levels
    final mixedTopics = _createMixedDifficultyTopics(topicsToUse);
    if (mixedTopics.isNotEmpty) {
      final plan = _createPlanFromTopics(mixedTopics, 'Mixed Difficulty');
      if (plan != null) plans.add(plan);
    }

    // Plan 3: Focus on a specific subject
    final subjectFocusTopics = _createSubjectFocusTopics(topicsToUse);
    if (subjectFocusTopics.isNotEmpty) {
      final plan = _createPlanFromTopics(subjectFocusTopics, 'Subject Focus');
      if (plan != null) plans.add(plan);
    }

    setState(() {
      _isGenerating = false;
      _generatedPlans = plans;
    });
  }

  List<Topic> _createMixedDifficultyTopics(List<Topic> availableTopics) {
    if (availableTopics.length < 2) return availableTopics;

    // Group topics by difficulty
    final easyTopics =
        availableTopics
            .where((t) => ['first_time', 'early_stage'].contains(t.stage))
            .toList();
    final hardTopics =
        availableTopics
            .where(
              (t) => ['mid_stage', 'late_stage', 'mastered'].contains(t.stage),
            )
            .toList();

    if (easyTopics.isEmpty || hardTopics.isEmpty) return availableTopics;

    // Create a mix, alternating between easy and hard
    final mixedTopics = <Topic>[];
    final maxItems = min(easyTopics.length + hardTopics.length, 5);

    easyTopics.shuffle();
    hardTopics.shuffle();

    int easyIndex = 0;
    int hardIndex = 0;

    for (int i = 0; i < maxItems; i++) {
      if (i % 2 == 0) {
        if (easyIndex < easyTopics.length) {
          mixedTopics.add(easyTopics[easyIndex++]);
        } else if (hardIndex < hardTopics.length) {
          mixedTopics.add(hardTopics[hardIndex++]);
        }
      } else {
        if (hardIndex < hardTopics.length) {
          mixedTopics.add(hardTopics[hardIndex++]);
        } else if (easyIndex < easyTopics.length) {
          mixedTopics.add(easyTopics[easyIndex++]);
        }
      }
    }

    return mixedTopics;
  }

  List<Topic> _createSubjectFocusTopics(List<Topic> availableTopics) {
    if (availableTopics.isEmpty) return [];

    // Group by subject
    final Map<String, List<Topic>> bySubject = {};
    for (final topic in availableTopics) {
      if (!bySubject.containsKey(topic.subject)) {
        bySubject[topic.subject] = [];
      }
      bySubject[topic.subject]!.add(topic);
    }

    // Find subject with most topics
    String selectedSubject = '';
    int maxCount = 0;

    for (final entry in bySubject.entries) {
      if (entry.value.length > maxCount) {
        maxCount = entry.value.length;
        selectedSubject = entry.key;
      }
    }

    if (selectedSubject.isEmpty) return [];

    // Get up to 5 topics from the selected subject
    final subjectTopics = bySubject[selectedSubject]!;
    subjectTopics.shuffle();
    return subjectTopics.take(min(5, subjectTopics.length)).toList();
  }

  SessionPlan? _createPlanFromTopics(List<Topic> topics, String planType) {
    if (topics.isEmpty) return null;

    // Take at most 5 topics
    final selectedTopics = topics.take(min(5, topics.length)).toList();

    // Calculate durations based on session duration and topic count
    final List<int> durations = _calculateDurations(selectedTopics);

    return SessionPlan(
      topics: selectedTopics,
      durations: durations,
      type: planType,
    );
  }

  List<int> _calculateDurations(List<Topic> topics) {
    // Distribute session duration among topics, giving more time to harder topics
    final totalTopics = topics.length;
    if (totalTopics == 0) return [];

    // Assign weights based on topic difficulty
    final weights = <double>[];
    for (final topic in topics) {
      switch (topic.stage) {
        case 'first_time':
          weights.add(1.0);
          break;
        case 'early_stage':
          weights.add(1.2);
          break;
        case 'mid_stage':
          weights.add(1.5);
          break;
        case 'late_stage':
          weights.add(1.8);
          break;
        case 'mastered':
          weights.add(1.3); // Less time needed for mastered topics
          break;
        default:
          weights.add(1.0);
      }
    }

    // Calculate total weight
    final totalWeight = weights.fold(0.0, (sum, weight) => sum + weight);

    // Distribute minutes according to weights
    final durations = <int>[];
    int remainingMinutes = _sessionDuration;

    for (int i = 0; i < totalTopics - 1; i++) {
      final minutes = ((_sessionDuration * weights[i]) / totalWeight).round();
      durations.add(minutes);
      remainingMinutes -= minutes;
    }

    // Assign remaining minutes to the last topic
    durations.add(max(1, remainingMinutes));

    return durations;
  }

  Future<void> _scheduleSession(SessionPlan plan) async {
    final calendarService = Provider.of<CalendarService>(
      context,
      listen: false,
    );

    // Create event title from topics
    final topicNames = plan.topics.take(3).map((t) => t.name).join(', ');
    final title =
        plan.topics.length > 3
            ? 'Study Session: $topicNames and more'
            : 'Study Session: $topicNames';

    // Create description with topic IDs for backend reference
    final description = StringBuffer();
    description.writeln('Learning session with these topics:');

    final topicIds = <String>[];

    for (int i = 0; i < plan.topics.length; i++) {
      final topic = plan.topics[i];
      final duration = plan.durations[i];
      description.writeln('• ${topic.subject}: ${topic.name} ($duration min)');
      topicIds.add(topic.id);
    }

    // Determine end time
    final endTime = _selectedDate.add(Duration(minutes: _sessionDuration));

    // Create calendar event
    final eventData = {
      'title': title,
      'start_time': _selectedDate.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'description': description.toString(),
      'category': 'study',
      'related_topic_ids': topicIds, // Add this to link to backend topics
    };

    try {
      await calendarService.createEvent(eventData);

      // Also record this study session in the backend
      await http.post(
        Uri.parse(
          '${Provider.of<LearningService>(context, listen: false).baseUrl}/study-sessions/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'start_time': _selectedDate.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'topics': topicIds,
          'durations': plan.durations,
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study session scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
}

class SessionPlan {
  final List<Topic> topics;
  final List<int> durations;
  final String type;

  SessionPlan({
    required this.topics,
    required this.durations,
    required this.type,
  });
}
