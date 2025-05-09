class EnergyLevel {
  final String id;
  final DateTime timestamp;
  final int level; 
  final String? notes;
  final String? factors; 

  EnergyLevel({
    required this.id,
    required this.timestamp,
    required this.level,
    this.notes,
    this.factors,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level,
      'notes': notes,
      'factors': factors,
    };
  }

  factory EnergyLevel.fromMap(Map<String, dynamic> map) {
    return EnergyLevel(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      level: map['level'],
      notes: map['notes'],
      factors: map['factors'],
    );
  }
}