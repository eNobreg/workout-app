/// Represents a logged workout session.
/// Tracks when a user performs a workout with all their sets.
class WorkoutSession {
  final String id;
  final String profileId;
  final String? workoutId; // Reference to workout template (can be null for ad-hoc)
  final String? workoutName; // Stored name at time of session
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? notes;

  WorkoutSession({
    required this.id,
    required this.profileId,
    this.workoutId,
    this.workoutName,
    required this.startedAt,
    this.completedAt,
    this.notes,
  });

  /// Creates a WorkoutSession from a database map.
  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      workoutId: map['workout_id'] as String?,
      workoutName: map['workout_name'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  /// Converts the WorkoutSession to a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'workout_id': workoutId,
      'workout_name': workoutName,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Returns true if the session is still in progress.
  bool get isInProgress => completedAt == null;

  /// Returns the duration of the workout session.
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  /// Creates a copy of the WorkoutSession with optional field updates.
  WorkoutSession copyWith({
    String? id,
    String? profileId,
    String? workoutId,
    String? workoutName,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'WorkoutSession(id: $id, workoutName: $workoutName, startedAt: $startedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
