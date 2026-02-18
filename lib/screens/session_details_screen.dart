import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/history_provider.dart';
import '../widgets/set_input_card.dart';

/// Screen displaying details of a specific workout session.
/// Shows all sets grouped by exercise with edit/delete options.
class SessionDetailsScreen extends StatefulWidget {
  /// The session ID to display.
  final String sessionId;

  const SessionDetailsScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<HistoryProvider>().getSessionDetails(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = historyProvider.selectedSession;
          final sets = historyProvider.selectedSessionSets;

          if (session == null) {
            return const Center(child: Text('Session not found'));
          }

          return _buildSessionDetails(theme, session, sets);
        },
      ),
    );
  }

  Widget _buildSessionDetails(
    ThemeData theme,
    WorkoutSession session,
    List<SessionSet> sets,
  ) {
    // Group sets by exercise
    final groupedSets = <String, List<SessionSet>>{};
    for (final set in sets) {
      final exerciseKey = set.exerciseId;
      groupedSets.putIfAbsent(exerciseKey, () => []);
      groupedSets[exerciseKey]!.add(set);
    }

    return CustomScrollView(
      slivers: [
        // Session header
        SliverToBoxAdapter(
          child: _buildSessionHeader(theme, session, sets),
        ),

        // Sets list grouped by exercise
        if (groupedSets.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No sets recorded',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exerciseId = groupedSets.keys.elementAt(index);
                  final exerciseSets = groupedSets[exerciseId]!;
                  final exerciseName = exerciseSets.first.exerciseName ?? 'Unknown';

                  return _buildExerciseGroup(theme, exerciseName, exerciseSets);
                },
                childCount: groupedSets.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionHeader(
    ThemeData theme,
    WorkoutSession session,
    List<SessionSet> sets,
  ) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(session.startedAt);
    final timeStr = DateFormat('h:mm a').format(session.startedAt);
    final duration = session.duration;
    final durationStr = duration != null
        ? '${duration.inMinutes} minutes'
        : 'In progress';

    // Count unique exercises
    final exerciseCount = sets.map((s) => s.exerciseId).toSet().length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.workoutName ?? 'Quick Workout',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '$timeStr • $durationStr',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(theme, '${sets.length}', 'Sets'),
                _buildStatItem(theme, '$exerciseCount', 'Exercises'),
                _buildStatItem(theme, _calculateTotalVolume(sets), 'Total Vol'),
              ],
            ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Notes',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(session.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _calculateTotalVolume(List<SessionSet> sets) {
    double total = 0;
    for (final set in sets) {
      if (set.weight != null && set.reps != null) {
        total += set.weight! * set.reps!;
      }
    }
    if (total >= 1000) {
      return '${(total / 1000).toStringAsFixed(1)}k';
    }
    return total.toStringAsFixed(0);
  }

  Widget _buildExerciseGroup(
    ThemeData theme,
    String exerciseName,
    List<SessionSet> sets,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              exerciseName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          // Sets list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sets.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final set = sets[index];
              return _buildSetTile(theme, set);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSetTile(ThemeData theme, SessionSet set) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          '${set.setNumber}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(set.formattedSet),
      subtitle: set.notes != null ? Text(set.notes!) : null,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'edit') {
            _showEditSetDialog(set);
          } else if (value == 'delete') {
            _confirmDeleteSet(set);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSetDialog(SessionSet set) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SetInputDialog(
        title: 'Edit Set ${set.setNumber}',
        initialWeight: set.weight,
        initialReps: set.reps,
      ),
    );

    if (result != null && mounted) {
      final updatedSet = set.copyWith(
        weight: result['weight'] as double,
        reps: result['reps'] as int,
      );
      await context.read<HistoryProvider>().updateSet(updatedSet);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set updated')),
      );
    }
  }

  Future<void> _confirmDeleteSet(SessionSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text('Delete Set ${set.setNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<HistoryProvider>().deleteSet(set.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set deleted')),
      );
    }
  }
}
