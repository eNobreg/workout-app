import 'package:flutter/material.dart';
import '../models/models.dart';
import 'set_input_card.dart';

/// A card widget for logging sets for a single exercise during a workout.
/// Shows exercise name, logged sets, and allows adding/editing/deleting sets.
class ExerciseLogCard extends StatefulWidget {
  /// The exercise being logged.
  final Exercise exercise;

  /// Default number of sets for this exercise in the workout.
  final int defaultSets;

  /// List of already logged sets for this exercise.
  final List<SessionSet> loggedSets;

  /// Callback when a new set is added.
  final void Function(double weight, int reps) onAddSet;

  /// Callback when a set is updated.
  final void Function(SessionSet set, double weight, int reps) onUpdateSet;

  /// Callback when a set is deleted.
  final void Function(SessionSet set) onDeleteSet;

  const ExerciseLogCard({
    super.key,
    required this.exercise,
    this.defaultSets = 3,
    required this.loggedSets,
    required this.onAddSet,
    required this.onUpdateSet,
    required this.onDeleteSet,
  });

  @override
  State<ExerciseLogCard> createState() => _ExerciseLogCardState();
}

class _ExerciseLogCardState extends State<ExerciseLogCard> {
  bool _isExpanded = true;
  bool _isAddingSet = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedSets = widget.loggedSets.length;
    final totalSets = widget.defaultSets;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedSets / $totalSets sets',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: completedSets >= totalSets
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: totalSets > 0 ? completedSets / totalSets : 0,
                          strokeWidth: 3,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            const Divider(height: 1),
            
            // Logged sets list
            if (widget.loggedSets.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.loggedSets.length,
                itemBuilder: (context, index) {
                  final set = widget.loggedSets[index];
                  return _SetListTile(
                    set: set,
                    onEdit: () => _showEditSetDialog(set),
                    onDelete: () => _confirmDeleteSet(set),
                  );
                },
              ),

            // Add set section
            if (_isAddingSet)
              Padding(
                padding: const EdgeInsets.all(12),
                child: SetInputCard(
                  initialWeight: widget.loggedSets.isNotEmpty
                      ? (widget.loggedSets.last.weight ?? widget.exercise.defaultWeight)
                      : widget.exercise.defaultWeight,
                  initialReps: widget.loggedSets.isNotEmpty
                      ? (widget.loggedSets.last.reps ?? widget.exercise.defaultReps)
                      : widget.exercise.defaultReps,
                  saveButtonText: 'Add Set',
                  showCancelButton: true,
                  onSave: (weight, reps) {
                    widget.onAddSet(weight, reps);
                    setState(() => _isAddingSet = false);
                  },
                  onCancel: () => setState(() => _isAddingSet = false),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isAddingSet = true),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Set'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
          ],
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

    if (result != null) {
      widget.onUpdateSet(
        set,
        result['weight'] as double,
        result['reps'] as int,
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

    if (confirmed == true) {
      widget.onDeleteSet(set);
    }
  }
}

/// A list tile showing a single logged set with edit/delete actions.
class _SetListTile extends StatelessWidget {
  final SessionSet set;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SetListTile({
    required this.set,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      title: Text(
        set.formattedSet,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            tooltip: 'Edit set',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: theme.colorScheme.error,
            ),
            onPressed: onDelete,
            tooltip: 'Delete set',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
