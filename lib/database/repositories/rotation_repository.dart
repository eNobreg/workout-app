import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';

/// Repository for rotation schedule database operations.
class RotationRepository {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  /// Loads the active rotation schedule for a user/profile.
  Future<RotationSchedule?> loadRotationByUser(String userId) async {
    return await _db.getActiveRotationSchedule(userId);
  }

  /// Loads all rotation schedules for a user/profile.
  Future<List<RotationSchedule>> loadAllRotationsByUser(String userId) async {
    return await _db.getRotationSchedules(userId);
  }

  /// Creates a new rotation schedule with initial days.
  Future<RotationSchedule> createRotationSchedule(
    String userId,
    String name, {
    List<RotationDay>? days,
  }) async {
    final scheduleId = _uuid.v4();
    final schedule = RotationSchedule(
      id: scheduleId,
      profileId: userId,
      name: name,
      days: days ?? [],
      createdAt: DateTime.now(),
      isActive: true,
    );
    await _db.insertRotationSchedule(schedule);
    return schedule;
  }

  /// Creates a rotation day for a schedule.
  Future<RotationDay> createRotationDay({
    required String scheduleId,
    required int dayNumber,
    String? workoutId,
    bool isRestDay = false,
  }) async {
    final day = RotationDay(
      id: _uuid.v4(),
      scheduleId: scheduleId,
      dayNumber: dayNumber,
      workoutId: workoutId,
      isRestDay: isRestDay,
    );
    await _db.insertRotationDay(day);
    return day;
  }

  /// Updates an existing rotation day.
  Future<void> updateRotationDay(RotationDay day) async {
    await _db.updateRotationDay(day);
  }

  /// Deletes a rotation day by ID.
  Future<void> deleteRotationDay(String dayId) async {
    await _db.deleteRotationDay(dayId);
  }

  /// Updates a rotation schedule.
  Future<void> updateRotationSchedule(RotationSchedule schedule) async {
    await _db.updateRotationSchedule(schedule);
  }

  /// Deletes a rotation schedule.
  Future<void> deleteRotationSchedule(String scheduleId) async {
    await _db.deleteRotationSchedule(scheduleId);
  }

  /// Gets rotation progress for a profile.
  Future<RotationProgress?> getRotationProgress(String profileId) async {
    return await _db.getRotationProgress(profileId);
  }

  /// Inserts or updates rotation progress for a profile.
  Future<void> upsertRotationProgress(RotationProgress progress) async {
    await _db.upsertRotationProgress(progress);
  }

  /// Deletes rotation progress for a profile.
  Future<void> deleteRotationProgress(String profileId) async {
    await _db.deleteRotationProgress(profileId);
  }

  /// Gets the rotation length for a user's active schedule.
  Future<int> getRotationLength(String userId) async {
    final schedule = await _db.getActiveRotationSchedule(userId);
    return schedule?.cycleLength ?? 0;
  }

  /// Calculates the current rotation day based on workout history.
  /// Returns 1-indexed day number.
  Future<int> getCurrentRotationDay(
    String userId,
    DateTime? lastWorkoutDate,
  ) async {
    final schedule = await _db.getActiveRotationSchedule(userId);
    if (schedule == null || schedule.cycleLength == 0) {
      return 1;
    }

    if (lastWorkoutDate == null) {
      return 1;
    }

    // Get the first workout date for this profile
    final sessions = await _db.getWorkoutSessions(userId);
    if (sessions.isEmpty) {
      return 1;
    }

    // Find completed sessions only
    final completedSessions =
        sessions.where((s) => s.completedAt != null).toList();
    if (completedSessions.isEmpty) {
      return 1;
    }

    // Sort by completion date
    completedSessions.sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
    final firstWorkoutDate = completedSessions.first.completedAt!;

    // Calculate days since first workout
    final daysSinceFirst =
        lastWorkoutDate.difference(firstWorkoutDate).inDays + 1;

    // Calculate current position in rotation (1-indexed)
    final currentDay = ((daysSinceFirst - 1) % schedule.cycleLength) + 1;
    return currentDay;
  }

  /// Updates the order of days after reordering.
  Future<void> updateDayOrder(List<RotationDay> days) async {
    for (var i = 0; i < days.length; i++) {
      final updated = days[i].copyWith(dayNumber: i + 1);
      await _db.updateRotationDay(updated);
    }
  }
}
