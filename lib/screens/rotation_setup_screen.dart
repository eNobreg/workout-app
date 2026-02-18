import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/rotation_day_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotation Setup'),
        actions: [
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
                      'Create a rotation cycle by adding days.\nExample: Push, Pull, Legs, Rest',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _addDay(context, rotationProvider, workouts),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Day'),
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
                            'Current: Day ${rotationProvider.currentDay}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Days list
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: days.length,
                  onReorder: (oldIndex, newIndex) =>
                      _reorderDays(context, rotationProvider, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final workout = day.workoutId != null
                        ? workouts.where((w) => w.id == day.workoutId).firstOrNull
                        : null;

                    return Dismissible(
                      key: ValueKey(day.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context, day),
                      onDismissed: (_) =>
                          _deleteDay(context, rotationProvider, day.id),
                      child: Card(
                        key: ValueKey('card_${day.id}'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: day.isRestDay
                                ? Theme.of(context).colorScheme.secondaryContainer
                                : Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              '${day.dayNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: day.isRestDay
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            day.isRestDay
                                ? 'Rest Day'
                                : (workout?.name ?? 'Select Workout'),
                            style: TextStyle(
                              fontStyle: day.isRestDay || workout == null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          subtitle: Text('Day ${day.dayNumber}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editDay(
                                  context,
                                  rotationProvider,
                                  day,
                                  workouts,
                                ),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            ],
                          ),
                          onTap: () => _editDay(
                            context,
                            rotationProvider,
                            day,
                            workouts,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer2<RotationProvider, WorkoutProvider>(
        builder: (context, rotationProvider, workoutProvider, child) {
          return FloatingActionButton.extended(
            onPressed: () =>
                _addDay(context, rotationProvider, workoutProvider.workouts),
            icon: const Icon(Icons.add),
            label: const Text('Add Day'),
          );
        },
      ),
    );
  }

  Future<void> _addDay(
    BuildContext context,
    RotationProvider rotationProvider,
    List<Workout> workouts,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => RotationDayDialog(
        dayNumber: rotationProvider.rotationDays.length + 1,
        workouts: workouts,
      ),
    );

    if (result != null) {
      await rotationProvider.addRotationDay(
        workoutId: result['workoutId'] as String?,
        isRestDay: result['isRestDay'] as bool,
      );
      setState(() => _hasChanges = true);
    }
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

  Future<bool> _confirmDelete(BuildContext context, RotationDay day) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Day'),
        content: Text('Are you sure you want to delete Day ${day.dayNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteDay(
    BuildContext context,
    RotationProvider rotationProvider,
    String dayId,
  ) async {
    await rotationProvider.deleteRotationDay(dayId);
    setState(() => _hasChanges = true);
  }

  Future<void> _reorderDays(
    BuildContext context,
    RotationProvider rotationProvider,
    int oldIndex,
    int newIndex,
  ) async {
    await rotationProvider.reorderDays(oldIndex, newIndex);
    setState(() => _hasChanges = true);
  }

  void _saveAndExit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rotation saved')),
    );
    Navigator.pop(context);
  }
}
