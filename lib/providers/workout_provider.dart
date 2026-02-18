import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';

/// Provider for managing workouts and workout exercises.
class WorkoutProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<Workout> _workouts = [];
  Map<String, List<WorkoutExercise>> _workoutExercises = {};
  bool _isLoading = false;
  String? _currentProfileId;

  /// All workouts for the current profile.
  List<Workout> get workouts => _workouts;

  /// Whether the provider is loading data.
  bool get isLoading => _isLoading;

  /// Loads workouts for a profile.
  Future<void> loadWorkouts(String profileId) async {
    _currentProfileId = profileId;
    _isLoading = true;
    notifyListeners();

    try {
      _workouts = await _db.getWorkouts(profileId);
      _workoutExercises = {};

      // Load exercises for each workout
      for (final workout in _workouts) {
        _workoutExercises[workout.id] =
            await _db.getWorkoutExercises(workout.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new workout.
  Future<Workout> createWorkout({
    required String name,
    String? description,
  }) async {
    if (_currentProfileId == null) {
      throw StateError('No profile selected');
    }

    final workout = Workout(
      id: _uuid.v4(),
      profileId: _currentProfileId!,
      name: name,
      description: description,
      sortOrder: _workouts.length,
      createdAt: DateTime.now(),
    );

    await _db.insertWorkout(workout);
    _workouts.add(workout);
    _workoutExercises[workout.id] = [];
    notifyListeners();

    return workout;
  }

  /// Updates an existing workout.
  Future<void> updateWorkout(Workout workout) async {
    await _db.updateWorkout(workout);
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout;
      notifyListeners();
    }
  }

  /// Deletes a workout.
  Future<void> deleteWorkout(String id) async {
    await _db.deleteWorkout(id);
    _workouts.removeWhere((w) => w.id == id);
    _workoutExercises.remove(id);
    notifyListeners();
  }

  /// Gets a workout by ID.
  Workout? getWorkout(String id) {
    try {
      return _workouts.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Gets exercises for a workout.
  List<WorkoutExercise> getWorkoutExercises(String workoutId) {
    return _workoutExercises[workoutId] ?? [];
  }

  /// Adds an exercise to a workout.
  Future<WorkoutExercise> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int defaultSets = 3,
    int? defaultReps,
    double? defaultWeight,
  }) async {
    final exercises = _workoutExercises[workoutId] ?? [];

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
    _workoutExercises[workoutId] = [...exercises, workoutExercise];
    notifyListeners();

    return workoutExercise;
  }

  /// Updates a workout exercise.
  Future<void> updateWorkoutExercise(WorkoutExercise workoutExercise) async {
    await _db.updateWorkoutExercise(workoutExercise);
    final exercises = _workoutExercises[workoutExercise.workoutId];
    if (exercises != null) {
      final index = exercises.indexWhere((e) => e.id == workoutExercise.id);
      if (index != -1) {
        exercises[index] = workoutExercise;
        notifyListeners();
      }
    }
  }

  /// Removes an exercise from a workout.
  Future<void> removeExerciseFromWorkout(
      String workoutId, String workoutExerciseId) async {
    await _db.deleteWorkoutExercise(workoutExerciseId);
    final exercises = _workoutExercises[workoutId];
    if (exercises != null) {
      exercises.removeWhere((e) => e.id == workoutExerciseId);
      notifyListeners();
    }
  }

  /// Reorders exercises in a workout.
  Future<void> reorderWorkoutExercises(
      String workoutId, int oldIndex, int newIndex) async {
    final exercises = _workoutExercises[workoutId];
    if (exercises == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final exercise = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, exercise);

    // Update sort orders
    for (var i = 0; i < exercises.length; i++) {
      final updated = exercises[i].copyWith(sortOrder: i);
      exercises[i] = updated;
      await _db.updateWorkoutExercise(updated);
    }

    notifyListeners();
  }

  /// Clears workouts (when switching profiles).
  void clear() {
    _workouts = [];
    _workoutExercises = {};
    _currentProfileId = null;
    notifyListeners();
  }
}
