import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';

/// A calendar widget that displays workout history.
/// Marks dates with completed workouts and allows date selection.
class WorkoutCalendar extends StatefulWidget {
  /// Map of dates to workout sessions.
  final Map<DateTime, List<WorkoutSession>> workoutsByDate;

  /// Currently selected date.
  final DateTime? selectedDay;

  /// Callback when a date is selected.
  final void Function(DateTime selectedDay, DateTime focusedDay)? onDaySelected;

  /// Callback when the visible month changes.
  final void Function(DateTime focusedDay)? onPageChanged;

  const WorkoutCalendar({
    super.key,
    required this.workoutsByDate,
    this.selectedDay,
    this.onDaySelected,
    this.onPageChanged,
  });

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = widget.selectedDay;
  }

  @override
  void didUpdateWidget(WorkoutCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDay != oldWidget.selectedDay) {
      _selectedDay = widget.selectedDay;
    }
  }

  /// Normalizes a date to midnight for comparison.
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gets workouts for a specific day.
  List<WorkoutSession> _getWorkoutsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    return widget.workoutsByDate[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TableCalendar<WorkoutSession>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: _getWorkoutsForDay,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: theme.colorScheme.primary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.primary,
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        markerDecoration: BoxDecoration(
          color: theme.colorScheme.tertiary,
          shape: BoxShape.circle,
        ),
        markerSize: 6,
        markersMaxCount: 3,
        markersAnchor: 0.7,
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: theme.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        weekendStyle: theme.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        widget.onDaySelected?.call(selectedDay, focusedDay);
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        widget.onPageChanged?.call(focusedDay);
      },
    );
  }
}
