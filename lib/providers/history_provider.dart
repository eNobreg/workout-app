import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../database/repositories/history_repository.dart';

/// Provider for managing workout history state.
/// Handles loading sessions, exercise history, and set operations.
class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repository = HistoryRepository();

  List<WorkoutSession> _allSessions = [];
  List<SessionSet> _selectedSessionSets = [];
  List<SessionSet> _exerciseHistory = [];
  WorkoutSession? _selectedSession;
  bool _isLoading = false;
  String? _currentProfileId;

  /// All workout sessions for the current user.
  List<WorkoutSession> get allSessions => _allSessions;

  /// Sets for the currently selected session.
  List<SessionSet> get selectedSessionSets => _selectedSessionSets;

  /// History of sets for a specific exercise.
  List<SessionSet> get exerciseHistory => _exerciseHistory;

  /// The currently selected session.
  WorkoutSession? get selectedSession => _selectedSession;

  /// Whether data is being loaded.
  bool get isLoading => _isLoading;

  /// Completed sessions only (excluding in-progress).
  List<WorkoutSession> get completedSessions =>
      _allSessions.where((s) => !s.isInProgress).toList();

  /// Loads all sessions for a user.
  Future<void> loadAllSessions(String userId) async {
    _currentProfileId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      _allSessions = await _repository.getAllSessions(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets sessions within a date range for calendar display.
  Future<List<WorkoutSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    if (_currentProfileId == null) return [];
    return await _repository.getSessionsInRange(_currentProfileId!, start, end);
  }

  /// Gets sessions for a specific date.
  List<WorkoutSession> getSessionsForDate(DateTime date) {
    return _allSessions.where((session) {
      final sessionDate = session.startedAt;
      return sessionDate.year == date.year &&
          sessionDate.month == date.month &&
          sessionDate.day == date.day;
    }).toList();
  }

  /// Gets the details (sets) for a specific session.
  Future<void> getSessionDetails(String sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedSession = await _repository.getSession(sessionId);
      _selectedSessionSets = await _repository.getSessionDetails(sessionId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets all sets for an exercise (for progress charts).
  Future<void> getExerciseHistory(String userId, String exerciseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _exerciseHistory =
          await _repository.getAllSetsForExercise(userId, exerciseId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a session and refreshes the list.
  Future<void> deleteSession(String sessionId) async {
    await _repository.deleteSession(sessionId);
    _allSessions.removeWhere((s) => s.id == sessionId);
    if (_selectedSession?.id == sessionId) {
      _selectedSession = null;
      _selectedSessionSets = [];
    }
    notifyListeners();
  }

  /// Updates a set and refreshes the session details.
  Future<void> updateSet(SessionSet set) async {
    await _repository.updateSetLog(set);
    final index = _selectedSessionSets.indexWhere((s) => s.id == set.id);
    if (index != -1) {
      _selectedSessionSets[index] = set;
    }
    // Also update in exercise history if present
    final historyIndex = _exerciseHistory.indexWhere((s) => s.id == set.id);
    if (historyIndex != -1) {
      _exerciseHistory[historyIndex] = set;
    }
    notifyListeners();
  }

  /// Deletes a set.
  Future<void> deleteSet(String setLogId) async {
    await _repository.deleteSetLog(setLogId);
    _selectedSessionSets.removeWhere((s) => s.id == setLogId);
    _exerciseHistory.removeWhere((s) => s.id == setLogId);
    notifyListeners();
  }

  /// Clears the selected session.
  void clearSelectedSession() {
    _selectedSession = null;
    _selectedSessionSets = [];
    notifyListeners();
  }

  /// Clears exercise history.
  void clearExerciseHistory() {
    _exerciseHistory = [];
    notifyListeners();
  }

  /// Clears all data (when switching profiles).
  void clear() {
    _allSessions = [];
    _selectedSessionSets = [];
    _exerciseHistory = [];
    _selectedSession = null;
    _currentProfileId = null;
    notifyListeners();
  }
}
