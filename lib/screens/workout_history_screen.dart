import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../providers/history_provider.dart';
import '../widgets/workout_calendar.dart';
import 'session_details_screen.dart';

/// View mode for the history screen.
enum HistoryViewMode { calendar, list }

/// Screen displaying workout history with calendar or list view.
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  HistoryViewMode _viewMode = HistoryViewMode.calendar;
  DateTime? _selectedDate;
  List<WorkoutSession> _selectedDaySessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profileId = context.read<ProfileProvider>().activeProfile?.id;
    if (profileId != null) {
      await context.read<HistoryProvider>().loadAllSessions(profileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          // View toggle button
          SegmentedButton<HistoryViewMode>(
            segments: const [
              ButtonSegment(
                value: HistoryViewMode.calendar,
                icon: Icon(Icons.calendar_month),
                label: Text('Calendar'),
              ),
              ButtonSegment(
                value: HistoryViewMode.list,
                icon: Icon(Icons.list),
                label: Text('List'),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (selection) {
              setState(() {
                _viewMode = selection.first;
              });
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = historyProvider.completedSessions;

          if (sessions.isEmpty) {
            return _buildEmptyState(theme);
          }

          return _viewMode == HistoryViewMode.calendar
              ? _buildCalendarView(theme, sessions, historyProvider)
              : _buildListView(theme, sessions, historyProvider);
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
            Icons.history,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No workout history yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a workout to see it here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(
    ThemeData theme,
    List<WorkoutSession> sessions,
    HistoryProvider historyProvider,
  ) {
    // Build map of dates to sessions
    final workoutsByDate = <DateTime, List<WorkoutSession>>{};
    for (final session in sessions) {
      final date = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      workoutsByDate.putIfAbsent(date, () => []);
      workoutsByDate[date]!.add(session);
    }

    return Column(
      children: [
        WorkoutCalendar(
          workoutsByDate: workoutsByDate,
          selectedDay: _selectedDate,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
              _selectedDaySessions = historyProvider.getSessionsForDate(selectedDay);
            });
          },
        ),
        const Divider(),
        Expanded(
          child: _buildSelectedDaySessions(theme),
        ),
      ],
    );
  }

  Widget _buildSelectedDaySessions(ThemeData theme) {
    if (_selectedDate == null) {
      return Center(
        child: Text(
          'Select a date to view workouts',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (_selectedDaySessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No workouts on ${DateFormat('MMM d, yyyy').format(_selectedDate!)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedDaySessions.length,
      itemBuilder: (context, index) {
        final session = _selectedDaySessions[index];
        return _buildSessionCard(theme, session);
      },
    );
  }

  Widget _buildListView(
    ThemeData theme,
    List<WorkoutSession> sessions,
    HistoryProvider historyProvider,
  ) {
    // Group sessions by date
    final groupedSessions = <String, List<WorkoutSession>>{};
    for (final session in sessions) {
      final dateKey = _formatDateHeader(session.startedAt);
      groupedSessions.putIfAbsent(dateKey, () => []);
      groupedSessions[dateKey]!.add(session);
    }

    final dateKeys = groupedSessions.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final daySessions = groupedSessions[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                dateKey,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...daySessions.map((session) => _buildSessionCard(theme, session)),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(ThemeData theme, WorkoutSession session) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) => _confirmDelete(session),
      onDismissed: (direction) => _deleteSession(session),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.fitness_center,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(session.workoutName ?? 'Quick Workout'),
          subtitle: Text(_formatSessionSubtitle(session)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToSessionDetails(session),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(sessionDate).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatSessionSubtitle(WorkoutSession session) {
    final time = DateFormat('h:mm a').format(session.startedAt);
    final duration = session.duration;
    if (duration != null) {
      final minutes = duration.inMinutes;
      return '$time • ${minutes}min';
    }
    return time;
  }

  Future<bool> _confirmDelete(WorkoutSession session) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: Text(
          'Are you sure you want to delete "${session.workoutName ?? 'Quick Workout'}"?\n\nThis will also delete all logged sets.',
        ),
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
    ) ?? false;
  }

  Future<void> _deleteSession(WorkoutSession session) async {
    await context.read<HistoryProvider>().deleteSession(session.id);
    // Also update session provider if needed
    await context.read<SessionProvider>().deleteSession(session.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${session.workoutName ?? 'Quick Workout'}"'),
        ),
      );
    }
  }

  void _navigateToSessionDetails(WorkoutSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionDetailsScreen(sessionId: session.id),
      ),
    );
  }
}
