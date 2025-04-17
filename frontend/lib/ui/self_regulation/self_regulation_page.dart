import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/energy_service.dart';
import '../../services/focus_session_service.dart';
import '../../services/habit_service.dart';
import '../../services/mood_service.dart';
import 'energy_tracking.dart';
import 'pomodoro_timer.dart';
import 'habit_builder.dart';
import 'reflection_journal.dart';
import 'mood_tracking.dart';

class SelfRegulationPage extends StatelessWidget {
  const SelfRegulationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Self-Regulation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Develop Your Self-Regulation Skills',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick stats row
            _buildQuickStatsRow(context),
            const SizedBox(height: 32),
            
            // Module cards
            _buildModuleCard(
              context: context,
              title: 'Energy Levels',
              description: 'Track your energy levels throughout the day',
              icon: Icons.battery_charging_full,
              color: Colors.blue,
              page: const EnergyTrackingPage(),
            ),
            const SizedBox(height: 16),
            
            _buildModuleCard(
              context: context,
              title: 'Focus Sessions',
              description: 'Stay focused with the Pomodoro technique',
              icon: Icons.timer,
              color: Colors.orange,
              page: const PomodoroTimerPage(),
            ),
            const SizedBox(height: 16),
            
            _buildModuleCard(
              context: context,
              title: 'Habit Builder',
              description: 'Build and track daily habits',
              icon: Icons.repeat,
              color: Colors.green,
              page: const HabitBuilderPage(),
            ),
            const SizedBox(height: 16),
            
            _buildModuleCard(
              context: context,
              title: 'Reflection Journal',
              description: 'Reflect on your day and track progress',
              icon: Icons.auto_stories,
              color: Colors.purple,
              page: const ReflectionJournalPage(),
            ),
            const SizedBox(height: 16),
            
            _buildModuleCard(
              context: context,
              title: 'Mood Tracking',
              description: 'Monitor your mood and identify patterns',
              icon: Icons.mood,
              color: Colors.teal,
              page: const MoodTrackingPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Consumer<EnergyService>(
          builder: (context, energyService, child) {
            final avgEnergy = energyService.getTodayAverageEnergy();
            return _buildStatCard(
              'Energy',
              avgEnergy > 0 ? avgEnergy.toStringAsFixed(1) : '-',
              Icons.battery_charging_full,
              Colors.blue,
            );
          },
        ),
        
        Consumer<FocusSessionService>(
          builder: (context, focusService, child) {
            final minutes = focusService.getTotalFocusMinutesToday();
            return _buildStatCard(
              'Focus',
              '$minutes min',
              Icons.timer,
              Colors.orange,
            );
          },
        ),
        
        Consumer<HabitService>(
          builder: (context, habitService, child) {
            final count = habitService.completedTodayCount;
            final total = habitService.todayHabits.length;
            return _buildStatCard(
              'Habits',
              '$count/$total',
              Icons.repeat,
              Colors.green,
            );
          },
        ),
        
        Consumer<MoodService>(
          builder: (context, moodService, child) {
            final avgMood = moodService.averageMoodToday;
            return _buildStatCard(
              'Mood',
              avgMood > 0 ? avgMood.toStringAsFixed(1) : '-',
              Icons.mood,
              Colors.teal,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}