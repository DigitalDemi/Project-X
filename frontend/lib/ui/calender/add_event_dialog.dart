import 'package:flutter/material.dart';
import 'package:frontend/services/calender_service.dart';
import 'package:provider/provider.dart';
import '../../models/calendar_event.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final CalendarEvent? eventToEdit;

  const AddEventDialog({
    super.key,
    required this.selectedDate,
    this.eventToEdit,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      _titleController.text = widget.eventToEdit!.title;
      _descriptionController.text = widget.eventToEdit!.description ?? '';
      _startTime = TimeOfDay.fromDateTime(widget.eventToEdit!.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.eventToEdit!.endTime);
    } else {
      _endTime = TimeOfDay(
        hour: _startTime.hour + 1,
        minute: _startTime.minute,
      );
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Automatically adjust end time if needed
          if (_endTime.hour < picked.hour || 
              (_endTime.hour == picked.hour && _endTime.minute <= picked.minute)) {
            _endTime = TimeOfDay(
              hour: picked.hour + 1,
              minute: picked.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.isEmpty) return;

    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final eventData = {
      'title': _titleController.text,
      'start_time': startDateTime.toIso8601String(),
      'end_time': endDateTime.toIso8601String(),
      'description': _descriptionController.text,
    };

    try {
      final service = Provider.of<CalendarService>(context, listen: false);
      await service.createEvent(eventData);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.eventToEdit != null ? 'Edit Event' : 'Add New Event',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _titleController,
              label: 'Event Title',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Start',
                    time: _startTime,
                    onTap: () => _selectTime(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    label: 'End',
                    time: _endTime,
                    onTap: () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
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
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                  child: Text(
                    widget.eventToEdit != null ? 'Update' : 'Save',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines ?? 1,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.deepPurpleAccent),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[700]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}