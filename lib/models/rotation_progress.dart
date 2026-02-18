/// Represents a user's progress through a rotation schedule.
///
/// This is stored separately from the schedule itself so a user can keep their
/// current position across app launches.
class RotationProgress {
  final String profileId;
  final String scheduleId;
  final int currentDay;
  final int? lastCompletedDay;
  final DateTime? lastCompletedAt;
  final DateTime updatedAt;

  RotationProgress({
    required this.profileId,
    required this.scheduleId,
    required this.currentDay,
    this.lastCompletedDay,
    this.lastCompletedAt,
    required this.updatedAt,
  });

  factory RotationProgress.fromMap(Map<String, dynamic> map) {
    return RotationProgress(
      profileId: map['profile_id'] as String,
      scheduleId: map['schedule_id'] as String,
      currentDay: map['current_day'] as int? ?? 1,
      lastCompletedDay: map['last_completed_day'] as int?,
      lastCompletedAt: map['last_completed_at'] != null
          ? DateTime.parse(map['last_completed_at'] as String)
          : null,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'schedule_id': scheduleId,
      'current_day': currentDay,
      'last_completed_day': lastCompletedDay,
      'last_completed_at': lastCompletedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RotationProgress copyWith({
    String? profileId,
    String? scheduleId,
    int? currentDay,
    int? lastCompletedDay,
    DateTime? lastCompletedAt,
    DateTime? updatedAt,
  }) {
    return RotationProgress(
      profileId: profileId ?? this.profileId,
      scheduleId: scheduleId ?? this.scheduleId,
      currentDay: currentDay ?? this.currentDay,
      lastCompletedDay: lastCompletedDay ?? this.lastCompletedDay,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'RotationProgress(profileId: $profileId, scheduleId: $scheduleId, currentDay: $currentDay)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RotationProgress &&
          runtimeType == other.runtimeType &&
          profileId == other.profileId &&
          scheduleId == other.scheduleId;

  @override
  int get hashCode => Object.hash(profileId, scheduleId);
}
