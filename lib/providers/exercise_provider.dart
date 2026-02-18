import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../database/repositories/repositories.dart';

/// Provider for managing exercises.
class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _repository = ExerciseRepository();

  List<Exercise> _exercises = [];
  List<Exercise> _selectedWorkoutExercises = [];
  bool _isLoading = false;
  String? _currentProfileId;

  /// All exercises for the current profile.
  List<Exercise> get exercises => _exercises;

  /// Alias for exercises (as per sub-issue requirement).
  List<Exercise> get allExercises => _exercises;

  /// Exercises in the currently selected workout.
  List<Exercise> get selectedWorkoutExercises => _selectedWorkoutExercises;

  /// Whether the provider is loading data.
  bool get isLoading => _isLoading;

  /// Loads exercises for a profile.
  Future<void> loadExercises(String profileId) async {
    _currentProfileId = profileId;
    _isLoading = true;
    notifyListeners();

    try {
      _exercises = await _repository.loadExercisesByUser(profileId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new exercise.
  Future<Exercise> createExercise({
    required String name,
    String? notes,
    required int defaultSets,
    required int defaultReps,
    required double defaultWeight,
  }) async {
    if (_currentProfileId == null) {
      throw StateError('No profile selected');
    }

    final exercise = await _repository.createExercise(
      _currentProfileId!,
      name,
      notes: notes,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultWeight: defaultWeight,
    );

    _exercises.add(exercise);
    _exercises.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();

    return exercise;
  }

  /// Updates an existing exercise.
  Future<void> updateExercise(Exercise exercise) async {
    await _repository.updateExercise(exercise);
    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      _exercises[index] = exercise;
      _exercises.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  /// Deletes an exercise.
  Future<void> deleteExercise(String id) async {
    await _repository.deleteExercise(id);
    _exercises.removeWhere((e) => e.id == id);
    _selectedWorkoutExercises.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Loads exercises for a specific workout.
  Future<void> loadExercisesForWorkout(String workoutId) async {
    _selectedWorkoutExercises =
        await _repository.loadExercisesForWorkout(workoutId);
    notifyListeners();
  }

  /// Adds an exercise to a workout.
  Future<void> addToWorkout(String workoutId, String exerciseId) async {
    final orderIndex = _selectedWorkoutExercises.length;
    await _repository.addExerciseToWorkout(workoutId, exerciseId, orderIndex);
    final exercise = getExercise(exerciseId);
    if (exercise != null) {
      _selectedWorkoutExercises.add(exercise);
      notifyListeners();
    }
  }

  /// Removes an exercise from a workout.
  Future<void> removeFromWorkout(String workoutId, String exerciseId) async {
    await _repository.removeExerciseFromWorkout(workoutId, exerciseId);
    _selectedWorkoutExercises.removeWhere((e) => e.id == exerciseId);
    notifyListeners();
  }

  /// Reorders exercises in a workout.
  Future<void> reorderExercises(
      String workoutId, List<Exercise> exercises) async {
    await _repository.updateExerciseOrder(workoutId, exercises);
    _selectedWorkoutExercises = exercises;
    notifyListeners();
  }

  /// Gets an exercise by ID.
  Exercise? getExercise(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Searches exercises by name.
  List<Exercise> searchExercises(String query) {
    if (query.isEmpty) return _exercises;
    final lowerQuery = query.toLowerCase();
    return _exercises
        .where((e) => e.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Clears exercises (when switching profiles).
  void clear() {
    _exercises = [];
    _selectedWorkoutExercises = [];
    _currentProfileId = null;
    notifyListeners();
  }
}
