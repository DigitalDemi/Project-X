// lib/ui/tasks/horizontal_task_scroller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:frontend/ui/tasks/task_card.dart'; // Imports Task, TaskCard, Dialogs
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HorizontalTaskScroller extends StatefulWidget {
  const HorizontalTaskScroller({super.key});

  @override
  State<HorizontalTaskScroller> createState() => _HorizontalTaskScrollerState();
}

class _HorizontalTaskScrollerState extends State<HorizontalTaskScroller> {
  List<Task> _tasks = [];
  final String _storageKey = 'tasks_v2';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // --- Data Persistence Methods (Unchanged) ---
  Future<void> _loadTasks() async { if (!mounted) return; setState(() { _isLoading = true; }); try { final prefs = await SharedPreferences.getInstance(); final tasksJson = prefs.getString(_storageKey); List<Task> loadedTasks = []; if (tasksJson != null) { final List<dynamic> decoded = jsonDecode(tasksJson); loadedTasks = decoded.map((taskData) { try { return Task.fromJson(taskData as Map<String, dynamic>); } catch (e) { debugPrint("Error parsing task: $e"); return null; } }).where((t) => t != null).cast<Task>().toList(); } if (mounted) { setState(() { _tasks = loadedTasks; _isLoading = false; }); } } catch (e) { debugPrint("Error loading tasks: $e"); if (mounted) { setState(() { _isLoading = false; }); } } }
  Future<void> _saveTasks() async { if (_isLoading || !mounted) return; try { final prefs = await SharedPreferences.getInstance(); final tasksJson = jsonEncode(_tasks.map((task) => task.toJson()).toList()); await prefs.setString(_storageKey, tasksJson); } catch (e) { debugPrint("Error saving tasks: $e"); if (mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error saving tasks.')),); } } }

  // --- Task Modification Methods (Unchanged) ---
  Future<void> _showAddTaskDialog() async { if (!mounted) return; final result = await showDialog<Task>( context: context, barrierDismissible: false, builder: (context) => const AddTaskDialog(), ); if (result != null && mounted) { setState(() { _tasks.add(result); }); await _saveTasks(); } }
  Future<void> _updateTaskImage(String taskId, String imagePath) async { if (!mounted) return; int taskIndex = _tasks.indexWhere((task) => task.id == taskId); if (taskIndex != -1) { setState(() { _tasks[taskIndex] = _tasks[taskIndex].copyWith(imagePath: imagePath); }); await _saveTasks(); } else { debugPrint("Task with ID $taskId not found for image update."); } }
  Future<void> _handleTaskCompletionChange(String taskId, bool newCompletionState) async { if (!mounted) return; int taskIndex = _tasks.indexWhere((task) => task.id == taskId); if (taskIndex != -1) { final profileService = Provider.of<ProfileService>(context, listen: false); setState(() { _tasks[taskIndex] = _tasks[taskIndex].copyWith(isCompleted: newCompletionState); }); await _saveTasks(); if (newCompletionState == true) { debugPrint("Task $taskId completion state updated to true. Updating streak."); try { await profileService.updateCompletionStreak(); } catch (e) { debugPrint("Error updating streak: $e"); if(mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error updating streak.'))); } } } else { debugPrint("Task $taskId completion state updated to false (Undo/Incomplete)."); } } else { debugPrint("Task with ID $taskId not found for completion update."); } }
  Future<void> _handleTaskDisappearance(String taskId) async { if (!mounted) return; debugPrint("Removing task $taskId from list after timer."); int taskIndex = _tasks.indexWhere((task) => task.id == taskId); if (taskIndex != -1) { setState(() { _tasks.removeAt(taskIndex); }); await _saveTasks(); } else { debugPrint("Task with ID $taskId not found for removal after timer."); } }

  // --- Options Menu (Triggered by TaskCard's onShowOptions via long press) ---
  // **** MODIFIED Menu Items and Order ****
  void _showTaskOptions(BuildContext parentContext, String taskId) {
    int taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) { debugPrint("Task $taskId not found for options menu."); return; }
    final task = _tasks[taskIndex];

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.grey[850],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(child: Wrap(children: <Widget>[

          // 1. Conditional Complete/Incomplete Option
          if (!task.isCompleted)
            ListTile(
              leading: Icon(Icons.check_circle_outline, color: Colors.greenAccent[400]),
              title: Text('Complete Task', style: TextStyle(color: Colors.greenAccent[400])),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _handleTaskCompletionChange(taskId, true); // Mark as complete
              },
            )
          else // Task is already completed
             ListTile(
              leading: Icon(Icons.radio_button_unchecked_outlined, color: Colors.yellowAccent[700]),
              title: Text('Mark as Incomplete', style: TextStyle(color: Colors.yellowAccent[700])),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _handleTaskCompletionChange(taskId, false); // Mark as incomplete
              },
            ),

          // 2. Edit Option
          ListTile(
            leading: Icon(Icons.edit_outlined, color: Colors.blue[300]),
            title: Text('Edit Task', style: TextStyle(color: Colors.blue[300])),
            onTap: () async {
              Navigator.pop(bottomSheetContext);
              final updatedTask = await showDialog<Task>( context: parentContext, barrierDismissible: false, builder: (_) => EditTaskDialog(task: task),);
              if (mounted && updatedTask != null) {
                 int editIndex = _tasks.indexWhere((t) => t.id == taskId);
                 if (editIndex != -1) {
                     setState(() { _tasks[editIndex] = updatedTask; });
                     await _saveTasks();
                     if(mounted) ScaffoldMessenger.of(parentContext).showSnackBar( SnackBar(content: Text('Task "${updatedTask.title}" updated.')),);
                 }
              }
            },
          ),

          // 3. Remove Option
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Remove Task', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              Navigator.pop(bottomSheetContext);
              bool confirm = await showDialog<bool>( context: parentContext, builder: (context) => AlertDialog(backgroundColor: Colors.grey[800], title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)), content: Text('Remove "${task.title}"?', style: TextStyle(color: Colors.white70)), actions: [ TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.redAccent))),])) ?? false;
              if (mounted && confirm) {
                int removeIndex = _tasks.indexWhere((t) => t.id == taskId);
                if (removeIndex != -1) {
                   setState(() { _tasks.removeAt(removeIndex); });
                   await _saveTasks();
                   if(mounted) ScaffoldMessenger.of(parentContext).showSnackBar( SnackBar(content: Text('Task "${task.title}" removed.')),);
                }
              }
            },
          ),

          // 4. Cancel Option
          Divider(height: 1, thickness: 1, color: Colors.grey[700]),
          ListTile(
             leading: Icon(Icons.cancel_outlined, color: Colors.grey[400]),
             title: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
             onTap: () => Navigator.pop(bottomSheetContext),
          ),

        ],),);
      },
    );
  }

  // --- Build Method (Includes Sorting) ---
  @override
  Widget build(BuildContext context) {
    const double scrollerHeight = 180.0;

    if (_isLoading) {
      return SizedBox( height: scrollerHeight, child: Center( child: CircularProgressIndicator( color: Colors.deepPurpleAccent[100], strokeWidth: 3.0, ), ), );
    }

    // **** SORT the tasks: Incomplete first, then Completed ****
    List<Task> sortedTasks = List.from(_tasks);
    sortedTasks.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1; // false (incomplete) comes first
    });
    // ********************************************************

    return SizedBox(
      height: scrollerHeight,
      child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              scrollDirection: Axis.horizontal,
              itemCount: sortedTasks.length + 1,
              itemBuilder: (context, index) {
                if (index == sortedTasks.length) {
                  return Padding( padding: EdgeInsets.only(left: sortedTasks.isNotEmpty ? 16 : 0), child: AddTaskCard(onTap: _showAddTaskDialog),);
                }

                final task = sortedTasks[index];
                return Padding(
                  padding: EdgeInsets.only(right: (index < sortedTasks.length - 1) ? 16 : 0),
                  child: TaskCard(
                    key: ValueKey(task.id),
                    task: task,
                    onImageChanged: (path) => _updateTaskImage(task.id, path), // Pass ID
                    onCompletionChanged: _handleTaskCompletionChange, // Uses ID internally
                    onTaskDisappear: _handleTaskDisappearance,       // Uses ID internally
                    // **** Long press now calls _showTaskOptions ****
                    onShowOptions: () => _showTaskOptions(context, task.id), // Pass ID
                  ),
                );
              },
            ),
    );
  }
}