import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';

/// Provider for managing exercises.
class ExerciseProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<Exercise> _exercises = [];
  bool _isLoading = false;
  String? _currentProfileId;

  /// All exercises for the current profile.
  List<Exercise> get exercises => _exercises;

  /// Whether the provider is loading data.
  bool get isLoading => _isLoading;

  /// Loads exercises for a profile.
  Future<void> loadExercises(String profileId) async {
    _currentProfileId = profileId;
    _isLoading = true;
    notifyListeners();

    try {
      _exercises = await _db.getExercises(profileId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new exercise.
  Future<Exercise> createExercise({
    required String name,
    String? notes,
  }) async {
    if (_currentProfileId == null) {
      throw StateError('No profile selected');
    }

    final exercise = Exercise(
      id: _uuid.v4(),
      profileId: _currentProfileId!,
      name: name,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _db.insertExercise(exercise);
    _exercises.add(exercise);
    _exercises.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();

    return exercise;
  }

  /// Updates an existing exercise.
  Future<void> updateExercise(Exercise exercise) async {
    await _db.updateExercise(exercise);
    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      _exercises[index] = exercise;
      _exercises.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  /// Deletes an exercise.
  Future<void> deleteExercise(String id) async {
    await _db.deleteExercise(id);
    _exercises.removeWhere((e) => e.id == id);
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
    _currentProfileId = null;
    notifyListeners();
  }
}
