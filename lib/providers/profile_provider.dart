import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';

/// Provider for managing user profiles.
class ProfileProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<Profile> _profiles = [];
  Profile? _activeProfile;
  bool _isLoading = false;

  /// All profiles.
  List<Profile> get profiles => _profiles;

  /// The currently active profile.
  Profile? get activeProfile => _activeProfile;

  /// Whether the provider is loading data.
  bool get isLoading => _isLoading;

  /// Loads all profiles from the database.
  Future<void> loadProfiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profiles = await _db.getProfiles();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new profile.
  Future<Profile> createProfile(String name) async {
    final profile = Profile(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );

    await _db.insertProfile(profile);
    _profiles.add(profile);
    notifyListeners();

    return profile;
  }

  /// Updates an existing profile.
  Future<void> updateProfile(Profile profile) async {
    await _db.updateProfile(profile);
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _profiles[index] = profile;
      if (_activeProfile?.id == profile.id) {
        _activeProfile = profile;
      }
      notifyListeners();
    }
  }

  /// Deletes a profile.
  Future<void> deleteProfile(String id) async {
    await _db.deleteProfile(id);
    _profiles.removeWhere((p) => p.id == id);
    if (_activeProfile?.id == id) {
      _activeProfile = null;
    }
    notifyListeners();
  }

  /// Sets the active profile.
  Future<void> setActiveProfile(Profile? profile) async {
    _activeProfile = profile;
    if (profile != null) {
      final updated = profile.copyWith(lastActiveAt: DateTime.now());
      await _db.updateProfile(updated);
      final index = _profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _profiles[index] = updated;
      }
      _activeProfile = updated;
    }
    notifyListeners();
  }

  /// Gets a profile by ID.
  Profile? getProfile(String id) {
    try {
      return _profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
