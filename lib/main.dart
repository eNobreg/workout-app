import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/providers.dart';
import 'providers/history_provider.dart';
import 'screens/screens.dart';

/// Named routes for navigation.
class Routes {
  static const String profileSelection = '/';
  static const String home = '/home';
  static const String activeWorkout = '/active_workout';
  static const String rotationSetup = '/rotation_setup';
  static const String workoutHistory = '/workout_history';
  static const String sessionDetails = '/session_details';
  static const String exerciseHistory = '/exercise_history';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WorkoutTrackerApp());
}

/// The root widget of the Workout Tracker application.
class WorkoutTrackerApp extends StatelessWidget {
  const WorkoutTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => RotationProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
      ],
      child: MaterialApp(
        title: 'Workout Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: Routes.profileSelection,
        routes: {
          Routes.profileSelection: (_) => const ProfileSelectionScreen(),
          Routes.home: (_) => const HomeScreen(),
          Routes.activeWorkout: (_) => const ActiveWorkoutScreen(),
          Routes.rotationSetup: (_) => const RotationSetupScreen(),
          Routes.workoutHistory: (_) => const WorkoutHistoryScreen(),
        },
      ),
    );
  }
}
