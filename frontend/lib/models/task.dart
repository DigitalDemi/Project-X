// lib/ui/tasks/task_card.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';

// --- Task Model (Unchanged) ---
class Task { /* ... Same ... */
  final String id; final String title; final String duration; final String energyLevel; final String? imagePath; final bool isCompleted;
  Task({ required this.id, required this.title, required this.duration, required this.energyLevel, this.imagePath, this.isCompleted = false });
  Map<String, dynamic> toJson() => { 'id': id, 'title': title, 'duration': duration, 'energyLevel': energyLevel, 'imagePath': imagePath, 'isCompleted': isCompleted };
  factory Task.fromJson(Map<String, dynamic> json) => Task( id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(), title: json['title'] as String? ?? 'Untitled Task', duration: json['duration'] as String? ?? 'N/A', energyLevel: json['energyLevel'] as String? ?? 'MEDIUM', imagePath: json['imagePath'] as String?, isCompleted: json['isCompleted'] as bool? ?? false );
  Task copyWith({ String? id, String? title, String? duration, String? energyLevel, String? imagePath, bool? isCompleted }) { return Task( id: id ?? this.id, title: title ?? this.title, duration: duration ?? this.duration, energyLevel: energyLevel ?? this.energyLevel, imagePath: imagePath ?? this.imagePath, isCompleted: isCompleted ?? this.isCompleted ); }
}


// --- Task Card Widget (Unchanged) ---
class TaskCard extends StatefulWidget { /* ... Same ... */
  final Task task; final Function(String)? onImageChanged; final Function(String taskId, bool isCompleted)? onCompletionChanged; final Function(String taskId)? onTaskDisappear; final VoidCallback? onShowOptions;
  const TaskCard({ super.key, required this.task, this.onImageChanged, this.onCompletionChanged, this.onTaskDisappear, this.onShowOptions });
  @override State<TaskCard> createState() => _TaskCardState();
}

// --- Task Card State (Interaction and Lifecycle Adjusted) ---
class _TaskCardState extends State<TaskCard> {
  final ImagePicker _picker = ImagePicker();
  bool _isHolding = false; // For visual overlay ONLY
  bool _isPendingRemoval = false; // Starts when isCompleted becomes true externally
  Timer? _disappearTimer;
  static const Duration _disappearDuration = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    // Check initial state - if loaded as completed, immediately start pending removal
    // This handles cases where the app restarts while a task was pending.
    // Note: This assumes tasks marked complete *should* disappear after a while.
    // If completed tasks should persist indefinitely until manually deleted, remove this check.
    if (widget.task.isCompleted) {
       _startPendingRemovalVisualsIfNeeded();
    }
  }


  @override
  void dispose() {
    _disappearTimer?.cancel();
    super.dispose();
  }

  // --- Lifecycle Method to Detect External Completion ---
  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If task becomes completed externally (via menu), start the pending/timer process
    if (!oldWidget.task.isCompleted && widget.task.isCompleted && !_isPendingRemoval) {
      debugPrint("Task ${widget.task.id} detected as completed externally. Starting pending removal.");
      _startPendingRemovalVisualsIfNeeded();
    }
    // If task becomes *in*complete externally (via menu) while pending, cancel timer
    else if (oldWidget.task.isCompleted && !widget.task.isCompleted && _isPendingRemoval) {
        debugPrint("Task ${widget.task.id} marked incomplete externally while pending. Cancelling timer.");
        _cancelPendingRemovalVisuals();
    }
  }

  // --- Interaction Logic ---

  // Start showing the hold overlay visual
  void _startHoldVisual() {
    if (_isPendingRemoval) return; // Don't show hold overlay if pending removal
    if (mounted) {
      setState(() { _isHolding = true; });
    }
  }

  // Stop showing the hold overlay visual
  void _endHoldVisual() {
    if (mounted) {
      setState(() { _isHolding = false; });
    }
  }

  // Starts the visual pending state and the timer (called by didUpdateWidget)
  void _startPendingRemovalVisualsIfNeeded() {
     // Ensure we don't start multiple timers if already pending
     if (!_isPendingRemoval && mounted) {
        setState(() {
          _isPendingRemoval = true;
        });
        _disappearTimer?.cancel(); // Cancel any previous timer just in case
        _disappearTimer = Timer(_disappearDuration, _onTimerEnd);
        debugPrint("Pending state started & Timer started for task ${widget.task.id}");
     }
  }


  // Cancels the pending state and timer (called by Undo or external incompletion)
   void _cancelPendingRemovalVisuals() {
      _disappearTimer?.cancel();
      debugPrint("Pending removal cancelled for task ${widget.task.id}");
      if (mounted) {
         setState(() {
           _isPendingRemoval = false;
         });
      }
   }


  // Called when the 'Undo' button is pressed
  void _undoCompletion() {
    if (!mounted) return;
     _cancelPendingRemovalVisuals(); // Cancel timer and visuals
    // Notify parent that the task is now logically incomplete
    widget.onCompletionChanged?.call(widget.task.id, false);
  }

  // Called by the Timer when the duration elapses
  void _onTimerEnd() {
    if (!mounted) return;
    // Check if still pending - user might have undone it right before timer fired
    if (_isPendingRemoval) {
        debugPrint("Timer ended for task ${widget.task.id}. Requesting disappearance.");
        widget.onTaskDisappear?.call(widget.task.id);
    } else {
        debugPrint("Timer ended for task ${widget.task.id}, but it was already undone.");
    }
    // The parent will remove this widget, so no setState needed here.
  }

  // --- Other Helpers (Unchanged) ---
  Future<void> _pickImage() async { if (_isHolding || _isPendingRemoval) return; try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (!mounted) return; if (image != null && widget.onImageChanged != null) { widget.onImageChanged!(image.path); } } catch (e) { debugPrint('Error picking image: $e'); if (mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Could not pick image.')),); } } }
  bool _imageFileExists() { if (widget.task.imagePath == null) return false; try { return File(widget.task.imagePath!).existsSync(); } catch (e) { debugPrint("Error checking image file existence: $e"); return false; } }


  // --- Build Method (Layout Adjusted) ---
  @override
  Widget build(BuildContext context) {
    // Visual state depends on actual completion AND pending removal state
    final bool isVisuallyComplete = widget.task.isCompleted || _isPendingRemoval;
    final Color cardColor = _isPendingRemoval ? Colors.grey[800]! : (widget.task.isCompleted ? Colors.grey[700]! : Colors.white);
    final Color textColor = _isPendingRemoval ? Colors.grey[500]! : (widget.task.isCompleted ? Colors.white70 : Colors.black);
    final Color subtitleColor = _isPendingRemoval ? Colors.grey[600]! : (widget.task.isCompleted ? Colors.white54 : Colors.grey[600]!);
    final TextDecoration titleDecoration = isVisuallyComplete ? TextDecoration.lineThrough : TextDecoration.none;
    final bool imageExists = _imageFileExists();

    // **** GestureDetector Updated ****
    return GestureDetector(
      // Long press now triggers the options menu via the callback
      onLongPress: widget.onShowOptions,
      // These handle the visual overlay *only*
      onLongPressStart: (_) => _startHoldVisual(),
      onLongPressEnd: (_) => _endHoldVisual(),
      onLongPressCancel: _endHoldVisual, // Also hide overlay if cancelled
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isVisuallyComplete ? [] : [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2),) ]
        ),
        child: Stack(
          clipBehavior: Clip.none, // Allow potential overflow if needed
          children: [
            // --- Main Card Content ---
            Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                // **** REMOVED the explicit 'more' button ****
                 Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [ GestureDetector( onTap: _pickImage, child: Opacity( opacity: _isPendingRemoval ? 0.5 : 1.0, child: Container( width: 40, height: 40, decoration: BoxDecoration( color: isVisuallyComplete ? Colors.grey[600] : Colors.grey[300], shape: BoxShape.circle, image: imageExists ? DecorationImage(image: FileImage(File(widget.task.imagePath!)), fit: BoxFit.cover) : null,), child: !imageExists ? Icon(Icons.add_photo_alternate_outlined, color: isVisuallyComplete ? Colors.white38 : Colors.grey[600], size: 20) : null, ),),),
                 // Keep space for alignment, but no button here now
                 const SizedBox(height: 24, width: 24),
                 ], ),
                 const Spacer(),
                 Opacity( opacity: _isPendingRemoval ? 0.6 : 1.0, child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(widget.task.title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2, decoration: titleDecoration, decorationColor: Colors.redAccent, decorationThickness: 2.0), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 6), Text(widget.task.duration, style: TextStyle(color: subtitleColor, fontSize: 11)), const SizedBox(height: 4), Text( widget.task.energyLevel.toUpperCase(), style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500)), const SizedBox(height: 4), ],),),
               ], ), // End Main Content Column

            // --- Hold Overlay Visual (Unchanged) ---
            Positioned.fill( child: Visibility( visible: _isHolding, child: IgnorePointer( child: Container( decoration: BoxDecoration( color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(20), ), child: Center( child: Column( mainAxisSize: MainAxisSize.min, children: [ Icon( Icons.task_alt, color: Colors.greenAccent[400], size: 48.0, ), const SizedBox(height: 8), Text( 'Completed', style: TextStyle( color: Colors.greenAccent[400], fontWeight: FontWeight.bold, fontSize: 16,),), ], ),),),),),),

            // --- Undo Button Overlay (Unchanged) ---
            Positioned.fill( child: Visibility( visible: _isPendingRemoval, child: Container( decoration: BoxDecoration( color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20),), child: Center( child: TextButton.icon( icon: const Icon(Icons.undo, size: 20), label: const Text('Undo'), style: TextButton.styleFrom( foregroundColor: Colors.yellowAccent[700], padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), backgroundColor: Colors.black.withOpacity(0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), ), onPressed: _undoCompletion, ),),),),),

          ], // End Stack Children
        ),
      ),
    );
  }
}


// --- Add Task Card Placeholder (Unchanged) ---
class AddTaskCard extends StatelessWidget { /* ... */ final VoidCallback onTap; const AddTaskCard({super.key, required this.onTap}); @override Widget build(BuildContext context) { return GestureDetector( onTap: onTap, child: Container( width: 150, decoration: BoxDecoration( color: Colors.grey[850]?.withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.7), width: 1.5),), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.add_circle_outline, color: Colors.deepPurpleAccent[100], size: 32,), const SizedBox(height: 8), const Text('Add New Task', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500,))]),),); } }

// --- Add Task Dialog (Unchanged) ---
class AddTaskDialog extends StatefulWidget { /* ... */ const AddTaskDialog({super.key}); @override State<AddTaskDialog> createState() => _AddTaskDialogState(); }
class _AddTaskDialogState extends State<AddTaskDialog> { /* ... */ final _formKey = GlobalKey<FormState>(); final _titleController = TextEditingController(); final _durationController = TextEditingController(); String _energyLevel = 'MEDIUM'; @override Widget build(BuildContext context) { return Dialog( backgroundColor: Colors.grey[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding( padding: const EdgeInsets.all(20), child: Form( key: _formKey, child: Column( mainAxisSize: MainAxisSize.min, children: [ const Text('Add New Task', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 24), TextFormField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Task Title', labelStyle: TextStyle(color: Colors.grey[400]), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)), errorStyle: const TextStyle(color: Colors.redAccent)), validator: (v)=>(v==null||v.trim().isEmpty)?'Please enter a title':null), const SizedBox(height: 16), TextFormField(controller: _durationController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Duration (e.g., 1hr 30min)', labelStyle: TextStyle(color: Colors.grey[400]), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)), errorStyle: const TextStyle(color: Colors.redAccent)), validator: (v)=>(v==null||v.trim().isEmpty)?'Please enter a duration':null), const SizedBox(height: 16), DropdownButtonFormField<String>(value: _energyLevel, dropdownColor: Colors.grey[800], style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Energy Level', labelStyle: TextStyle(color: Colors.grey[400]), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)), errorStyle: const TextStyle(color: Colors.redAccent)), items: const [DropdownMenuItem(value: 'HIGH', child: Text('HIGH ENERGY')), DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM ENERGY')), DropdownMenuItem(value: 'LOW', child: Text('LOW ENERGY'))], onChanged: (v){ if (v != null) { setState(() { _energyLevel = v; }); } }, validator: (v)=>(v == null)?'Please select an energy level':null), const SizedBox(height: 32), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))), const SizedBox(width: 12), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { if (_formKey.currentState!.validate()) { Navigator.pop(context, Task(id: DateTime.now().millisecondsSinceEpoch.toString(), title: _titleController.text.trim(), duration: _durationController.text.trim(), energyLevel: _energyLevel, isCompleted: false)); } }, child: const Text('Add Task'))]) ],),),),); } @override void dispose() { _titleController.dispose(); _durationController.dispose(); super.dispose(); } }

// --- Edit Task Dialog (Unchanged) ---
class EditTaskDialog extends StatefulWidget { /* ... */ final Task task; const EditTaskDialog({super.key, required this.task}); @override State<EditTaskDialog> createState() => _EditTaskDialogState(); }
class _EditTaskDialogState extends State<EditTaskDialog> { /* ... */ final _formKey = GlobalKey<FormState>(); late TextEditingController _titleController; late TextEditingController _durationController; late String _energyLevel; @override void initState() { super.initState(); _titleController = TextEditingController(text: widget.task.title); _durationController = TextEditingController(text: widget.task.duration); _energyLevel = widget.task.energyLevel; if (!['HIGH', 'MEDIUM', 'LOW'].contains(_energyLevel)) { _energyLevel = 'MEDIUM'; } } @override Widget build(BuildContext context) { return Dialog( backgroundColor: Colors.grey[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding( padding: const EdgeInsets.all(20), child: Form( key: _formKey, child: Column( mainAxisSize: MainAxisSize.min, children: [ const Text('Edit Task', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 24), TextFormField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Task Title', labelStyle: TextStyle(color: Colors.grey[400]), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)), errorStyle: const TextStyle(color: Colors.redAccent)), validator: (v)=>(v==null||v.trim().isEmpty)?'Please enter a title':null), const SizedBox(height: 16), TextFormField(controller: _durationController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Duration (e.g., 1hr 30min)', labelStyle: TextStyle(color: Colors.grey[400]), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)), errorStyle: const TextStyle(color: Colors.redAccent)), validator: (v)=>(v==null||v.trim().isEmpty)?'Please enter a duration':null), const SizedBox(height: 16), DropdownButtonFormField<String>(value: _energyLevel, dropdownColor: Colors.grey[800], style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Energy Level', labelStyle: TextStyle(color: Colors.grey[400]), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)), errorStyle: const TextStyle(color: Colors.redAccent)), items: const [DropdownMenuItem(value: 'HIGH', child: Text('HIGH ENERGY')), DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM ENERGY')), DropdownMenuItem(value: 'LOW', child: Text('LOW ENERGY'))], onChanged: (v){ if (v != null) { setState(() { _energyLevel = v; }); } }, validator: (v)=>(v == null)?'Please select an energy level':null), const SizedBox(height: 32), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))), const SizedBox(width: 12), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { if (_formKey.currentState!.validate()) { final updatedTask = widget.task.copyWith(title: _titleController.text.trim(), duration: _durationController.text.trim(), energyLevel: _energyLevel); Navigator.pop(context, updatedTask); } }, child: const Text('Save Changes'))]) ],),),),); } @override void dispose() { _titleController.dispose(); _durationController.dispose(); super.dispose(); } }