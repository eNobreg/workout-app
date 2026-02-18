/// Represents an exercise within a workout template.
/// Links exercises to workouts with ordering and default set count.
class WorkoutExercise {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int sortOrder;
  final int defaultSets;
  final int? defaultReps;
  final double? defaultWeight;

  WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.sortOrder,
    this.defaultSets = 3,
    this.defaultReps,
    this.defaultWeight,
  });

  /// Creates a WorkoutExercise from a database map.
  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] as String,
      workoutId: map['workout_id'] as String,
      exerciseId: map['exercise_id'] as String,
      sortOrder: map['sort_order'] as int,
      defaultSets: map['default_sets'] as int? ?? 3,
      defaultReps: map['default_reps'] as int?,
      defaultWeight: map['default_weight'] != null
          ? (map['default_weight'] as num).toDouble()
          : null,
    );
  }

  /// Converts the WorkoutExercise to a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'sort_order': sortOrder,
      'default_sets': defaultSets,
      'default_reps': defaultReps,
      'default_weight': defaultWeight,
    };
  }

  /// Creates a copy of the WorkoutExercise with optional field updates.
  WorkoutExercise copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? sortOrder,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeight,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultWeight: defaultWeight ?? this.defaultWeight,
    );
  }

  @override
  String toString() =>
      'WorkoutExercise(id: $id, workoutId: $workoutId, exerciseId: $exerciseId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExercise &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
