import '../../models/models.dart';
import '../../services/database_service.dart';

/// Repository for accessing workout history data.
/// Provides methods for retrieving sessions, sets, and exercise history.
class HistoryRepository {
  final DatabaseService _db;

  HistoryRepository({DatabaseService? db}) : _db = db ?? DatabaseService.instance;

  /// Gets all completed workout sessions for a user.
  Future<List<WorkoutSession>> getAllSessions(String userId) async {
    return await _db.getWorkoutSessions(userId);
  }

  /// Gets all sets for a specific session.
  Future<List<SessionSet>> getSessionDetails(String sessionId) async {
    return await _db.getSessionSets(sessionId);
  }

  /// Gets all sets for a specific exercise across all sessions.
  Future<List<SessionSet>> getAllSetsForExercise(
    String userId,
    String exerciseId,
  ) async {
    return await _db.getExerciseHistory(exerciseId);
  }

  /// Gets sessions within a date range (for calendar view).
  Future<List<WorkoutSession>> getSessionsInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    return await _db.getWorkoutSessionsInRange(userId, start, end);
  }

  /// Deletes a workout session and all its sets.
  Future<void> deleteSession(String sessionId) async {
    await _db.deleteWorkoutSession(sessionId);
  }

  /// Updates a session set.
  Future<void> updateSetLog(SessionSet set) async {
    await _db.updateSessionSet(set);
  }

  /// Deletes a session set.
  Future<void> deleteSetLog(String setId) async {
    await _db.deleteSessionSet(setId);
  }

  /// Gets a single session by ID.
  Future<WorkoutSession?> getSession(String sessionId) async {
    return await _db.getWorkoutSession(sessionId);
  }
}
