import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/validators.dart';
import '../widgets/widgets.dart';
import 'active_workout_screen.dart';
import 'rotation_setup_screen.dart';
import 'workout_history_screen.dart';
import 'session_details_screen.dart';
import 'exercise_history_screen.dart';
import 'profile_screen.dart';
import 'workout_detail_screen.dart';

/// Main home screen with bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;

    if (profile == null) {
      // If no profile is selected, redirect to profile selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(Routes.profileSelection);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          // Rotation indicator in app bar
          if (_currentIndex == 0)
            Consumer<RotationProvider>(
              builder: (context, rotationProvider, child) {
                final rotationLength = rotationProvider.rotationLength;
                if (rotationLength == 0) {
                  return IconButton(
                    icon: const Icon(Icons.rotate_right),
                    onPressed: () => _navigateToRotationSetup(context),
                    tooltip: 'Set Up Rotation',
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => _navigateToRotationSetup(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Day ${rotationProvider.currentDay}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
            tooltip: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _TodayTab(),
          _WorkoutsTab(),
          _ExercisesTab(),
          _HistoryTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  void _navigateToRotationSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RotationSetupScreen(),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Workouts';
      case 2:
        return 'Exercises';
      case 3:
        return 'History';
      default:
        return 'Workout Tracker';
    }
  }
}

/// Today tab - shows current workout and quick start options.
class _TodayTab extends StatelessWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    final activeSession = context.watch<SessionProvider>().activeSession;
    final rotationProvider = context.watch<RotationProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Workout card
          _buildTodaysWorkoutCard(context, rotationProvider, workoutProvider),
          const SizedBox(height: 16),

          // Active session card
          if (activeSession != null) ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Workout in Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(activeSession.workoutName ?? 'Quick Workout'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ActiveWorkoutScreen(),
                            ),
                          );
                        },
                        child: const Text('Continue Workout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Quick start section
          Text(
            'Quick Start',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Quick workout button
          Card(
            child: ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Quick Workout'),
              subtitle: const Text('Start an empty workout session'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _startQuickWorkout(context),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Workout Templates section
          Consumer<TemplateProvider>(
            builder: (context, templateProvider, child) {
              final templates = templateProvider.templates;

              if (templates.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Templates',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...templates.take(3).map((template) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.bookmark),
                            title: Text(template.name),
                            subtitle: Text('${template.items.length} exercise${template.items.length == 1 ? '' : 's'}'),
                            trailing: const Icon(Icons.play_arrow),
                            onTap: () => _startQuickWorkoutFromTemplate(context, template),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Workouts section
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, child) {
              final workouts = workoutProvider.workouts;

              if (workouts.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No workouts yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create your first workout to get started',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Workouts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...workouts.take(3).map((workout) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text(workout.name),
                          subtitle: workout.description != null
                              ? Text(workout.description!)
                              : null,
                          trailing: const Icon(Icons.play_arrow),
                          onTap: () => _startWorkout(context, workout),
                        ),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning! Ready for your workout?';
    } else if (hour < 17) {
      return 'Good afternoon! Time to train?';
    } else {
      return 'Good evening! Let\'s get moving!';
    }
  }


  Widget _buildTodaysWorkoutCard(
    BuildContext context,
    RotationProvider rotationProvider,
    WorkoutProvider workoutProvider,
  ) {
    final currentDay = rotationProvider.currentRotationDay;
    final rotationLength = rotationProvider.rotationLength;

    // No rotation or no current day
    if (rotationLength == 0 || currentDay == null) {
      return const SizedBox.shrink();
    }

    final workout = currentDay.workoutId != null
        ? workoutProvider.workouts
            .where((w) => w.id == currentDay.workoutId)
            .firstOrNull
        : null;

    final dayLabel = currentDay.isRestDay
        ? 'Rest Day'
        : (workout?.name ?? 'Workout Day');

    return Card(
      color: currentDay.isRestDay
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Workout",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dayLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!currentDay.isRestDay && workout != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startWorkout(context, workout),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Workout'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startQuickWorkout(BuildContext context) async {
    final sessionProvider = context.read<SessionProvider>();
    await sessionProvider.startSession();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen(),
        ),
      );
    }
  }

  Future<void> _startWorkout(BuildContext context, dynamic workout) async {
    final sessionProvider = context.read<SessionProvider>();
    await sessionProvider.startSession(
      workoutId: workout.id,
      workoutName: workout.name,
    );
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen(),
        ),
      );
    }
  }

  Future<void> _startQuickWorkoutFromTemplate(
    BuildContext context,
    dynamic template,
  ) async {
    final sessionProvider = context.read<SessionProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();

    // Start a new quick workout session
    await sessionProvider.startSession();
    if (!context.mounted) return;

    // Add exercises from the template
    for (final item in template.items) {
      final exercise = exerciseProvider.getExercise(item.exerciseId);
      if (exercise != null) {
        await sessionProvider.logSet(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          setNumber: 1,
          weight: 0.0,
          reps: 0,
        );
      }
    }

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen(),
        ),
      );
    }
  }
}

/// Workouts tab - manage workout templates.
class _WorkoutsTab extends StatelessWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  onTap: () => _navigateToWorkoutDetail(context, workout.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'createWorkoutFab',
        onPressed: () => _showCreateWorkoutDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToWorkoutDetail(BuildContext context, String workoutId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(workoutId: workoutId),
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
        _navigateToWorkoutDetail(context, workout.id);
      }
    }
  }
}

/// Exercises tab - manage custom exercises.
class _ExercisesTab extends StatelessWidget {
  const _ExercisesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ExerciseProvider>(
        builder: (context, exerciseProvider, child) {
          if (exerciseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = exerciseProvider.exercises;

          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  const Text('No exercises yet'),
                  const SizedBox(height: 8),
                  const Text('Create your custom exercises'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateExerciseDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];

              return Dismissible(
                key: ValueKey(exercise.id),
                direction: DismissDirection.startToEnd, // swipe right to delete
                background: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (_) => _confirmDeleteExercise(context, exercise),
                onDismissed: (_) {},
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text(exercise.name),
                    subtitle: exercise.notes != null ? Text(exercise.notes!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.show_chart),
                          tooltip: 'History',
                          onPressed: () =>
                              _navigateToExerciseHistory(context, exercise),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit',
                          onPressed: () => _showEditExerciseDialog(context, exercise),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToExerciseHistory(context, exercise),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'createExerciseFab',
        onPressed: () => _showCreateExerciseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateExerciseDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _ExerciseFormDialog(
        title: 'Create Exercise',
        confirmText: 'Create',
      ),
    );

    if (result != null && context.mounted) {
      final exerciseProvider = context.read<ExerciseProvider>();
      await exerciseProvider.createExercise(
        name: result['name'] as String,
        notes: (result['notes'] as String).isNotEmpty
            ? result['notes'] as String
            : null,
        defaultSets: result['defaultSets'] as int,
        defaultReps: result['defaultReps'] as int,
        defaultWeight: result['defaultWeight'] as double,
      );
    }
  }

  Future<void> _showEditExerciseDialog(
    BuildContext context,
    Exercise exercise,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ExerciseFormDialog(
        title: 'Edit Exercise',
        confirmText: 'Save',
        initialExercise: exercise,
      ),
    );

    if (result != null && context.mounted) {
      final exerciseProvider = context.read<ExerciseProvider>();
      await exerciseProvider.updateExercise(
        exercise.copyWith(
          name: result['name'] as String,
          notes: (result['notes'] as String).isNotEmpty
              ? result['notes'] as String
              : null,
          defaultSets: result['defaultSets'] as int,
          defaultReps: result['defaultReps'] as int,
          defaultWeight: result['defaultWeight'] as double,
        ),
      );
    }
  }

  void _navigateToExerciseHistory(BuildContext context, dynamic exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseHistoryScreen(exercise: exercise),
      ),
    );
  }

  Future<bool> _confirmDeleteExercise(
    BuildContext context,
    Exercise exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to delete "${exercise.name}"?'),
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

    if (confirmed == true && context.mounted) {
      try {
        await context.read<ExerciseProvider>().deleteExercise(exercise.id);
        return true;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete exercise: $e')),
          );
        }
        return false;
      }
    }

    return false;
  }
}

class _ExerciseFormDialog extends StatefulWidget {
  final String title;
  final String confirmText;
  final Exercise? initialExercise;

  const _ExerciseFormDialog({
    required this.title,
    required this.confirmText,
    this.initialExercise,
  });

  @override
  State<_ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<_ExerciseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();

    final ex = widget.initialExercise;

    _nameController = TextEditingController(text: ex?.name ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    _setsController =
        TextEditingController(text: '${ex?.defaultSets ?? 3}');
    _repsController =
        TextEditingController(text: '${ex?.defaultReps ?? 10}');
    _weightController =
        TextEditingController(text: '${ex?.defaultWeight ?? 0}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'notes': _notesController.text.trim(),
      'defaultSets': int.tryParse(_setsController.text.trim()) ?? 3,
      'defaultReps': int.tryParse(_repsController.text.trim()) ?? 10,
      'defaultWeight': double.tryParse(_weightController.text.trim()) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Bench Press, Squat',
              ),
              autofocus: widget.initialExercise == null,
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  validateName(value, fieldName: 'Exercise name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Default Sets'),
              validator: (value) => validateSets(value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Default Reps'),
              validator: (value) => validateReps(value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Default Weight',
                suffixText: 'lbs',
              ),
              validator: (value) => validateWeight(value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Use wide grip',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

/// History tab - view past workouts.
class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final profileId = context.read<ProfileProvider>().activeProfile?.id;
    if (profileId != null && mounted) {
      await context.read<HistoryProvider>().loadAllSessions(profileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        if (historyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = historyProvider.completedSessions;

        return Column(
          children: [
            // Header with "View All" button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Workouts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WorkoutHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            // Sessions list
            Expanded(
              child: sessions.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildSessionsList(theme, sessions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text('No workout history yet'),
          const SizedBox(height: 8),
          const Text('Complete a workout to see it here'),
        ],
      ),
    );
  }

  Widget _buildSessionsList(ThemeData theme, List<dynamic> sessions) {
    // Show only the 10 most recent sessions
    final recentSessions = sessions.take(10).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: recentSessions.length,
      itemBuilder: (context, index) {
        final session = recentSessions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.check_circle,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(session.workoutName ?? 'Quick Workout'),
            subtitle: Text(_formatDate(session.startedAt)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SessionDetailsScreen(sessionId: session.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

