import 'package:flutter/material.dart';
import '../models/models.dart';

/// Dialog for editing a rotation day.
/// Allows selecting a workout or marking as rest day.
class RotationDayDialog extends StatefulWidget {
  /// The day number being edited.
  final int dayNumber;

  /// The current workout ID (null for rest day or new day).
  final String? currentWorkoutId;

  /// Whether currently a rest day.
  final bool isRestDay;

  /// List of available workouts to choose from.
  final List<Workout> workouts;

  const RotationDayDialog({
    super.key,
    required this.dayNumber,
    this.currentWorkoutId,
    this.isRestDay = false,
    required this.workouts,
  });

  @override
  State<RotationDayDialog> createState() => _RotationDayDialogState();
}

class _RotationDayDialogState extends State<RotationDayDialog> {
  late String? _selectedWorkoutId;
  late bool _isRestDay;

  @override
  void initState() {
    super.initState();
    _selectedWorkoutId = widget.currentWorkoutId;
    _isRestDay = widget.isRestDay;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Day ${widget.dayNumber}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rest day toggle
          SwitchListTile(
            title: const Text('Rest Day'),
            subtitle: const Text('No workout scheduled'),
            value: _isRestDay,
            onChanged: (value) {
              setState(() {
                _isRestDay = value;
                if (value) {
                  _selectedWorkoutId = null;
                }
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // Workout dropdown (disabled if rest day)
          if (!_isRestDay) ...[
            const Text(
              'Select Workout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.workouts.isEmpty)
              const Text(
                'No workouts available. Create a workout first.',
                style: TextStyle(color: Colors.grey),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedWorkoutId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Choose a workout',
                ),
                items: widget.workouts
                    .map((workout) => DropdownMenuItem(
                          value: workout.id,
                          child: Text(workout.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWorkoutId = value;
                  });
                },
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, {
              'workoutId': _isRestDay ? null : _selectedWorkoutId,
              'isRestDay': _isRestDay,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
