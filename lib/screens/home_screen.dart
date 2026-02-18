import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/providers.dart';
import 'workout_detail_screen.dart';
import 'active_workout_screen.dart';
import 'rotation_setup_screen.dart';
import 'workout_history_screen.dart';
import 'session_details_screen.dart';
import 'exercise_history_screen.dart';

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
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _switchProfile,
            tooltip: 'Switch Profile',
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
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
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

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Today';
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

  void _switchProfile() async {
    // Clear current data
    context.read<ExerciseProvider>().clear();
    context.read<WorkoutProvider>().clear();
    context.read<SessionProvider>().clear();
    context.read<RotationProvider>().clear();
    await context.read<ProfileProvider>().setActiveProfile(null);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(Routes.profileSelection);
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
          // Welcome message
          Text(
            'Hello, ${profile?.name ?? 'User'}!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _getGreeting(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Rotation display
          _buildRotationCard(context, rotationProvider, workoutProvider),
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

  Widget _buildRotationCard(
    BuildContext context,
    RotationProvider rotationProvider,
    WorkoutProvider workoutProvider,
  ) {
    final currentDay = rotationProvider.currentRotationDay;
    final rotationLength = rotationProvider.rotationLength;

    // No rotation set up
    if (rotationLength == 0) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.rotate_right),
          title: const Text('Set Up Rotation'),
          subtitle: const Text('Create a workout cycle (e.g., Push/Pull/Legs)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToRotationSetup(context),
        ),
      );
    }

    // Rotation is set up - show current day
    final workout = currentDay?.workoutId != null
        ? workoutProvider.workouts
            .where((w) => w.id == currentDay!.workoutId)
            .firstOrNull
        : null;

    final dayLabel = currentDay?.isRestDay == true
        ? 'Rest Day'
        : (workout?.name ?? 'Workout Day');

    return Card(
      color: currentDay?.isRestDay == true
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: () => _navigateToRotationSetup(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Text(
                  '${rotationProvider.currentDay}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day ${rotationProvider.currentDay}: $dayLabel',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$rotationLength-day rotation cycle',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined),
            ],
          ),
        ),
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
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(exercise.name),
                  subtitle:
                      exercise.notes != null ? Text(exercise.notes!) : null,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'history') {
                        _navigateToExerciseHistory(context, exercise);
                      } else if (value == 'delete') {
                        _confirmDeleteExercise(context, exercise);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.show_chart),
                            SizedBox(width: 8),
                            Text('View History'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _navigateToExerciseHistory(context, exercise),
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
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Bench Press, Squat',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Use wide grip',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext, {
                  'name': name,
                  'notes': notesController.text.trim(),
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      final exerciseProvider = context.read<ExerciseProvider>();
      await exerciseProvider.createExercise(
        name: result['name']!,
        notes: result['notes']!.isNotEmpty ? result['notes'] : null,
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

  Future<void> _confirmDeleteExercise(
      BuildContext context, dynamic exercise) async {
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
      await context.read<ExerciseProvider>().deleteExercise(exercise.id);
    }
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
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final profileId = context.read<ProfileProvider>().activeProfile?.id;
    if (profileId != null) {
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
