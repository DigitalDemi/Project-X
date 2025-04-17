import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/habit_service.dart';
import '../../models/habit.dart';
import 'add_habit_dialog.dart';

class HabitBuilderPage extends StatelessWidget {
  const HabitBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Habit Builder'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddHabitDialog(context),
          ),
        ],
      ),
      body: Consumer<HabitService>(
        builder: (context, habitService, child) {
          final todayHabits = habitService.todayHabits;
          final otherHabits = habitService.habits
              .where((h) => !h.isDueToday())
              .toList();
              
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHabitStats(context, habitService),
                const SizedBox(height: 24),
                
                const Text(
                  'Today\'s Habits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (todayHabits.isEmpty)
                  _buildEmptyState(
                    'No habits for today',
                    'Add a new habit to get started',
                    Icons.calendar_today,
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayHabits.length,
                    itemBuilder: (context, index) {
                      return HabitTile(
                        habit: todayHabits[index],
                        onToggle: () => habitService.toggleHabit(todayHabits[index].id),
                        onDelete: () => _confirmDeleteHabit(
                          context, 
                          habitService, 
                          todayHabits[index],
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 32),
                
                const Text(
                  'Other Habits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (otherHabits.isEmpty)
                  _buildEmptyState(
                    'No other habits',
                    'Add habits with different schedules',
                    Icons.calendar_month,
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: otherHabits.length,
                    itemBuilder: (context, index) {
                      return HabitTile(
                        habit: otherHabits[index],
                        onToggle: () => habitService.toggleHabit(otherHabits[index].id),
                        onDelete: () => _confirmDeleteHabit(
                          context, 
                          habitService, 
                          otherHabits[index],
                        ),
                        isGrayed: true,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHabitStats(BuildContext context, HabitService habitService) {
    final completionRate = habitService.todayCompletionRate;
    
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
            'Habit Tracker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Today\'s Progress',
                '${(completionRate * 100).toInt()}%',
                Icons.trending_up,
                Colors.green,
              ),
              _buildStatItem(
                'Habits Due',
                '${habitService.todayHabits.length}',
                Icons.calendar_today,
                Colors.amber,
              ),
              _buildStatItem(
                'Completed',
                '${habitService.completedTodayCount}',
                Icons.check_circle,
                Colors.blue,
              ),
              // lib/ui/self_regulation/habit_builder.dart (continued)
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionRate,
              backgroundColor: Colors.grey[700],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );
  }

  void _confirmDeleteHabit(
    BuildContext context,
    HabitService habitService,
    Habit habit,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Habit', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${habit.title}"? This will remove all streak data.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              habitService.deleteHabit(habit.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isGrayed;

  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
    this.isGrayed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedToday();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isGrayed ? Colors.grey[900] : Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.grey[800]!,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.grey[600]!,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: TextStyle(
                        color: isGrayed ? Colors.white70 : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (habit.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.description!,
                        style: TextStyle(
                          color: isGrayed ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          habit.frequency == 'daily' ? 'Daily' : 'Weekly',
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          'Streak: ${habit.currentStreak}',
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}