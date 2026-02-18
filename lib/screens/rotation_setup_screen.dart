import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/rotation_day_dialog.dart';
import '../widgets/rotation_days_input_dialog.dart';
import '../widgets/rotation_day_grid_box.dart';

/// Screen for setting up and managing rotation schedules.
class RotationSetupScreen extends StatefulWidget {
  const RotationSetupScreen({super.key});

  @override
  State<RotationSetupScreen> createState() => _RotationSetupScreenState();
}

class _RotationSetupScreenState extends State<RotationSetupScreen> {
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _ensureScheduleExists();
  }

  Future<void> _ensureScheduleExists() async {
    final rotationProvider = context.read<RotationProvider>();
    if (rotationProvider.activeSchedule == null) {
      await rotationProvider.createSchedule('My Rotation');
    }
  }

  Future<void> _showDaysInputDialog() async {
    final days = await showDialog<int>(
      context: context,
      builder: (context) => const RotationDaysInputDialog(),
    );

    if (days != null) {
      await _createRotationDays(days);
    }
  }

  Future<void> _createRotationDays(int count) async {
    final rotationProvider = context.read<RotationProvider>();
    for (int i = 0; i < count; i++) {
      await rotationProvider.addRotationDay(isRestDay: true);
    }
    setState(() => _hasChanges = true);
  }

  Future<void> _showChangeDaysDialog() async {
    final rotationProvider = context.read<RotationProvider>();
    final currentDays = rotationProvider.rotationDays.length;

    final newDays = await showDialog<int>(
      context: context,
      builder: (context) => RotationDaysInputDialog(
        initialDays: currentDays,
      ),
    );

    if (newDays != null && newDays != currentDays) {
      await _adjustRotationDays(newDays, currentDays);
    }
  }

  Future<void> _adjustRotationDays(int newCount, int currentCount) async {
    final rotationProvider = context.read<RotationProvider>();

    if (newCount > currentCount) {
      // Add days
      for (int i = 0; i < newCount - currentCount; i++) {
        await rotationProvider.addRotationDay(isRestDay: true);
      }
    } else if (newCount < currentCount) {
      // Remove days from the end
      final daysToRemove = rotationProvider.rotationDays.skip(newCount).toList();
      for (final day in daysToRemove) {
        await rotationProvider.deleteRotationDay(day.id);
      }
    }

    setState(() => _hasChanges = true);
  }

  Future<void> _showSetCurrentDayDialog(
    RotationProvider rotationProvider,
    WorkoutProvider workoutProvider,
  ) async {
    if (rotationProvider.rotationDays.isEmpty) return;

    final workoutNameById = {
      for (final w in workoutProvider.workouts) w.id: w.name,
    };

    final initialDay = rotationProvider.currentDay.clamp(
      1,
      rotationProvider.rotationDays.length,
    );

    final selectedDay = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        var tempDay = initialDay;

        return AlertDialog(
          title: const Text('Set Current Rotation Day'),
          content: DropdownButtonFormField<int>(
            initialValue: tempDay,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Current day',
            ),
            items: rotationProvider.rotationDays.map((day) {
              final label = day.isRestDay
                  ? 'Day ${day.dayNumber} — Rest'
                  : 'Day ${day.dayNumber} — ${workoutNameById[day.workoutId] ?? 'Workout'}';
              return DropdownMenuItem(
                value: day.dayNumber,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              tempDay = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, tempDay),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );

    if (selectedDay == null) return;

    await rotationProvider.setCurrentDay(selectedDay);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rotation set to Day $selectedDay')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotation Setup'),
        actions: [
          Consumer2<RotationProvider, WorkoutProvider>(
            builder: (context, rotationProvider, workoutProvider, child) {
              final canSetDay = rotationProvider.rotationDays.isNotEmpty;
              return IconButton(
                icon: const Icon(Icons.edit_calendar),
                tooltip: 'Set current day',
                onPressed: canSetDay
                    ? () => _showSetCurrentDayDialog(
                          rotationProvider,
                          workoutProvider,
                        )
                    : null,
              );
            },
          ),
          if (_hasChanges)
            TextButton(
              onPressed: _saveAndExit,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Consumer2<RotationProvider, WorkoutProvider>(
        builder: (context, rotationProvider, workoutProvider, child) {
          if (rotationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final days = rotationProvider.rotationDays;
          final workouts = workoutProvider.workouts;

          if (days.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rotate_right,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No rotation set up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Set up a rotation cycle for your workout split',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showDaysInputDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Set Up Rotation'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Rotation info header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      Icons.rotate_right,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${days.length}-Day Rotation',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Tap boxes to set workouts or rest days',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Current: Day ${rotationProvider.currentDay}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: _showChangeDaysDialog,
                      tooltip: 'Change number of days',
                    ),
                  ],
                ),
              ),

              // Days grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final workout = day.workoutId != null
                          ? workouts.where((w) => w.id == day.workoutId).firstOrNull
                          : null;

                      return RotationDayGridBox(
                        dayNumber: day.dayNumber,
                        isRestDay: day.isRestDay,
                        workoutName: workout?.name,
                        isCurrent:
                            day.dayNumber == rotationProvider.currentDay,
                        onTap: () => _editDay(
                          context,
                          rotationProvider,
                          day,
                          workouts,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _editDay(
    BuildContext context,
    RotationProvider rotationProvider,
    RotationDay day,
    List<Workout> workouts,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => RotationDayDialog(
        dayNumber: day.dayNumber,
        currentWorkoutId: day.workoutId,
        isRestDay: day.isRestDay,
        workouts: workouts,
      ),
    );

    if (result != null) {
      await rotationProvider.updateRotationDay(
        day,
        newWorkoutId: result['workoutId'] as String?,
        isRestDay: result['isRestDay'] as bool,
      );
      setState(() => _hasChanges = true);
    }
  }


  void _saveAndExit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rotation saved')),
    );
    Navigator.pop(context);
  }
}
