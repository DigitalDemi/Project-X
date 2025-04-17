import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/energy_level.dart';
import 'sync_service.dart';
import 'package:uuid/uuid.dart';

class EnergyService extends ChangeNotifier {
  final SyncService _syncService;
  List<EnergyLevel> _energyLevels = [];
  
  EnergyService(this._syncService) {
    _loadEnergyLevels();
  }

  List<EnergyLevel> get energyLevels => _energyLevels;

  Future<void> _loadEnergyLevels() async {
    try {
      final db = await _syncService.database;
      final levels = await db.query('energy_levels', orderBy: 'timestamp DESC');
      _energyLevels = levels.map((e) => EnergyLevel.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading energy levels: $e');
      }
    }
  }

  Future<void> addEnergyLevel(int level, {String? notes, String? factors}) async {
    try {
      final db = await _syncService.database;
      final energyLevel = EnergyLevel(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        level: level,
        notes: notes,
        factors: factors,
      );

      await db.insert(
        'energy_levels',
        energyLevel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _energyLevels.insert(0, energyLevel);
      notifyListeners();

      _syncService.queueChange({
        'type': 'energy_level',
        'action': 'create',
        'data': energyLevel.toMap(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding energy level: $e');
      }
      rethrow;
    }
  }

  // Get today's average energy level
  double getTodayAverageEnergy() {
    final today = DateTime.now();
    final todayEntries = _energyLevels.where((e) => 
      e.timestamp.day == today.day && 
      e.timestamp.month == today.month &&
      e.timestamp.year == today.year
    ).toList();
    
    if (todayEntries.isEmpty) return 0;
    
    final sum = todayEntries.fold(0, (sum, entry) => sum + entry.level);
    return sum / todayEntries.length;
  }

  // Get energy data for past week
  List<MapEntry<DateTime, double>> getWeeklyEnergyData() {
    final Map<DateTime, List<int>> dailyLevels = {};
    final now = DateTime.now();
    
    // Initialize past 7 days
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      dailyLevels[date] = [];
    }
    
    // Populate with data
    for (final entry in _energyLevels) {
      final date = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      if (date.isAfter(now.subtract(Duration(days: 7)))) {
        dailyLevels.putIfAbsent(date, () => []).add(entry.level);
      }
    }
    
    // Calculate averages
    return dailyLevels.entries.map((entry) {
      if (entry.value.isEmpty) return MapEntry(entry.key, 0.0);
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return MapEntry(entry.key, avg);
    }).toList();
  }
}