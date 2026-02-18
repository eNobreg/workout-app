import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../database/repositories/template_repository.dart';

/// Provider for managing quick workout templates.
class TemplateProvider extends ChangeNotifier {
  final TemplateRepository _repository = TemplateRepository();

  List<QuickWorkoutTemplate> _templates = [];
  bool _isLoading = false;
  String? _currentProfileId;

  /// All templates for the current profile.
  List<QuickWorkoutTemplate> get templates => _templates;

  /// Whether the provider is loading data.
  bool get isLoading => _isLoading;

  /// Loads templates for a profile.
  Future<void> loadTemplates(String profileId) async {
    _currentProfileId = profileId;
    _isLoading = true;
    notifyListeners();

    try {
      _templates = await _repository.loadTemplatesByUser(profileId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new template from exercise IDs.
  Future<QuickWorkoutTemplate> createTemplate({
    required String name,
    required List<String> exerciseIds,
  }) async {
    if (_currentProfileId == null) {
      throw StateError('No profile selected');
    }

    final template = await _repository.createTemplate(
      profileId: _currentProfileId!,
      name: name,
      exerciseIds: exerciseIds,
    );

    _templates.add(template);
    notifyListeners();

    return template;
  }

  /// Deletes a template.
  Future<void> deleteTemplate(String templateId) async {
    await _repository.deleteTemplate(templateId);
    _templates.removeWhere((t) => t.id == templateId);
    notifyListeners();
  }

  /// Gets a template by ID.
  Future<QuickWorkoutTemplate?> getTemplate(String templateId) async {
    return await _repository.getTemplate(templateId);
  }

  /// Clears templates (when switching profiles).
  void clear() {
    _templates = [];
    _currentProfileId = null;
    notifyListeners();
  }
}
