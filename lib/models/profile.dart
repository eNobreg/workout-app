/// Represents a user profile in the workout tracker.
/// Supports multi-user functionality on a single device.
class Profile {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  Profile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastActiveAt,
  });

  /// Creates a Profile from a database map.
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastActiveAt: map['last_active_at'] != null
          ? DateTime.parse(map['last_active_at'] as String)
          : null,
    );
  }

  /// Converts the Profile to a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }

  /// Creates a copy of the Profile with optional field updates.
  Profile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  String toString() => 'Profile(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
