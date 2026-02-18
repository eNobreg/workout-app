import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';

/// Provider for managing user profiles.
class ProfileProvider extends ChangeNotifier {
  static const String _activeProfileKey = 'active_profile_id';
  
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

  /// Loads all profiles from the database and restores the last active profile.
  Future<void> loadProfiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profiles = await _db.getProfiles();
      // Try to restore the last active profile
      await _restoreActiveProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restores the last active profile from shared preferences.
  Future<void> _restoreActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_activeProfileKey);
    if (savedId != null) {
      final profile = getProfile(savedId);
      if (profile != null) {
        _activeProfile = profile;
      }
    }
  }

  /// Saves the active profile ID to shared preferences.
  Future<void> _saveActiveProfileId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_activeProfileKey, id);
    } else {
      await prefs.remove(_activeProfileKey);
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
      await _saveActiveProfileId(null);
    }
    notifyListeners();
  }

  /// Sets the active profile and persists the selection.
  Future<void> setActiveProfile(Profile? profile) async {
    _activeProfile = profile;
    await _saveActiveProfileId(profile?.id);
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
