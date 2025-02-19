// lib/ui/tasks/task_list.dart
import 'package:flutter/material.dart';

class Task {
  String title;
  bool isCompleted;

  Task({
    required this.title,
    this.isCompleted = false,
  });
}

class TaskListSection extends StatefulWidget {
  const TaskListSection({super.key});

  @override
  State<TaskListSection> createState() => _TaskListSectionState();
}

class _TaskListSectionState extends State<TaskListSection> {
  final List<Task> tasks = [
    Task(title: 'Complete project presentation'),
    Task(title: 'Review team updates'),
    Task(title: 'Schedule client meeting'),
    Task(title: 'Update documentation'),
    Task(title: 'Send weekly report'),
  ];

  final TextEditingController _taskController = TextEditingController();

  void _toggleTask(int index) {
    setState(() {
      tasks[index].isCompleted = !tasks[index].isCompleted;
    });
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        tasks.add(Task(title: _taskController.text));
        _taskController.clear();
      });
    }
  }

  void _removeTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // Fixed height for the entire section
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Task List
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TASK LIST',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.edit_note, color: Colors.white.withOpacity(0.7)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Add task input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add new task',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.deepPurpleAccent),
                        onPressed: _addTask,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tasks list
                  Expanded(
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: Key(tasks[index].title),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _removeTask(index),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                              value: tasks[index].isCompleted,
                              onChanged: (_) => _toggleTask(index),
                              activeColor: Colors.deepPurpleAccent,
                            ),
                            title: Text(
                              tasks[index].title,
                              style: TextStyle(
                                color: Colors.white70,
                                decoration: tasks[index].isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Next Time Block
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'NEXT TIME BLOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 48,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calendar sync coming soon',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}