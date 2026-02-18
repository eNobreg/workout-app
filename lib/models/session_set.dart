/// Represents a single set logged during a workout session.
/// Tracks weight and reps for each set, with support for logging in any order.
class SessionSet {
  final String id;
  final String sessionId;
  final String exerciseId;
  final String? exerciseName; // Stored name at time of logging
  final int setNumber;
  final double? weight;
  final int? reps;
  final DateTime loggedAt;
  final String? notes;

  SessionSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    this.exerciseName,
    required this.setNumber,
    this.weight,
    this.reps,
    required this.loggedAt,
    this.notes,
  });

  /// Creates a SessionSet from a database map.
  factory SessionSet.fromMap(Map<String, dynamic> map) {
    return SessionSet(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String?,
      setNumber: map['set_number'] as int,
      weight: map['weight'] != null
          ? (map['weight'] as num).toDouble()
          : null,
      reps: map['reps'] as int?,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      notes: map['notes'] as String?,
    );
  }

  /// Converts the SessionSet to a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'logged_at': loggedAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Creates a copy of the SessionSet with optional field updates.
  SessionSet copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    String? exerciseName,
    int? setNumber,
    double? weight,
    int? reps,
    DateTime? loggedAt,
    String? notes,
  }) {
    return SessionSet(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      loggedAt: loggedAt ?? this.loggedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Returns a formatted string of the set (e.g., "135 lbs × 10").
  String get formattedSet {
    final weightStr = weight != null ? '${weight!.toStringAsFixed(1)} lbs' : '-';
    final repsStr = reps != null ? '$reps' : '-';
    return '$weightStr × $repsStr';
  }

  @override
  String toString() =>
      'SessionSet(id: $id, exerciseName: $exerciseName, set: $setNumber, $formattedSet)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionSet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
