import '../../models/models.dart';
import '../../services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Repository for managing quick workout templates in the database.
class TemplateRepository {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  /// Loads all templates for a profile.
  Future<List<QuickWorkoutTemplate>> loadTemplatesByUser(String profileId) async {
    final templateMaps = await _db.query(
      'quick_workout_templates',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'createdAt DESC',
    );
    return templateMaps.map((map) => QuickWorkoutTemplate.fromMap(map)).toList();
  }

  /// Gets a template by ID.
  Future<QuickWorkoutTemplate?> getTemplate(String templateId) async {
    final result = await _db.query(
      'quick_workout_templates',
      where: 'id = ?',
      whereArgs: [templateId],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return QuickWorkoutTemplate.fromMap(result.first);
  }

  /// Creates a new template from a list of exercise IDs.
  Future<QuickWorkoutTemplate> createTemplate({
    required String profileId,
    required String name,
    required List<String> exerciseIds,
  }) async {
    final template = QuickWorkoutTemplate(
      id: _uuid.v4(),
      profileId: profileId,
      name: name,
      items: List.generate(
        exerciseIds.length,
        (index) => TemplateExerciseItem(
          exerciseId: exerciseIds[index],
          sortOrder: index,
        ),
      ),
      createdAt: DateTime.now(),
    );

    await _db.insert('quick_workout_templates', {
      'id': template.id,
      'profileId': template.profileId,
      'name': template.name,
      'exerciseIds': jsonEncode(exerciseIds),
      'createdAt': template.createdAt.toIso8601String(),
    });

    return template;
  }

  /// Updates a template.
  Future<void> updateTemplate(QuickWorkoutTemplate template) async {
    final exerciseIds = template.items.map((item) => item.exerciseId).toList();
    await _db.update(
      'quick_workout_templates',
      {
        'name': template.name,
        'exerciseIds': jsonEncode(exerciseIds),
      },
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  /// Deletes a template.
  Future<void> deleteTemplate(String templateId) async {
    await _db.delete(
      'quick_workout_templates',
      where: 'id = ?',
      whereArgs: [templateId],
    );
  }

  /// Gets exercise IDs from a template.
  Future<List<String>> getTemplateExercises(String templateId) async {
    final template = await getTemplate(templateId);
    if (template == null) return [];
    return template.items.map((item) => item.exerciseId).toList();
  }
}
