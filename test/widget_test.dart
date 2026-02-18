// Basic widget test for the Workout Tracker app.

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/main.dart';

void main() {
  testWidgets('App starts and shows profile selection', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WorkoutTrackerApp());

    // Wait for the app to settle.
    await tester.pumpAndSettle();

    // Verify that the profile selection screen shows.
    expect(find.text('Workout Tracker'), findsOneWidget);
  });
}
