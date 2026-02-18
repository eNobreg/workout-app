import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'workout_detail_screen.dart';

/// Screen displaying a list of workout templates.
class WorkoutListScreen extends StatelessWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          if (workoutProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final workouts = workoutProvider.workouts;

          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  const Text('No workouts yet'),
                  const SizedBox(height: 8),
                  const Text('Create workout templates like "Push Day"'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateWorkoutDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Workout'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final exerciseCount =
                  workoutProvider.getWorkoutExercises(workout.id).length;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(workout.name),
                  subtitle: Text(
                    '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _navigateToWorkoutDetail(context, workout),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'workoutListCreateFab',
        onPressed: () => _showCreateWorkoutDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToWorkoutDetail(BuildContext context, Workout workout) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(workoutId: workout.id),
      ),
    );
  }

  Future<void> _showCreateWorkoutDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Workout'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Workout Name',
            hintText: 'e.g., Push Day, Leg Day',
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

    if (name != null && name.isNotEmpty && context.mounted) {
      final workoutProvider = context.read<WorkoutProvider>();
      final workout = await workoutProvider.createWorkout(name: name);

      if (context.mounted) {
        _navigateToWorkoutDetail(context, workout);
      }
    }
  }
}
