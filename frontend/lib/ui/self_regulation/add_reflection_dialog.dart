import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/reflection_service.dart';

class AddReflectionDialog extends StatefulWidget {
  const AddReflectionDialog({super.key});

  @override
  State<AddReflectionDialog> createState() => _AddReflectionDialogState();
}

class _AddReflectionDialogState extends State<AddReflectionDialog> {
  final _contentController = TextEditingController();
  int? _moodRating;
  int? _productivityRating;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _saveReflection() {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some reflection text')),
      );
      return;
    }

    final reflectionService = Provider.of<ReflectionService>(context, listen: false);
    
    reflectionService.addReflection(
      content: _contentController.text,
      tags: _tags,
      moodRating: _moodRating,
      productivityRating: _productivityRating,
    );
    
    Navigator.pop(context);
  }

  void _addTag() {
    if (_tagController.text.isEmpty) return;
    
    // Normalize tag (remove spaces, lowercase)
    final tag = _tagController.text.trim().toLowerCase().replaceAll(' ', '_');
    
    if (!_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
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
              'Daily Reflection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Mood rating
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMoodOption(1, Icons.sentiment_very_dissatisfied, Colors.red),
                _buildMoodOption(2, Icons.sentiment_dissatisfied, Colors.orange),
                _buildMoodOption(3, Icons.sentiment_neutral, Colors.yellow),
                _buildMoodOption(4, Icons.sentiment_satisfied, Colors.lightGreen),
                _buildMoodOption(5, Icons.sentiment_very_satisfied, Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            
            // Productivity rating
            const Text(
              'How productive were you today?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return _buildProductivityOption(rating);
              }),
            ),
            const SizedBox(height: 24),
            
            // Reflection text
            const Text(
              'Your thoughts on today:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What went well? What could be improved?',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            
            // Tags
            const Text(
              'Tags (optional):',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add tags (e.g., work, exercise)',
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
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_circle, color: Colors.deepPurpleAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Tag chips
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
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
                  onPressed: _saveReflection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                  child: const Text('Save Reflection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodOption(int rating, IconData icon, Color color) {
    final isSelected = _moodRating == rating;
    
    return InkWell(
      onTap: () {
        setState(() {
          _moodRating = rating;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? color : Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }

  Widget _buildProductivityOption(int rating) {
    final isSelected = _productivityRating == rating;
    
    return InkWell(
      onTap: () {
        setState(() {
          _productivityRating = rating;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurpleAccent.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: Colors.deepPurpleAccent, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              rating <= (_productivityRating ?? 0) ? Icons.star : Icons.star_border,
              color: isSelected ? Colors.deepPurpleAccent : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              rating.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}