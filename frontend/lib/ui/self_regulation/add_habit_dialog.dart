// lib/ui/self_regulation/add_habit_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/habit_service.dart';

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _frequency = 'daily';
  final List<int> _selectedWeekdays = [1, 2, 3, 4, 5]; // Monday to Friday by default
  String _timeOfDay = 'anytime';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveHabit() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit title')),
      );
      return;
    }

    final habitService = Provider.of<HabitService>(context, listen: false);
    
    habitService.createHabit(
      title: _titleController.text,
      description: _descriptionController.text.isEmpty 
          ? null 
          : _descriptionController.text,
      frequency: _frequency,
      weekdays: _frequency == 'weekly' ? _selectedWeekdays : null,
      timeOfDay: _timeOfDay,
    );
    
    Navigator.pop(context);
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
              'Add New Habit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title field
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Habit Title',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description field
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            // Frequency selector
            const Text(
              'Frequency',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFrequencyOption('Daily', 'daily'),
                const SizedBox(width: 12),
                _buildFrequencyOption('Weekly', 'weekly'),
              ],
            ),
            const SizedBox(height: 24),
            
            // Weekday selector (for weekly habits)
            if (_frequency == 'weekly') ...[
              const Text(
                'Days of Week',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildWeekdaySelector(),
              const SizedBox(height: 24),
            ],
            
            // Time of day selector
            const Text(
              'Time of Day',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTimeOption('Morning', 'morning', Icons.wb_sunny),
                _buildTimeOption('Afternoon', 'afternoon', Icons.wb_cloudy),
                _buildTimeOption('Evening', 'evening', Icons.nights_stay),
                _buildTimeOption('Anytime', 'anytime', Icons.access_time),
              ],
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
                  onPressed: _saveHabit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                  child: const Text('Add Habit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(String label, String value) {
    final isSelected = _frequency == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _frequency = value;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurpleAccent : Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final weekday = index + 1; // 1-7 (Monday-Sunday)
        final isSelected = _selectedWeekdays.contains(weekday);
        
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                if (_selectedWeekdays.length > 1) {
                  _selectedWeekdays.remove(weekday);
                }
              } else {
                _selectedWeekdays.add(weekday);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.deepPurpleAccent : Colors.grey[800],
            ),
            child: Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeOption(
    String label,
    String value,
    IconData icon,
  ) {
    final isSelected = _timeOfDay == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _timeOfDay = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.3) : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.grey[700]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurpleAccent : Colors.grey[400],
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}