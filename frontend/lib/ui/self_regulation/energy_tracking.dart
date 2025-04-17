import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/energy_service.dart';

class EnergyTrackingPage extends StatefulWidget {
  const EnergyTrackingPage({super.key});

  @override
  State<EnergyTrackingPage> createState() => _EnergyTrackingPageState();
}

class _EnergyTrackingPageState extends State<EnergyTrackingPage> {
  int _selectedLevel = 3;
  final _notesController = TextEditingController();
  final _factorsController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _factorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyService>(
      builder: (context, energyService, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.grey[900],
            title: const Text('Energy Tracking'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Energy Level Input
                _buildEnergyLevelInput(),
                
                const SizedBox(height: 24),
                
                // Weekly Energy Chart
                _buildWeeklyEnergyChart(energyService),
                
                const SizedBox(height: 24),
                
                // Recent entries
                _buildRecentEntries(energyService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnergyLevelInput() {
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
            'How\'s your energy right now?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Energy Slider
          Slider(
            value: _selectedLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _getEnergyLabel(_selectedLevel),
            activeColor: _getEnergyColor(_selectedLevel),
            onChanged: (value) {
              setState(() {
                _selectedLevel = value.toInt();
              });
            },
          ),
          
          // Energy labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Very Low', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                Text('Low', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                Text('Medium', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                Text('High', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                Text('Very High', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notes field
          TextField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
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
          
          const SizedBox(height: 16),
          
          // Factors field
          TextField(
            controller: _factorsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'What affected your energy? (optional)',
              labelStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              hintText: 'Sleep, food, stress, exercise...',
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _saveEnergyLevel(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getEnergyColor(_selectedLevel),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Log Energy Level',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyEnergyChart(EnergyService energyService) {
    final weeklyData = energyService.getWeeklyEnergyData();
    
    if (weeklyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No energy data available yet',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    
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
            'Your Energy This Week',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= weeklyData.length) return const Text('');
                        final date = weeklyData[value.toInt()].key;
                        return Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(weeklyData.length, (index) {
                      return FlSpot(index.toDouble(), weeklyData[index].value);
                    }),
                    isCurved: true,
                    color: Colors.deepPurpleAccent,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                  ),
                ],
                minY: 0,
                maxY: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEntries(EnergyService energyService) {
    final recentEntries = energyService.energyLevels.take(5).toList();
    
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
            'Recent Entries',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (recentEntries.isEmpty)
            const Text(
              'No entries yet. Start tracking your energy!',
              style: TextStyle(color: Colors.white70),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentEntries.length,
              itemBuilder: (context, index) {
                final entry = recentEntries[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getEnergyColor(entry.level),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        entry.level.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    _getEnergyLabel(entry.level),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateTime(entry.timestamp),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      if (entry.notes != null && entry.notes!.isNotEmpty)
                        Text(
                          entry.notes!,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _saveEnergyLevel(BuildContext context) {
    final energyService = Provider.of<EnergyService>(context, listen: false);
    
    energyService.addEnergyLevel(
      _selectedLevel,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      factors: _factorsController.text.isEmpty ? null : _factorsController.text,
    );
    
    // Clear fields
    _notesController.clear();
    _factorsController.clear();
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Energy level (${_getEnergyLabel(_selectedLevel)}) saved!'),
        backgroundColor: _getEnergyColor(_selectedLevel),
      ),
    );
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 1: return 'Very Low';
      case 2: return 'Low';
      case 3: return 'Medium';
      case 4: return 'High';
      case 5: return 'Very High';
      default: return 'Medium';
    }
  }

  Color _getEnergyColor(int level) {
    switch (level) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow;
      case 4: return Colors.green[600]!;
      case 5: return Colors.blue;
      default: return Colors.yellow;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}