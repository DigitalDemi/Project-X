import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class Task {
  final String id;
  final String title;
  final String duration;
  final String energyLevel;
  final String? imagePath;

  Task({
    required this.id,
    required this.title,
    required this.duration,
    required this.energyLevel,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'duration': duration,
    'energyLevel': energyLevel,
    'imagePath': imagePath,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    duration: json['duration'],
    energyLevel: json['energyLevel'],
    imagePath: json['imagePath'],
  );
}

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onEdit;
  final Function(String)? onImageChanged;

  const TaskCard({
    super.key,
    required this.task,
    this.onEdit,
    this.onImageChanged,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && widget.onImageChanged != null) {
        widget.onImageChanged!(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                image: widget.task.imagePath != null
                    ? DecorationImage(
                        image: FileImage(File(widget.task.imagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.task.imagePath == null
                  ? Icon(
                      Icons.add_photo_alternate,
                      color: Colors.grey[600],
                      size: 20,
                    )
                  : null,
            ),
          ),
          const Spacer(),
          Text(
            widget.task.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.duration,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.task.energyLevel,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AddTaskCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddTaskCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.deepPurpleAccent,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.deepPurpleAccent,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'Add New Task',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  String _energyLevel = 'HIGH ENERGY';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New Task',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Task Title',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Duration (e.g., 1HR 30MIN)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _energyLevel,
              dropdownColor: Colors.grey[850],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Energy Level',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'HIGH ENERGY',
                  child: Text('HIGH ENERGY', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: 'LOW ENERGY',
                  child: Text('LOW ENERGY', style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _energyLevel = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                  onPressed: () {
                    if (_titleController.text.isNotEmpty &&
                        _durationController.text.isNotEmpty) {
                      Navigator.pop(context, Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleController.text,
                        duration: _durationController.text,
                        energyLevel: _energyLevel,
                      ));
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}

class TaskCardList extends StatefulWidget {
  const TaskCardList({super.key});

  @override
  State<TaskCardList> createState() => _TaskCardListState();
}

class _TaskCardListState extends State<TaskCardList> {
  List<Task> _tasks = [];
  final String _storageKey = 'tasks';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_storageKey);
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      setState(() {
        _tasks = decoded.map((task) => Task.fromJson(task)).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_storageKey, tasksJson);
  }

  Future<void> _showAddTaskDialog() async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );

    if (result != null) {
      setState(() {
        _tasks.add(result);
      });
      await _saveTasks();
    }
  }

  Future<void> _updateTaskImage(int index, String imagePath) async {
    setState(() {
      _tasks[index] = Task(
        id: _tasks[index].id,
        title: _tasks[index].title,
        duration: _tasks[index].duration,
        energyLevel: _tasks[index].energyLevel,
        imagePath: imagePath,
      );
    });
    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tasks.length + 1,  // +1 for the Add Task card
        itemBuilder: (context, index) {
          if (index == _tasks.length) {
            return AddTaskCard(onTap: _showAddTaskDialog);
          }
          
          final task = _tasks[index];
          return TaskCard(
            task: task,
            onImageChanged: (path) => _updateTaskImage(index, path),
          );
        },
      ),
    );
  }
}