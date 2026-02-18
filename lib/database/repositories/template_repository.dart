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
    final templateMaps = await _db.getQuickWorkoutTemplates(profileId);
    return templateMaps;
  }

  /// Gets a template by ID.
  Future<QuickWorkoutTemplate?> getTemplate(String templateId) async {
    final result = await _db.getQuickWorkoutTemplate(templateId);
    return result;
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

    await _db.insertQuickWorkoutTemplate(template, exerciseIds);
    return template;
  }

  /// Updates a template.
  Future<void> updateTemplate(QuickWorkoutTemplate template) async {
    final exerciseIds = template.items.map((item) => item.exerciseId).toList();
    await _db.updateQuickWorkoutTemplate(template, exerciseIds);
  }

  /// Deletes a template.
  Future<void> deleteTemplate(String templateId) async {
    await _db.deleteQuickWorkoutTemplate(templateId);
  }

  /// Gets exercise IDs from a template.
  Future<List<String>> getTemplateExercises(String templateId) async {
    final template = await getTemplate(templateId);
    if (template == null) return [];
    return template.items.map((item) => item.exerciseId).toList();
  }
}
