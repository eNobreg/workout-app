/// Represents a custom exercise defined by a user.
/// No predefined database - users create their own exercises.
class Exercise {
  final String id;
  final String profileId;
  final String name;
  final String? notes;
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.profileId,
    required this.name,
    this.notes,
    required this.createdAt,
  });

  /// Creates an Exercise from a database map.
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      name: map['name'] as String,
      notes: map['notes'] as String?,
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of the Exercise with optional field updates.
  Exercise copyWith({
    String? id,
    String? profileId,
    String? name,
    String? notes,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
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
