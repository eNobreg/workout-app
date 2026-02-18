import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';

/// Screen for viewing and editing a workout template.
class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late TextEditingController _nameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkoutProvider, ExerciseProvider>(
      builder: (context, workoutProvider, exerciseProvider, child) {
        final workout = workoutProvider.getWorkout(widget.workoutId);

        if (workout == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout')),
            body: const Center(child: Text('Workout not found')),
          );
        }

        final workoutExercises =
            workoutProvider.getWorkoutExercises(widget.workoutId);

        return Scaffold(
          appBar: AppBar(
            title: _isEditingName
                ? TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Workout name',
                    ),
                    onSubmitted: (_) => _saveWorkoutName(workout),
                  )
                : Text(workout.name),
            actions: [
              if (_isEditingName)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _saveWorkoutName(workout),
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _startEditingName(workout),
                  tooltip: 'Edit name',
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDeleteWorkout(workout);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Workout',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Workout description (optional)
              if (workout.description != null &&
                  workout.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    workout.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

              // Exercises header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercises',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${workoutExercises.length} total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Exercises list
              Expanded(
                child: workoutExercises.isEmpty
                    ? _buildEmptyExercises()
                    : _buildExercisesList(
                        workoutExercises, exerciseProvider, workoutProvider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'addExerciseToWorkoutFab',
            onPressed: () => _showAddExerciseDialog(exerciseProvider),
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          ),
        );
      },
    );
  }

  Widget _buildEmptyExercises() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text('No exercises yet'),
          const SizedBox(height: 8),
          const Text('Add exercises to this workout'),
        ],
      ),
    );
  }

  Widget _buildExercisesList(
    List<WorkoutExercise> workoutExercises,
    ExerciseProvider exerciseProvider,
    WorkoutProvider workoutProvider,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: workoutExercises.length,
      onReorder: (oldIndex, newIndex) {
        workoutProvider.reorderWorkoutExercises(
            widget.workoutId, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final workoutExercise = workoutExercises[index];
        final exercise = exerciseProvider.getExercise(workoutExercise.exerciseId);
        final exerciseName = exercise?.name ?? 'Unknown Exercise';

        return Card(
          key: ValueKey(workoutExercise.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(exerciseName),
            subtitle: Text(
              '${workoutExercise.defaultSets} sets${workoutExercise.defaultReps != null ? ' × ${workoutExercise.defaultReps} reps' : ''}',
            ),
            onTap: () => _showEditExerciseDefaults(workoutExercise, workoutProvider),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditExerciseDefaults(workoutExercise, workoutProvider);
                } else if (value == 'remove') {
                  _confirmRemoveExercise(workoutExercise, exerciseName);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Defaults'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startEditingName(Workout workout) {
    setState(() {
      _nameController.text = workout.name;
      _isEditingName = true;
    });
  }

  Future<void> _saveWorkoutName(Workout workout) async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != workout.name) {
      final updated = workout.copyWith(name: newName);
      await context.read<WorkoutProvider>().updateWorkout(updated);
    }
    setState(() {
      _isEditingName = false;
    });
  }

  Future<void> _confirmDeleteWorkout(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Workout'),
        content: Text('Are you sure you want to delete "${workout.name}"?'),
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

    if (confirmed == true && mounted) {
      await context.read<WorkoutProvider>().deleteWorkout(workout.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showEditExerciseDefaults(
    WorkoutExercise workoutExercise,
    WorkoutProvider workoutProvider,
  ) async {
    final setsController = TextEditingController(text: '${workoutExercise.defaultSets}');
    final repsController = TextEditingController(
      text: workoutExercise.defaultReps?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: workoutExercise.defaultWeight?.toString() ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Exercise Defaults'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Default Sets',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Default Reps (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Default Weight (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final defaultSets = int.tryParse(setsController.text) ?? 3;
      final defaultReps =
          repsController.text.isNotEmpty ? int.tryParse(repsController.text) : null;
      final defaultWeight = weightController.text.isNotEmpty
          ? double.tryParse(weightController.text)
          : null;

      final updated = workoutExercise.copyWith(
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultWeight: defaultWeight,
      );

      await workoutProvider.updateWorkoutExercise(updated);
      setsController.dispose();
      repsController.dispose();
      weightController.dispose();
    }
  }

  Future<void> _confirmRemoveExercise(
      WorkoutExercise workoutExercise, String exerciseName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: Text('Remove "$exerciseName" from this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<WorkoutProvider>()
          .removeExerciseFromWorkout(widget.workoutId, workoutExercise.id);
    }
  }

  Future<void> _showAddExerciseDialog(ExerciseProvider exerciseProvider) async {
    final exercises = exerciseProvider.exercises;
    final workoutProvider = context.read<WorkoutProvider>();
    final existingExerciseIds = workoutProvider
        .getWorkoutExercises(widget.workoutId)
        .map((we) => we.exerciseId)
        .toSet();

    // Filter out exercises already in the workout
    final availableExercises =
        exercises.where((e) => !existingExerciseIds.contains(e.id)).toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _AddExerciseSheet(
          availableExercises: availableExercises,
          scrollController: scrollController,
          onExerciseSelected: (exercise) async {
            await workoutProvider.addExerciseToWorkout(
              workoutId: widget.workoutId,
              exerciseId: exercise.id,
            );
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          onCreateExercise: () async {
            Navigator.of(context).pop();
            await _showCreateExerciseDialog();
          },
        ),
      ),
    );
  }

  Future<void> _showCreateExerciseDialog() async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Exercise'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Exercise Name',
            hintText: 'e.g., Bench Press, Squat',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      final exerciseProvider = context.read<ExerciseProvider>();
      final exercise = await exerciseProvider.createExercise(name: name);

      // Add the new exercise to the workout
      if (mounted) {
        await context.read<WorkoutProvider>().addExerciseToWorkout(
              workoutId: widget.workoutId,
              exerciseId: exercise.id,
            );
      }
    }
  }
}

/// Bottom sheet for selecting an exercise to add to a workout.
class _AddExerciseSheet extends StatelessWidget {
  final List<Exercise> availableExercises;
  final ScrollController scrollController;
  final Function(Exercise) onExerciseSelected;
  final VoidCallback onCreateExercise;

  const _AddExerciseSheet({
    required this.availableExercises,
    required this.scrollController,
    required this.onExerciseSelected,
    required this.onCreateExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Exercise',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: onCreateExercise,
                icon: const Icon(Icons.add),
                label: const Text('Create New'),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Exercise list
        Expanded(
          child: availableExercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      const Text('No exercises available'),
                      const SizedBox(height: 8),
                      const Text('Create an exercise to add it'),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: availableExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = availableExercises[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle:
                          exercise.notes != null ? Text(exercise.notes!) : null,
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => onExerciseSelected(exercise),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
