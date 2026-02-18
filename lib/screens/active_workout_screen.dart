import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/exercise_log_card.dart';

/// Screen for an active workout session.
/// Displays exercises from the workout template and allows logging sets.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();

    final session = sessionProvider.activeSession;

    if (session == null) {
      // No active session, go back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get workout exercises if this is a template-based workout
    List<_ExerciseWithDefaults> exercises = [];
    if (session.workoutId != null) {
      final workoutExercises =
          workoutProvider.getWorkoutExercises(session.workoutId!);
      for (final we in workoutExercises) {
        final exercise = exerciseProvider.getExercise(we.exerciseId);
        if (exercise != null) {
          exercises.add(_ExerciseWithDefaults(
            exercise: exercise,
            defaultSets: we.defaultSets,
          ));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.workoutName ?? 'Quick Workout',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              _formatDate(session.startedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmCancelWorkout(context),
          tooltip: 'Cancel Workout',
        ),
        actions: [
          // Timer showing workout duration
          _WorkoutTimer(startedAt: session.startedAt),
        ],
      ),
      body: exercises.isEmpty
          ? _buildQuickWorkoutBody(context, sessionProvider, exerciseProvider)
          : _buildTemplateWorkoutBody(
              context, sessionProvider, exerciseProvider, exercises),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _confirmFinishWorkout(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Finish Workout'),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateWorkoutBody(
    BuildContext context,
    SessionProvider sessionProvider,
    ExerciseProvider exerciseProvider,
    List<_ExerciseWithDefaults> exercises,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final item = exercises[index];
        final sets = sessionProvider.getActiveSetsForExercise(item.exercise.id);

        return ExerciseLogCard(
          exercise: item.exercise,
          defaultSets: item.defaultSets,
          loggedSets: sets,
          onAddSet: (weight, reps) => _addSet(
            sessionProvider,
            item.exercise,
            sets.length + 1,
            weight,
            reps,
          ),
          onUpdateSet: (set, weight, reps) => _updateSet(
            sessionProvider,
            set,
            weight,
            reps,
          ),
          onDeleteSet: (set) => _deleteSet(sessionProvider, set),
        );
      },
    );
  }

  Widget _buildQuickWorkoutBody(
    BuildContext context,
    SessionProvider sessionProvider,
    ExerciseProvider exerciseProvider,
  ) {
    final activeSets = sessionProvider.activeSets;

    // Group sets by exercise
    final exerciseIds = activeSets.map((s) => s.exerciseId).toSet();
    final exercises = exerciseIds
        .map((id) => exerciseProvider.getExercise(id))
        .where((e) => e != null)
        .cast<Exercise>()
        .toList();

    return Column(
      children: [
        // Add exercise button for quick workouts
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => _showAddExerciseSheet(context, exerciseProvider),
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),

        // Exercise list
        Expanded(
          child: exercises.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final sets =
                        sessionProvider.getActiveSetsForExercise(exercise.id);

                    return ExerciseLogCard(
                      exercise: exercise,
                      defaultSets: 3, // Default for quick workouts
                      loggedSets: sets,
                      onAddSet: (weight, reps) => _addSet(
                        sessionProvider,
                        exercise,
                        sets.length + 1,
                        weight,
                        reps,
                      ),
                      onUpdateSet: (set, weight, reps) => _updateSet(
                        sessionProvider,
                        set,
                        weight,
                        reps,
                      ),
                      onDeleteSet: (set) => _deleteSet(sessionProvider, set),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text('No exercises yet'),
          const SizedBox(height: 8),
          const Text('Add an exercise to start logging sets'),
        ],
      ),
    );
  }

  Future<void> _showAddExerciseSheet(
    BuildContext context,
    ExerciseProvider exerciseProvider,
  ) async {
    final exercises = exerciseProvider.exercises;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add Exercise',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: exercises.isEmpty
                  ? const Center(child: Text('No exercises available'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return ListTile(
                          title: Text(exercise.name),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            Navigator.pop(context, exercise);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ).then((exercise) {
      if (exercise != null && exercise is Exercise) {
        // The exercise is now available for adding sets
        // The UI will update when a set is added
      }
    });
  }

  Future<void> _addSet(
    SessionProvider provider,
    Exercise exercise,
    int setNumber,
    double weight,
    int reps,
  ) async {
    await provider.logSet(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
    );
  }

  Future<void> _updateSet(
    SessionProvider provider,
    SessionSet set,
    double weight,
    int reps,
  ) async {
    final updated = set.copyWith(
      weight: weight,
      reps: reps,
    );
    await provider.updateSet(updated);
  }

  Future<void> _deleteSet(SessionProvider provider, SessionSet set) async {
    await provider.deleteSet(set.id);
  }

  Future<void> _confirmFinishWorkout(BuildContext context) async {
    final sessionProvider = context.read<SessionProvider>();
    final totalSets = sessionProvider.activeSets.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finish Workout'),
        content: Text(
          totalSets > 0
              ? 'Complete workout with $totalSets logged set${totalSets == 1 ? '' : 's'}?'
              : 'You haven\'t logged any sets. Finish anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Going'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await sessionProvider.endSession();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _confirmCancelWorkout(BuildContext context) async {
    final sessionProvider = context.read<SessionProvider>();
    final totalSets = sessionProvider.activeSets.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Workout'),
        content: Text(
          totalSets > 0
              ? 'Are you sure? You will lose $totalSets logged set${totalSets == 1 ? '' : 's'}.'
              : 'Cancel this workout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Workout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final session = sessionProvider.activeSession;
      if (session != null) {
        await sessionProvider.deleteSession(session.id);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Helper class to pair exercise with its default sets from workout template.
class _ExerciseWithDefaults {
  final Exercise exercise;
  final int defaultSets;

  _ExerciseWithDefaults({
    required this.exercise,
    required this.defaultSets,
  });
}

/// A widget showing the elapsed workout time.
class _WorkoutTimer extends StatelessWidget {
  final DateTime startedAt;

  const _WorkoutTimer({required this.startedAt});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final elapsed = DateTime.now().difference(startedAt);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 4),
              Text(
                _formatDuration(elapsed),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
