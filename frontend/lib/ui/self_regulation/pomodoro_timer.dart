// lib/ui/self_regulation/pomodoro_timer.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/focus_session_service.dart';

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  int _selectedDuration = 25; // Default Pomodoro: 25 minutes
  bool _isRunning = false;
  bool _isPaused = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  String? _currentSessionId;
  final _topicController = TextEditingController();
  final List<String> _distractions = [];
  final _distractionController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _topicController.dispose();
    _distractionController.dispose();
    super.dispose();
  }

  void _startTimer() async {
    final focusService = Provider.of<FocusSessionService>(context, listen: false);
    
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _remainingSeconds = _selectedDuration * 60;
    });
    
    // Create new session in database
    _currentSessionId = await focusService.startSession(
      durationMinutes: _selectedDuration,
      topic: _topicController.text.isEmpty ? null : _topicController.text,
    );
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _completeTimer();
        return;
      }
      
      if (!_isPaused) {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Stop Session', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to stop this focus session?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeSession(wasCompleted: false);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _completeTimer() {
    _timer?.cancel();
    
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        onRatingSubmitted: (rating) {
          _completeSession(
            wasCompleted: true,
            focusRating: rating,
          );
        },
      ),
    );
  }

  void _completeSession({
    required bool wasCompleted,
    int focusRating = 0,
  }) {
    if (_currentSessionId == null) return;
    
    final focusService = Provider.of<FocusSessionService>(context, listen: false);
    
    focusService.completeSession(
      _currentSessionId!,
      focusRating: focusRating,
      distractions: _distractions.isEmpty ? null : _distractions,
    );
    
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = 0;
      _currentSessionId = null;
      _distractions.clear();
    });
  }

  void _addDistraction() {
    if (_distractionController.text.isEmpty) return;
    
    setState(() {
      _distractions.add(_distractionController.text);
      _distractionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Focus Timer'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer setup or display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isRunning
                  ? _buildRunningTimer()
                  : _buildTimerSetup(),
            ),
            
            const SizedBox(height: 24),
            
            // Topic field (before starting)
            if (!_isRunning)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // lib/ui/self_regulation/pomodoro_timer.dart (continued)
                    const Text(
                      'What are you focusing on?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _topicController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g., Project work, Reading, Learning...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Distraction tracker (when running)
            if (_isRunning)
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
                      'Distraction Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Note what distracts you during your focus session',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _distractionController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'What distracted you?',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addDistraction,
                          icon: const Icon(Icons.add_circle, color: Colors.deepPurpleAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Distraction chips
                    if (_distractions.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _distractions.map((distraction) {
                          return Chip(
                            label: Text(distraction),
                            backgroundColor: Colors.deepPurpleAccent.withOpacity(0.3),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _distractions.remove(distraction);
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              
            const SizedBox(height: 24),
            
            // Stats section
            Consumer<FocusSessionService>(
              builder: (context, focusService, child) {
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
                        'Focus Stats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatItem(
                        'Today\'s Focus Time',
                        '${focusService.getTotalFocusMinutesToday()} min',
                        Icons.access_time,
                      ),
                      const Divider(color: Colors.grey),
                      
                      // Common distractions
                      const Text(
                        'Common Distractions:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      _buildDistractionsList(focusService),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSetup() {
    return Column(
      children: [
        const Text(
          'Select Focus Duration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Duration selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDurationButton(15),
            _buildDurationButton(25),
            _buildDurationButton(45),
            _buildDurationButton(60),
          ],
        ),
        const SizedBox(height: 24),
        
        // Start button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _startTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Focus Session',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationButton(int minutes) {
    final isSelected = _selectedDuration == minutes;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDuration = minutes;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurpleAccent : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRunningTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    return Column(
      children: [
        // Topic display
        if (_topicController.text.isNotEmpty)
          Text(
            'Focusing on: ${_topicController.text}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        
        const SizedBox(height: 24),
        
        // Timer display
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 60,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        // Status message
        Text(
          _isPaused ? 'Timer Paused' : 'Stay Focused!',
          style: TextStyle(
            color: _isPaused ? Colors.yellow : Colors.green,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        
        // Timer controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimerButton(
              _isPaused ? 'Resume' : 'Pause',
              _isPaused ? Icons.play_arrow : Icons.pause,
              _isPaused ? _resumeTimer : _pauseTimer,
              Colors.amber,
            ),
            _buildTimerButton(
              'Stop',
              Icons.stop,
              _stopTimer,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 36),
          padding: const EdgeInsets.all(16),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDistractionsList(FocusSessionService service) {
    final distractions = service.getCommonDistractions();
    
    if (distractions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No distractions recorded yet',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: distractions.length,
      itemBuilder: (context, index) {
        final distraction = distractions[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.remove_circle_outline, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  distraction.key,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  distraction.value.toString(),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RatingDialog extends StatefulWidget {
  final Function(int) onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.onRatingSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Session Complete!',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How would you rate your focus during this session?',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return InkWell(
                onTap: () {
                  setState(() {
                    _rating = rating;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Icon(
                        rating <= _rating ? Icons.star : Icons.star_border,
                        color: rating <= _rating ? Colors.amber : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          color: rating <= _rating ? Colors.white : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onRatingSubmitted(_rating);
            Navigator.pop(context);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
                    