// lib/ui/tasks/task_list.dart
import 'package:flutter/material.dart';
import 'package:frontend/ui/calender/next_time_block.dart';

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
      height: 400,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Task List
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              margin: const EdgeInsets.only(right: 4),
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
                      Icon(
                        Icons.edit_note,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Add task input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Add new task',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.all(8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.deepPurpleAccent,
                        ),
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: _addTask,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Tasks list
                  Expanded(
                    child: ListView.builder(
                      itemCount: tasks.length,
                      padding: EdgeInsets.zero,
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
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            leading: Transform.scale(
                              scale: 0.8,
                              child: Checkbox(
                                value: tasks[index].isCompleted,
                                onChanged: (_) => _toggleTask(index),
                                activeColor: Colors.deepPurpleAccent,
                              ),
                            ),
                            title: Text(
                              tasks[index].title,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
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
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: const NextTimeBlock(),
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