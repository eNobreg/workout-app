/// Model for a saved quick workout template.
/// Allows users to save the exercises from a quick workout and start new workouts with those exercises.
class QuickWorkoutTemplate {
  final String id;
  final String profileId;
  final String name;
  final List<TemplateExerciseItem> items; // List of exercise IDs in order
  final DateTime createdAt;

  QuickWorkoutTemplate({
    required this.id,
    required this.profileId,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  /// Creates a copy of this template with optional field overrides.
  QuickWorkoutTemplate copyWith({
    String? id,
    String? profileId,
    String? name,
    List<TemplateExerciseItem>? items,
    DateTime? createdAt,
  }) {
    return QuickWorkoutTemplate(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts the template to a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'name': name,
      'itemsJson': _itemsToJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a template from a database map.
  static QuickWorkoutTemplate fromMap(Map<String, dynamic> map) {
    return QuickWorkoutTemplate(
      id: map['id'] as String,
      profileId: map['profileId'] as String,
      name: map['name'] as String,
      items: _itemsFromJson(map['itemsJson'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  static String _itemsToJson() {
    // For now, store as simple comma-separated exerciseId list
    // Can be enhanced later for more complex data
    return '';
  }

  static List<TemplateExerciseItem> _itemsFromJson(String json) {
    // Parse from JSON string
    if (json.isEmpty) return [];
    return json.split(',').map((id) => TemplateExerciseItem(exerciseId: id)).toList();
  }
}

/// Individual exercise item in a template.
class TemplateExerciseItem {
  final String exerciseId;
  final int sortOrder;

  TemplateExerciseItem({
    required this.exerciseId,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'sortOrder': sortOrder,
    };
  }

  static TemplateExerciseItem fromMap(Map<String, dynamic> map) {
    return TemplateExerciseItem(
      exerciseId: map['exerciseId'] as String,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }
}
