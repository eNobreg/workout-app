import 'package:flutter/material.dart';

/// A grid box representing a single day in the rotation.
class RotationDayGridBox extends StatelessWidget {
  final int dayNumber;
  final bool isRestDay;
  final String? workoutName;
  final VoidCallback onTap;
  final bool isCurrent;

  const RotationDayGridBox({
    super.key,
    required this.dayNumber,
    required this.isRestDay,
    this.workoutName,
    required this.onTap,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isRestDay
        ? colorScheme.secondaryContainer
        : colorScheme.primaryContainer;
    final textColor = isRestDay
        ? colorScheme.onSecondaryContainer
        : colorScheme.onPrimaryContainer;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isCurrent ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isCurrent
              ? BorderSide(color: colorScheme.tertiary, width: 3)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Day ${dayNumber.toString()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  isRestDay ? 'Rest' : (workoutName ?? 'Workout'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontStyle: workoutName == null && !isRestDay
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
