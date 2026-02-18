/// Represents a workout template (e.g., "Push Day", "Pull Day", "Leg Day").
/// Users create custom workouts with selected exercises.
class Workout {
  final String id;
  final String profileId;
  final String name;
  final String? description;
  final int sortOrder;
  final DateTime createdAt;

  Workout({
    required this.id,
    required this.profileId,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.createdAt,
  });

  /// Creates a Workout from a database map.
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts the Workout to a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'description': description,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of the Workout with optional field updates.
  Workout copyWith({
    String? id,
    String? profileId,
    String? name,
    String? description,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Workout(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Workout(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workout && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
