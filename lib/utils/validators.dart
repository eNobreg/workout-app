/// Input validation utilities for the workout tracker app.
/// Provides consistent validation across all forms.

/// Validates a name field (profile, workout, exercise names).
/// Returns an error message or null if valid.
String? validateName(String? value, {String fieldName = 'Name', int maxLength = 100}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  if (value.trim().length > maxLength) {
    return '$fieldName must be $maxLength characters or less';
  }
  return null;
}

/// Validates a weight field.
/// Returns an error message or null if valid.
String? validateWeight(String? value, {bool required = true}) {
  if (value == null || value.isEmpty) {
    return required ? 'Enter weight' : null;
  }
  final weight = double.tryParse(value);
  if (weight == null) {
    return 'Invalid number';
  }
  if (weight < 0) {
    return 'Weight cannot be negative';
  }
  return null;
}

/// Validates a reps field.
/// Returns an error message or null if valid.
String? validateReps(String? value, {bool required = true}) {
  if (value == null || value.isEmpty) {
    return required ? 'Enter reps' : null;
  }
  final reps = int.tryParse(value);
  if (reps == null) {
    return 'Invalid number';
  }
  if (reps < 0) {
    return 'Reps cannot be negative';
  }
  if (required && reps <= 0) {
    return 'Reps must be > 0';
  }
  return null;
}

/// Validates a sets field.
/// Returns an error message or null if valid.
String? validateSets(String? value, {bool required = true}) {
  if (value == null || value.isEmpty) {
    return required ? 'Enter sets' : null;
  }
  final sets = int.tryParse(value);
  if (sets == null) {
    return 'Invalid number';
  }
  if (sets <= 0) {
    return 'Sets must be > 0';
  }
  return null;
}

/// Validates a positive integer field.
/// Returns an error message or null if valid.
String? validatePositiveInt(String? value, {String fieldName = 'Value', bool required = true}) {
  if (value == null || value.isEmpty) {
    return required ? 'Enter $fieldName' : null;
  }
  final number = int.tryParse(value);
  if (number == null) {
    return 'Invalid number';
  }
  if (number <= 0) {
    return '$fieldName must be > 0';
  }
  return null;
}

/// Validates a non-negative number field.
/// Returns an error message or null if valid.
String? validateNonNegativeDouble(String? value, {String fieldName = 'Value', bool required = true}) {
  if (value == null || value.isEmpty) {
    return required ? 'Enter $fieldName' : null;
  }
  final number = double.tryParse(value);
  if (number == null) {
    return 'Invalid number';
  }
  if (number < 0) {
    return '$fieldName cannot be negative';
  }
  return null;
}
