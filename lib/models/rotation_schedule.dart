/// Represents a rotation schedule for workouts.
/// Supports flexible X-day cycles with rest days (e.g., Push/Pull/Legs/Rest).
class RotationSchedule {
  final String id;
  final String profileId;
  final String name;
  final List<RotationDay> days;
  final DateTime createdAt;
  final bool isActive;

  RotationSchedule({
    required this.id,
    required this.profileId,
    required this.name,
    required this.days,
    required this.createdAt,
    this.isActive = true,
  });

  /// Creates a RotationSchedule from a database map.
  /// Note: days must be loaded separately and passed in.
  factory RotationSchedule.fromMap(
    Map<String, dynamic> map, {
    List<RotationDay>? days,
  }) {
    return RotationSchedule(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      name: map['name'] as String,
      days: days ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  /// Converts the RotationSchedule to a map for database storage.
  /// Note: days are stored in a separate table.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Gets the number of days in the rotation cycle.
  int get cycleLength => days.length;

  /// Gets the workout for a specific day in the cycle (0-indexed).
  RotationDay? getDayAt(int index) {
    if (index < 0 || index >= days.length) return null;
    return days[index];
  }

  /// Creates a copy of the RotationSchedule with optional field updates.
  RotationSchedule copyWith({
    String? id,
    String? profileId,
    String? name,
    List<RotationDay>? days,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return RotationSchedule(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'RotationSchedule(id: $id, name: $name, cycleLength: $cycleLength)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RotationSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a single day in a rotation schedule.
/// Can be either a workout day or a rest day.
class RotationDay {
  final String id;
  final String scheduleId;
  final int dayNumber; // 1-indexed position in the rotation
  final String? workoutId; // null for rest days
  final bool isRestDay;

  RotationDay({
    required this.id,
    required this.scheduleId,
    required this.dayNumber,
    this.workoutId,
    this.isRestDay = false,
  });

  /// Creates a RotationDay from a database map.
  factory RotationDay.fromMap(Map<String, dynamic> map) {
    return RotationDay(
      id: map['id'] as String,
      scheduleId: map['schedule_id'] as String,
      dayNumber: map['day_number'] as int,
      workoutId: map['workout_id'] as String?,
      isRestDay: (map['is_rest_day'] as int? ?? 0) == 1,
    );
  }

  /// Converts the RotationDay to a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'day_number': dayNumber,
      'workout_id': workoutId,
      'is_rest_day': isRestDay ? 1 : 0,
    };
  }

  /// Creates a copy of the RotationDay with optional field updates.
  RotationDay copyWith({
    String? id,
    String? scheduleId,
    int? dayNumber,
    String? workoutId,
    bool? isRestDay,
  }) {
    return RotationDay(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      dayNumber: dayNumber ?? this.dayNumber,
      workoutId: workoutId ?? this.workoutId,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }

  @override
  String toString() =>
      'RotationDay(id: $id, dayNumber: $dayNumber, isRestDay: $isRestDay)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RotationDay &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
