import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../database/repositories/rotation_repository.dart';

/// Provider for managing rotation schedules.
class RotationProvider extends ChangeNotifier {
  final RotationRepository _repository = RotationRepository();

  RotationSchedule? _activeSchedule;
  List<RotationDay> _rotationDays = [];
  int _currentDay = 1;
  bool _isLoading = false;
  String? _currentProfileId;

  /// The active rotation schedule.
  RotationSchedule? get activeSchedule => _activeSchedule;

  /// All days in the active rotation.
  List<RotationDay> get rotationDays => _rotationDays;

  /// The current day in the rotation cycle (1-indexed).
  int get currentDay => _currentDay;

  /// The total length of the rotation cycle.
  int get rotationLength => _rotationDays.length;

  /// Whether the provider is loading data.
  bool get isLoading => _isLoading;

  /// Gets the rotation day for the current day.
  RotationDay? get currentRotationDay {
    if (_rotationDays.isEmpty || _currentDay < 1) return null;
    return _rotationDays.firstWhere(
      (d) => d.dayNumber == _currentDay,
      orElse: () => _rotationDays.first,
    );
  }

  /// Loads the active rotation schedule for a profile.
  Future<void> loadRotation(String profileId) async {
    _currentProfileId = profileId;
    _isLoading = true;
    notifyListeners();

    try {
      _activeSchedule = await _repository.loadRotationByUser(profileId);
      _rotationDays = _activeSchedule?.days ?? [];
      _currentDay = 1;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new rotation schedule.
  Future<RotationSchedule> createSchedule(String name) async {
    if (_currentProfileId == null) {
      throw StateError('No profile selected');
    }

    final schedule = await _repository.createRotationSchedule(
      _currentProfileId!,
      name,
    );

    _activeSchedule = schedule;
    _rotationDays = [];
    _currentDay = 1;
    notifyListeners();

    return schedule;
  }

  /// Adds a new day to the rotation.
  Future<RotationDay> addRotationDay({
    String? workoutId,
    bool isRestDay = false,
  }) async {
    if (_activeSchedule == null) {
      throw StateError('No active rotation schedule');
    }

    final dayNumber = _rotationDays.length + 1;
    final day = await _repository.createRotationDay(
      scheduleId: _activeSchedule!.id,
      dayNumber: dayNumber,
      workoutId: workoutId,
      isRestDay: isRestDay,
    );

    _rotationDays.add(day);
    _updateScheduleDays();
    notifyListeners();

    return day;
  }

  /// Updates an existing rotation day.
  Future<void> updateRotationDay(
    RotationDay day, {
    String? newWorkoutId,
    bool? isRestDay,
  }) async {
    final updated = day.copyWith(
      workoutId: isRestDay == true ? null : newWorkoutId,
      isRestDay: isRestDay ?? day.isRestDay,
    );

    await _repository.updateRotationDay(updated);

    final index = _rotationDays.indexWhere((d) => d.id == day.id);
    if (index != -1) {
      _rotationDays[index] = updated;
      _updateScheduleDays();
      notifyListeners();
    }
  }

  /// Deletes a rotation day.
  Future<void> deleteRotationDay(String dayId) async {
    await _repository.deleteRotationDay(dayId);
    _rotationDays.removeWhere((d) => d.id == dayId);

    // Renumber remaining days
    for (var i = 0; i < _rotationDays.length; i++) {
      final updated = _rotationDays[i].copyWith(dayNumber: i + 1);
      _rotationDays[i] = updated;
      await _repository.updateRotationDay(updated);
    }

    _updateScheduleDays();
    notifyListeners();
  }

  /// Reorders days in the rotation.
  Future<void> reorderDays(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final day = _rotationDays.removeAt(oldIndex);
    _rotationDays.insert(newIndex, day);

    // Update day numbers
    for (var i = 0; i < _rotationDays.length; i++) {
      final updated = _rotationDays[i].copyWith(dayNumber: i + 1);
      _rotationDays[i] = updated;
    }

    await _repository.updateDayOrder(_rotationDays);
    _updateScheduleDays();
    notifyListeners();
  }

  /// Calculates and sets the current day based on workout history.
  Future<void> calculateCurrentDay(DateTime? lastWorkoutDate) async {
    if (_currentProfileId == null || _rotationDays.isEmpty) {
      _currentDay = 1;
      notifyListeners();
      return;
    }

    _currentDay = await _repository.getCurrentRotationDay(
      _currentProfileId!,
      lastWorkoutDate,
    );
    notifyListeners();
  }

  /// Manually sets the current day.
  void setCurrentDay(int dayNumber) {
    if (dayNumber >= 1 && dayNumber <= _rotationDays.length) {
      _currentDay = dayNumber;
      notifyListeners();
    }
  }

  /// Advances to the next day in the rotation.
  void advanceDay() {
    if (_rotationDays.isEmpty) return;
    _currentDay = (_currentDay % _rotationDays.length) + 1;
    notifyListeners();
  }

  /// Deletes the active rotation schedule.
  Future<void> deleteSchedule() async {
    if (_activeSchedule == null) return;

    await _repository.deleteRotationSchedule(_activeSchedule!.id);
    _activeSchedule = null;
    _rotationDays = [];
    _currentDay = 1;
    notifyListeners();
  }

  /// Updates the schedule's days list.
  void _updateScheduleDays() {
    if (_activeSchedule != null) {
      _activeSchedule = _activeSchedule!.copyWith(days: List.from(_rotationDays));
    }
  }

  /// Clears rotation data (when switching profiles).
  void clear() {
    _activeSchedule = null;
    _rotationDays = [];
    _currentDay = 1;
    _currentProfileId = null;
    notifyListeners();
  }
}
