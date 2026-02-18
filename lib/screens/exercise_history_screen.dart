import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../providers/history_provider.dart';
import '../widgets/progress_chart.dart';
import '../widgets/set_input_card.dart';

/// Screen displaying exercise history with progress charts.
class ExerciseHistoryScreen extends StatefulWidget {
  /// The exercise to display history for.
  final Exercise exercise;

  const ExerciseHistoryScreen({
    super.key,
    required this.exercise,
  });

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final profileId = context.read<ProfileProvider>().activeProfile?.id;
    if (profileId != null) {
      await context.read<HistoryProvider>().getExerciseHistory(
            profileId,
            widget.exercise.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weight'),
            Tab(text: 'Reps'),
          ],
        ),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sets = historyProvider.exerciseHistory;

          if (sets.isEmpty) {
            return _buildEmptyState(theme);
          }

          return Column(
            children: [
              // Overlay toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _showOverlay,
                      onChanged: (value) {
                        setState(() {
                          _showOverlay = value ?? false;
                        });
                      },
                    ),
                    Text(
                      'Overlay both',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${sets.length} sets total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Chart
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChartTab(theme, sets, ChartDataType.weight),
                    _buildChartTab(theme, sets, ChartDataType.reps),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some sets for ${widget.exercise.name}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(
    ThemeData theme,
    List<SessionSet> sets,
    ChartDataType dataType,
  ) {
    return Column(
      children: [
        // Progress chart
        ProgressChart(
          sets: sets,
          title: dataType == ChartDataType.weight
              ? 'Weight Progress'
              : 'Reps Progress',
          yAxisLabel: dataType == ChartDataType.weight ? 'lbs' : 'reps',
          dataType: dataType,
          showOverlay: _showOverlay,
          onPointTap: (set) => _showSetDetails(set),
        ),

        const Divider(),

        // Sets history list
        Expanded(
          child: _buildSetsList(theme, sets),
        ),
      ],
    );
  }

  Widget _buildSetsList(ThemeData theme, List<SessionSet> sets) {
    // Sort by date (most recent first)
    final sortedSets = List<SessionSet>.from(sets)
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSets.length,
      itemBuilder: (context, index) {
        final set = sortedSets[index];
        return _buildSetListItem(theme, set);
      },
    );
  }

  Widget _buildSetListItem(ThemeData theme, SessionSet set) {
    final dateStr = DateFormat('MMM d, yyyy').format(set.loggedAt);
    final timeStr = DateFormat('h:mm a').format(set.loggedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '${set.setNumber}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          set.formattedSet,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$dateStr at $timeStr',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
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
        onTap: () => _showSetDetails(set),
      ),
    );
  }

  void _showSetDetails(SessionSet set) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(set.loggedAt);
    final timeStr = DateFormat('h:mm a').format(set.loggedAt);

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set ${set.setNumber}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(theme, 'Date', dateStr),
            _buildDetailRow(theme, 'Time', timeStr),
            _buildDetailRow(
              theme,
              'Weight',
              set.weight != null ? '${set.weight} lbs' : 'Not recorded',
            ),
            _buildDetailRow(
              theme,
              'Reps',
              set.reps != null ? '${set.reps}' : 'Not recorded',
            ),
            if (set.notes != null) _buildDetailRow(theme, 'Notes', set.notes!),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditSetDialog(set);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteSet(set);
                  },
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
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
