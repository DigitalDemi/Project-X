// lib/ui/self_regulation/add_mood_entry_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mood_service.dart';

class AddMoodEntryDialog extends StatefulWidget {
  const AddMoodEntryDialog({super.key});

  @override
  State<AddMoodEntryDialog> createState() => _AddMoodEntryDialogState();
}

class _AddMoodEntryDialogState extends State<AddMoodEntryDialog> {
  int _selectedRating = 3;
  final _noteController = TextEditingController();
  final List<String> _selectedFactors = [];

  final List<String> _commonFactors = [
    'sleep',
    'work',
    'exercise',
    'food',
    'social',
    'stress',
    'weather',
    'health',
    'entertainment',
    'productivity',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveMoodEntry() {
    final moodService = Provider.of<MoodService>(context, listen: false);
    
    moodService.addEntry(
      rating: _selectedRating,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      factors: _selectedFactors,
    );
    
    Navigator.pop(context);
  }

  void _toggleFactor(String factor) {
    setState(() {
      if (_selectedFactors.contains(factor)) {
        _selectedFactors.remove(factor);
      } else {
        _selectedFactors.add(factor);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How are you feeling?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Mood selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMoodOption(1, Icons.sentiment_very_dissatisfied, Colors.red, 'Very Bad'),
                _buildMoodOption(2, Icons.sentiment_dissatisfied, Colors.orange, 'Bad'),
                _buildMoodOption(3, Icons.sentiment_neutral, Colors.yellow, 'Neutral'),
                _buildMoodOption(4, Icons.sentiment_satisfied, Colors.lightGreen, 'Good'),
                _buildMoodOption(5, Icons.sentiment_very_satisfied, Colors.green, 'Very\nGood'),
              ],
            ),
            const SizedBox(height: 24),
            
            // Note field
            const Text(
              'Notes (optional):',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What\'s affecting your mood?',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Factors selection
            const Text(
              'What factors are affecting your mood?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonFactors.map((factor) {
                final isSelected = _selectedFactors.contains(factor);
                
                return ChoiceChip(
                  label: Text(factor),
                  selected: isSelected,
                  selectedColor: Colors.deepPurpleAccent.withOpacity(0.7),
                  backgroundColor: Colors.grey[800],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  onSelected: (_) => _toggleFactor(factor),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveMoodEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodOption(
    int rating,
    IconData icon,
    Color color,
    String label,
  ) {
    final isSelected = _selectedRating == rating;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRating = rating;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}