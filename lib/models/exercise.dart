/// Represents a custom exercise defined by a user.
/// No predefined database - users create their own exercises.
///
/// Exercises store user-defined *defaults* (sets/reps/weight) that can be overridden
/// when logging a workout, but still serve as the baseline for templates and quick
/// workouts.
class Exercise {
  final String id;
  final String profileId;
  final String name;
  final String? notes;
  final int defaultSets;
  final int defaultReps;
  final double defaultWeight;
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.profileId,
    required this.name,
    this.notes,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultWeight,
    required this.createdAt,
  });

  /// Creates an Exercise from a database map.
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      name: map['name'] as String,
      notes: map['notes'] as String?,
      defaultSets: map['default_sets'] as int? ?? 3,
      defaultReps: map['default_reps'] as int? ?? 10,
      defaultWeight: map['default_weight'] != null
          ? (map['default_weight'] as num).toDouble()
          : 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts the Exercise to a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'notes': notes,
      'default_sets': defaultSets,
      'default_reps': defaultReps,
      'default_weight': defaultWeight,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of the Exercise with optional field updates.
  Exercise copyWith({
    String? id,
    String? profileId,
    String? name,
    String? notes,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeight,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Exercise(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
