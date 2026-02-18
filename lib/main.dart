import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';

/// Named routes for navigation.
class Routes {
  static const String profileSelection = '/';
  static const String home = '/home';
  static const String activeWorkout = '/active_workout';
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
        },
      ),
    );
  }
}
