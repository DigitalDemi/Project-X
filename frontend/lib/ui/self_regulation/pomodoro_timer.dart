import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/focus_session_service.dart'; 

// I need to promodromo, and add the 5 mins breaks as, splits as well
// add mius the time from the focus timeer
// add mutiple reflection
// add notifcations about, what they have done today, and make it encouraging
// make a video, about the app 

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  // Timer State
  int _selectedDuration = 25; // Default duration in minutes
  bool _isRunning = false;
  bool _isPaused = false;
  int _remainingSeconds = 0;
  Timer? _timer;

  // Session Data State
  String? _currentSessionId; // ID of the currently active session
  final _topicController = TextEditingController();
  final List<String> _distractions = []; // UI list for *current* session's distractions
  final _distractionController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel(); // Clean up timer
    _topicController.dispose();
    _distractionController.dispose();
    super.dispose();
  }

  // --- Timer Actions ---

  void _startTimer() async {
    if (_isRunning) return; // Prevent multiple timers

    // Get service instance (don't listen here, just triggering action)
    final focusService = Provider.of<FocusSessionService>(context, listen: false);
    final topic = _topicController.text.trim();

    debugPrint("Attempting to start timer...");
    try {
      // Ask the service to start and save the session first
      _currentSessionId = await focusService.startSession(
        durationMinutes: _selectedDuration,
        topic: topic.isEmpty ? null : topic,
      );
      debugPrint("Service started session with ID: $_currentSessionId");

      // If successful, update UI state and start the countdown timer
      setState(() {
        _isRunning = true;
        _isPaused = false;
        _remainingSeconds = _selectedDuration * 60;
        _distractions.clear(); // Clear distractions from previous session UI
      });

      _timer?.cancel(); // Ensure no old timer is running
      _timer = Timer.periodic(const Duration(seconds: 1), _tick); // Start tick

    } catch (e, stackTrace) {
       debugPrint("!!!!!! Error starting timer session via service: $e\n$stackTrace");
       if (mounted) { // Show error to user if widget is still visible
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error starting session: ${e.toString()}')),
           );
       }
    }
  }

  // Called every second by the timer
  void _tick(Timer timer) {
     if (!_isRunning) { // Safety check: Stop if state changed
       timer.cancel();
       _timer = null;
       return;
     }

     if (_isPaused) return; // Don't count down if paused

     if (_remainingSeconds <= 0) { // Timer finished
       timer.cancel();
       _timer = null;
       _handleTimerCompletion(); // Trigger completion logic
       return;
     }

     // Check if widget is still mounted before updating state
     if (mounted) {
       setState(() {
         _remainingSeconds--;
       });
     } else {
       // Widget was removed unexpectedly, cancel timer
       timer.cancel();
       _timer = null;
     }
  }


  void _pauseTimer() {
    if (!_isRunning || _isPaused) return;
    debugPrint("Pausing timer.");
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    if (!_isRunning || !_isPaused) return;
     debugPrint("Resuming timer.");
    setState(() {
      _isPaused = false;
    });
  }

  // Action for the "Stop" button - Shows confirmation dialog
  void _stopTimer() {
    if (!_isRunning) return;
    debugPrint("Stop button pressed.");

    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Stop Session', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Discard this focus session? It won\'t count towards your stats.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Close dialog
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _completeSession(wasCompleted: false); // Call completion logic with cancelled flag
                },
                child: const Text('Yes, Stop', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
    );
  }

  // Action when timer naturally reaches zero
  void _handleTimerCompletion() {
    debugPrint("Timer finished naturally.");
    // Play sound/vibration etc. if desired

    // Show rating dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Require rating
      builder: (context) => RatingDialog(
            onRatingSubmitted: (rating) {
              // Call completion logic with completed flag and rating
              _completeSession(wasCompleted: true, focusRating: rating);
            },
          ),
    );
  }

  // --- Session Management ---

  // Central method to end the session (completed or stopped)
  void _completeSession({required bool wasCompleted, int focusRating = 0}) {
    debugPrint("UI completing session. wasCompleted: $wasCompleted, rating: $focusRating");
    if (_currentSessionId == null) {
      debugPrint("Error: _completeSession called but _currentSessionId is null.");
      _resetTimerState(); // Reset UI anyway
      return;
    }

    _timer?.cancel(); // Ensure timer is definitely stopped

    // Get service instance to save the data
    final focusService = Provider.of<FocusSessionService>(context, listen: false);

    // Create an immutable copy of distractions before passing
    final distractionsToSave = _distractions.isEmpty ? null : List<String>.unmodifiable(_distractions);

    // Call the service to update the session state in the database
    focusService.completeSession(
      id: _currentSessionId!,
      focusRating: focusRating,
      distractions: distractionsToSave,
      wasCompleted: wasCompleted, // Pass the correct flag
    ).catchError((e, stackTrace) {
       // Handle potential errors from the service/database layer
       debugPrint("!!!!!! Error during focusService.completeSession call: $e\n$stackTrace");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving session: ${e.toString()}')),
           );
       }
    }).whenComplete(() {
       // Always reset the UI state after attempting completion
       _resetTimerState();
    });
  }

  // Resets timer UI state variables
  void _resetTimerState() {
     debugPrint("Resetting timer UI state.");
     // Check if widget is still mounted before calling setState
     if (mounted) {
       setState(() {
         _isRunning = false;
         _isPaused = false;
         _remainingSeconds = 0;
         _currentSessionId = null;
         _distractions.clear();
         _timer?.cancel();
         _timer = null;
         // Optionally clear topic: _topicController.clear();
       });
     } else {
        // If not mounted, just ensure timer resource is released
       _timer?.cancel();
       _timer = null;
     }
  }

  // Adds a distraction to the current session's UI list
  void _addDistraction() {
    final text = _distractionController.text.trim(); // Trim input
    if (text.isEmpty) return; // Ignore empty input

    debugPrint("Adding distraction: $text");
    setState(() {
      // Optional: Prevent adding exact duplicates
      if (!_distractions.contains(text)) {
          _distractions.add(text);
      }
      _distractionController.clear(); // Clear the text field
    });
     FocusScope.of(context).unfocus(); // Hide keyboard after adding
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen for changes in FocusSessionService (e.g., when sessions load/update)
    return Consumer<FocusSessionService>(
      builder: (context, focusService, child) {
        // Get latest stats from the service within the builder
        final commonDistractions = focusService.getCommonDistractions();
        final totalFocusMinutes = focusService.getTotalFocusMinutesToday();

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => _handleBackButton(), // Use helper for back logic
            ),
            title: const Text('Focus Timer', style: TextStyle(color: Colors.white)),
          ),
          body: SingleChildScrollView( // Allow scrolling on smaller screens
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Top Section: Timer or Setup ---
                Container(
                  width: double.infinity, // Ensure container takes full width
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isRunning ? _buildRunningTimer() : _buildTimerSetup(),
                ),
                const SizedBox(height: 24),

                // --- Middle Section: Topic or Distractions ---
                // Show Topic input only when timer is NOT running
                if (!_isRunning) _buildTopicInput(),
                // Show Distraction tracker only when timer IS running
                if (_isRunning) _buildDistractionTracker(),
                const SizedBox(height: 24),

                // --- Bottom Section: Stats ---
                _buildStatsSection(commonDistractions, totalFocusMinutes),
              ],
            ),
          ),
        );
      },
    );
  }

  // Handles back button press, warns if timer is running
  void _handleBackButton() {
     if (_isRunning) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text("Discard Session?", style: TextStyle(color: Colors.white)),
            content: const Text("Navigating back will stop the current focus session. Are you sure?", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(true); // Confirm discard
                  // Explicitly stop the session when discarding via back button
                  _completeSession(wasCompleted: false);
                },
                child: const Text("Discard", style: TextStyle(color: Colors.redAccent))
              )
            ]
          )
        ).then((confirmed) {
           // Only pop the page if user confirmed discard
           if (confirmed == true && mounted) { // Check mounted again
              Navigator.pop(context);
           }
        });
     } else {
        // If timer not running, just pop the page
        Navigator.pop(context);
     }
  }


  // --- Helper Build Methods for UI Sections ---

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
        const SizedBox(height: 20),
        // Duration Buttons
         Wrap( // Use Wrap for better spacing if needed
            alignment: WrapAlignment.center,
            spacing: 12.0,
            runSpacing: 8.0,
            children: [15, 25, 45, 60].map((min) => _buildDurationButton(min)).toList(),
         ),
        const SizedBox(height: 30),
        // Start Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text('Start Focus Session'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationButton(int minutes) {
    final isSelected = _selectedDuration == minutes;
      return ChoiceChip(
         label: Text('$minutes min'),
         selected: isSelected,
         onSelected: (selected) {
            if (selected && !_isRunning) { // Only allow change if not running
               setState(() { _selectedDuration = minutes; });
            }
         },
         selectedColor: Colors.deepPurpleAccent,
         backgroundColor: Colors.grey[800],
         labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
         ),
         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
         side: BorderSide.none,
      );
  }

  Widget _buildTopicInput() {
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
            'What are you focusing on? (Optional)',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g., Project report, Study chapter 3...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistractionTracker() {
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
              'Distraction Tracker',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note distractions as they occur.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Input Field and Add Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
              children: [
                Expanded(
                  child: TextField(
                    controller: _distractionController,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _addDistraction(), // Add on keyboard submit
                    decoration: InputDecoration(
                      hintText: 'What distracted you?',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addDistraction, // Calls corrected method
                  icon: const Icon(Icons.add_circle),
                  color: Colors.deepPurpleAccent,
                  iconSize: 32,
                  tooltip: 'Add Distraction',
                  padding: EdgeInsets.zero, // Adjust padding if needed
                  constraints: const BoxConstraints(), // Remove default constraints if needed
                ),
              ],
            ),
            const SizedBox(height: 16),
            // List of Added Distractions (Chips)
            if (_distractions.isEmpty)
              const Padding(
                 padding: EdgeInsets.symmetric(vertical: 8.0),
                 child: Text('No distractions logged for this session yet.', style: TextStyle(color: Colors.white54)),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _distractions.map((distraction) {
                  return Chip(
                    label: Text(distraction, style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.deepPurpleAccent.withOpacity(0.4),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16), // Use rounded icon
                    deleteIconColor: Colors.white70,
                    onDeleted: () {
                      // Remove from the temporary UI list for this session
                      setState(() { _distractions.remove(distraction); });
                      debugPrint("Removed distraction from UI list: $distraction");
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap target size
                  );
                }).toList(),
              ),
          ],
        ),
      );
    }

  Widget _buildStatsSection(List<MapEntry<String, int>> commonDistractions, int totalFocusMinutes) {
     return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Focus Stats', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Today's Focus Time
            Row(
              children: [
                const Icon(Icons.access_time_filled, color: Colors.deepPurpleAccent, size: 20),
                const SizedBox(width: 12),
                const Text("Today's Focus Time", style: TextStyle(color: Colors.white70)),
                const Spacer(),
                Text('$totalFocusMinutes min', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(color: Colors.grey, height: 24),
            // Common Distractions
            const Text('Top Common Distractions (All Sessions):', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            if (commonDistractions.isEmpty)
               Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                   children: const [
                      Icon(Icons.info_outline, color: Colors.white54, size: 16),
                      SizedBox(width: 8),
                      Text('No distractions recorded yet.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                   ],
                )
              )
            else
              // Build the list of distraction entries
              ListView.separated( // Use ListView for potentially longer lists
                 shrinkWrap: true, // Important inside SingleChildScrollView
                 physics: const NeverScrollableScrollPhysics(), // Disable its own scrolling
                 itemCount: commonDistractions.length,
                 separatorBuilder: (_, __) => const SizedBox(height: 6), // Space between items
                 itemBuilder: (context, index) {
                    final entry = commonDistractions[index];
                    // Capitalize first letter for display
                    final displayKey = entry.key.isNotEmpty
                               ? entry.key[0].toUpperCase() + entry.key.substring(1)
                               : entry.key;
                    return Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayKey,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Count Bubble
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                 },
              ),
          ],
        ),
      );
  }

  Widget _buildRunningTimer() {
     final minutes = _remainingSeconds ~/ 60;
     final seconds = _remainingSeconds % 60;
     // Format time string as MM:SS
     final displayTime = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
     final currentTopic = _topicController.text.trim();

    return Column(
      children: [
        // Show topic if available
        if (currentTopic.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Focusing on: $currentTopic',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        // Timer Display
        Text(
          displayTime,
          style: const TextStyle(
            color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()], // Keep digits aligned
          ),
        ),
        const SizedBox(height: 16),
        // Progress Bar
        LinearProgressIndicator(
           // Calculate progress, avoid division by zero if duration is 0
           value: (_selectedDuration > 0) ? (_selectedDuration * 60 - _remainingSeconds) / (_selectedDuration * 60) : 0,
           backgroundColor: Colors.grey[700],
           valueColor: AlwaysStoppedAnimation<Color>(
               _isPaused ? Colors.orangeAccent : Colors.deepPurpleAccent // Change color if paused
           ),
           minHeight: 6,
        ),
         const SizedBox(height: 20),
        // Status Text
        Text(
          _isPaused ? 'Timer Paused' : 'Stay Focused!',
          style: TextStyle(
            color: _isPaused ? Colors.orangeAccent : Colors.greenAccent,
            fontSize: 16, fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        // Control Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimerControlButton(
              _isPaused ? 'Resume' : 'Pause',
              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              _isPaused ? _resumeTimer : _pauseTimer,
              _isPaused ? Colors.greenAccent : Colors.orangeAccent,
            ),
            _buildTimerControlButton('Stop', Icons.stop_rounded, _stopTimer, Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerControlButton(String label, IconData icon, VoidCallback onPressed, Color color) {
     return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
             backgroundColor: Colors.grey[800],
             foregroundColor: color,
             shape: const CircleBorder(),
             padding: const EdgeInsets.all(18),
             elevation: 4,
          ),
           child: Icon(icon, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
} // End of _PomodoroTimerPageState

// --- Rating Dialog Widget ---
class RatingDialog extends StatefulWidget {
  final Function(int) onRatingSubmitted;
  const RatingDialog({super.key, required this.onRatingSubmitted});
  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 3; // Default rating

  // Helper to get text description for rating
  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1: return 'Very Distracted';
      case 2: return 'Somewhat Distracted';
      case 3: return 'Moderately Focused';
      case 4: return 'Highly Focused';
      case 5: return 'In the Zone!';
      default: return '';
    }
 }

  @override
  Widget build(BuildContext context) {
     return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
         children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text('Session Complete!', style: TextStyle(color: Colors.white)),
         ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How focused were you during this session?',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 20),
          // Star Rating Input using IconButtons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final ratingValue = index + 1;
              final isSelected = ratingValue <= _rating;
              return IconButton(
                icon: Icon(
                   isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                   color: isSelected ? Colors.amber : Colors.grey[600],
                ),
                iconSize: 38, // Slightly larger stars
                padding: const EdgeInsets.symmetric(horizontal: 4), // Adjust spacing
                constraints: const BoxConstraints(), // Remove extra padding
                onPressed: () { setState(() { _rating = ratingValue; }); },
                tooltip: '$ratingValue star${ratingValue > 1 ? 's' : ''}',
              );
            }),
          ),
          const SizedBox(height: 12),
          // Display text description for the selected rating
           Center(
             child: Text(
               _getRatingDescription(_rating),
               style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w500),
               textAlign: TextAlign.center,
             ),
           )
        ],
      ),
      actions: [
         // Optional: Cancel button if needed
         // TextButton(
         //   onPressed: () => Navigator.pop(context),
         //   child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
         // ),
        // Submit Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
             backgroundColor: Colors.deepPurpleAccent,
             foregroundColor: Colors.white,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            widget.onRatingSubmitted(_rating); // Pass rating back
            Navigator.pop(context); // Close dialog
          },
          child: const Text('Submit Rating'),
        ),
      ],
    );
  }
}