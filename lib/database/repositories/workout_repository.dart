import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';

/// Repository for workout database operations.
class WorkoutRepository {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  /// Loads all workouts for a user/profile.
  Future<List<Workout>> loadWorkoutsByUser(String userId) async {
    return await _db.getWorkouts(userId);
  }

  /// Creates a new workout for a user.
  Future<Workout> createWorkout(String userId, String name,
      {String? description}) async {
    final workouts = await _db.getWorkouts(userId);
    final workout = Workout(
      id: _uuid.v4(),
      profileId: userId,
      name: name,
      description: description,
      sortOrder: workouts.length,
      createdAt: DateTime.now(),
    );
    await _db.insertWorkout(workout);
    return workout;
  }

  /// Updates an existing workout.
  Future<void> updateWorkout(Workout workout) async {
    await _db.updateWorkout(workout);
  }

  /// Deletes a workout by ID.
  Future<void> deleteWorkout(String workoutId) async {
    await _db.deleteWorkout(workoutId);
  }

  /// Gets a workout by ID.
  Future<Workout?> getWorkout(String workoutId) async {
    return await _db.getWorkout(workoutId);
  }

  /// Gets all workout exercises for a workout.
  Future<List<WorkoutExercise>> getWorkoutExercises(String workoutId) async {
    return await _db.getWorkoutExercises(workoutId);
  }

  /// Adds an exercise to a workout.
  Future<WorkoutExercise> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int defaultSets = 3,
    int? defaultReps,
    double? defaultWeight,
  }) async {
    final exercises = await _db.getWorkoutExercises(workoutId);
    final workoutExercise = WorkoutExercise(
      id: _uuid.v4(),
      workoutId: workoutId,
      exerciseId: exerciseId,
      sortOrder: exercises.length,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultWeight: defaultWeight,
    );
    await _db.insertWorkoutExercise(workoutExercise);
    return workoutExercise;
  }

  /// Updates a workout exercise.
  Future<void> updateWorkoutExercise(WorkoutExercise workoutExercise) async {
    await _db.updateWorkoutExercise(workoutExercise);
  }

  /// Removes an exercise from a workout.
  Future<void> removeExerciseFromWorkout(String workoutExerciseId) async {
    await _db.deleteWorkoutExercise(workoutExerciseId);
  }

  /// Updates the order of exercises in a workout.
  Future<void> updateExerciseOrder(
      String workoutId, List<WorkoutExercise> exercises) async {
    for (var i = 0; i < exercises.length; i++) {
      final updated = exercises[i].copyWith(sortOrder: i);
      await _db.updateWorkoutExercise(updated);
    }
  }
}
