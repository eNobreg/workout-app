import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';

/// Provider for managing workout sessions and session sets.
class SessionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<WorkoutSession> _sessions = [];
  WorkoutSession? _activeSession;
  List<SessionSet> _activeSets = [];
  bool _isLoading = false;
  String? _currentProfileId;

  /// All sessions for the current profile.
  List<WorkoutSession> get sessions => _sessions;

  /// The currently active (in-progress) session.
  WorkoutSession? get activeSession => _activeSession;

  /// Sets for the active session.
  List<SessionSet> get activeSets => _activeSets;

  /// Whether the provider is loading data.
  bool get isLoading => _isLoading;

  /// Loads sessions for a profile.
  Future<void> loadSessions(String profileId) async {
    _currentProfileId = profileId;
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _db.getWorkoutSessions(profileId);

      // Check for any in-progress session
      _activeSession = _sessions.where((s) => s.isInProgress).firstOrNull;
      if (_activeSession != null) {
        _activeSets = await _db.getSessionSets(_activeSession!.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets sessions within a date range (for calendar view).
  Future<List<WorkoutSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    if (_currentProfileId == null) return [];
    return await _db.getWorkoutSessionsInRange(_currentProfileId!, start, end);
  }

  /// Starts a new workout session.
  Future<WorkoutSession> startSession({
    String? workoutId,
    String? workoutName,
  }) async {
    if (_currentProfileId == null) {
      throw StateError('No profile selected');
    }

    // End any existing active session
    if (_activeSession != null) {
      await endSession();
    }

    final session = WorkoutSession(
      id: _uuid.v4(),
      profileId: _currentProfileId!,
      workoutId: workoutId,
      workoutName: workoutName,
      startedAt: DateTime.now(),
    );

    await _db.insertWorkoutSession(session);
    _sessions.insert(0, session);
    _activeSession = session;
    _activeSets = [];
    notifyListeners();

    return session;
  }

  /// Ends the current active session.
  Future<void> endSession({String? notes}) async {
    if (_activeSession == null) return;

    final completed = _activeSession!.copyWith(
      completedAt: DateTime.now(),
      notes: notes,
    );

    await _db.updateWorkoutSession(completed);
    final index = _sessions.indexWhere((s) => s.id == completed.id);
    if (index != -1) {
      _sessions[index] = completed;
    }

    _activeSession = null;
    _activeSets = [];
    notifyListeners();
  }

  /// Logs a set for the active session.
  Future<SessionSet> logSet({
    required String exerciseId,
    required String exerciseName,
    required int setNumber,
    double? weight,
    int? reps,
    String? notes,
  }) async {
    if (_activeSession == null) {
      throw StateError('No active session');
    }

    final set = SessionSet(
      id: _uuid.v4(),
      sessionId: _activeSession!.id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      loggedAt: DateTime.now(),
      notes: notes,
    );

    await _db.insertSessionSet(set);
    _activeSets.add(set);
    notifyListeners();

    return set;
  }

  /// Updates a logged set.
  Future<void> updateSet(SessionSet set) async {
    await _db.updateSessionSet(set);
    final index = _activeSets.indexWhere((s) => s.id == set.id);
    if (index != -1) {
      _activeSets[index] = set;
      notifyListeners();
    }
  }

  /// Deletes a logged set.
  Future<void> deleteSet(String id) async {
    await _db.deleteSessionSet(id);
    _activeSets.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  /// Gets all sets for a specific session.
  Future<List<SessionSet>> getSessionSets(String sessionId) async {
    return await _db.getSessionSets(sessionId);
  }

  /// Gets exercise history for charts/graphs.
  Future<List<SessionSet>> getExerciseHistory(String exerciseId) async {
    return await _db.getExerciseHistory(exerciseId);
  }

  /// Gets the last set logged for an exercise (for auto-fill suggestions).
  SessionSet? getLastSetForExercise(String exerciseId) {
    final exerciseSets = _activeSets
        .where((s) => s.exerciseId == exerciseId)
        .toList()
      ..sort((a, b) => b.setNumber.compareTo(a.setNumber));
    return exerciseSets.firstOrNull;
  }

  /// Gets all sets for an exercise in the active session.
  List<SessionSet> getActiveSetsForExercise(String exerciseId) {
    return _activeSets
        .where((s) => s.exerciseId == exerciseId)
        .toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  }

  /// Deletes a session and all its sets.
  Future<void> deleteSession(String id) async {
    await _db.deleteWorkoutSession(id);
    _sessions.removeWhere((s) => s.id == id);
    if (_activeSession?.id == id) {
      _activeSession = null;
      _activeSets = [];
    }
    notifyListeners();
  }

  /// Updates a session (e.g., for editing notes).
  Future<void> updateSession(WorkoutSession session) async {
    await _db.updateWorkoutSession(session);
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      if (_activeSession?.id == session.id) {
        _activeSession = session;
      }
      notifyListeners();
    }
  }

  /// Clears sessions (when switching profiles).
  void clear() {
    _sessions = [];
    _activeSession = null;
    _activeSets = [];
    _currentProfileId = null;
    notifyListeners();
  }
}
