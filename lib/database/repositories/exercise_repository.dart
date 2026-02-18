import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';

/// Repository for exercise database operations.
class ExerciseRepository {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  /// Loads all exercises for a user/profile.
  Future<List<Exercise>> loadExercisesByUser(String userId) async {
    return await _db.getExercises(userId);
  }

  /// Creates a new exercise for a user.
  Future<Exercise> createExercise(
    String userId,
    String name, {
    String? notes,
    required int defaultSets,
    required int defaultReps,
    required double defaultWeight,
  }) async {
    final exercise = Exercise(
      id: _uuid.v4(),
      profileId: userId,
      name: name,
      notes: notes,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultWeight: defaultWeight,
      createdAt: DateTime.now(),
    );
    await _db.insertExercise(exercise);
    return exercise;
  }

  /// Updates an existing exercise.
  Future<void> updateExercise(Exercise exercise) async {
    await _db.updateExercise(exercise);
  }

  /// Deletes an exercise by ID.
  Future<void> deleteExercise(String exerciseId) async {
    await _db.deleteExercise(exerciseId);
  }

  /// Gets an exercise by ID.
  Future<Exercise?> getExercise(String exerciseId) async {
    return await _db.getExercise(exerciseId);
  }

  /// Loads exercises for a specific workout.
  /// Returns the Exercise objects joined with WorkoutExercise data.
  Future<List<Exercise>> loadExercisesForWorkout(String workoutId) async {
    final workoutExercises = await _db.getWorkoutExercises(workoutId);
    final exercises = <Exercise>[];

    for (final we in workoutExercises) {
      final exercise = await _db.getExercise(we.exerciseId);
      if (exercise != null) {
        exercises.add(exercise);
      }
    }

    return exercises;
  }

  /// Adds an exercise to a workout at a specific order index.
  Future<void> addExerciseToWorkout(
    String workoutId,
    String exerciseId,
    int orderIndex,
  ) async {
    final workoutExercise = WorkoutExercise(
      id: _uuid.v4(),
      workoutId: workoutId,
      exerciseId: exerciseId,
      sortOrder: orderIndex,
    );
    await _db.insertWorkoutExercise(workoutExercise);
  }

  /// Removes an exercise from a workout.
  Future<void> removeExerciseFromWorkout(
    String workoutId,
    String exerciseId,
  ) async {
    final workoutExercises = await _db.getWorkoutExercises(workoutId);
    final toRemove = workoutExercises.where((we) => we.exerciseId == exerciseId);

    for (final we in toRemove) {
      await _db.deleteWorkoutExercise(we.id);
    }
  }

  /// Updates the order of exercises in a workout.
  /// The list should contain Exercise objects in the desired order.
  Future<void> updateExerciseOrder(
    String workoutId,
    List<Exercise> exercises,
  ) async {
    final workoutExercises = await _db.getWorkoutExercises(workoutId);

    for (var i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final we = workoutExercises.firstWhere(
        (w) => w.exerciseId == exercise.id,
        orElse: () => throw StateError(
            'Exercise ${exercise.id} not found in workout $workoutId'),
      );
      final updated = we.copyWith(sortOrder: i);
      await _db.updateWorkoutExercise(updated);
    }
  }
}
