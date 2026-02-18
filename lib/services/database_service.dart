import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

/// Database service for the workout tracker app.
/// Handles all SQLite database operations using sqflite.
class DatabaseService {
  static const String _databaseName = 'workout_tracker.db';
  static const int _databaseVersion = 1;

  // Singleton instance
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._();

  /// Returns the singleton instance of DatabaseService.
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Returns the database instance, initializing it if necessary.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initializes the database.
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates all database tables.
  Future<void> _onCreate(Database db, int version) async {
    // Profiles table
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_active_at TEXT
      )
    ''');

    // Exercises table
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Workouts table (workout templates)
    await db.execute('''
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Workout exercises table (exercises in workout templates)
    await db.execute('''
      CREATE TABLE workout_exercises (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        default_sets INTEGER NOT NULL DEFAULT 3,
        default_reps INTEGER,
        default_weight REAL,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    // Rotation schedules table
    await db.execute('''
      CREATE TABLE rotation_schedules (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Rotation days table
    await db.execute('''
      CREATE TABLE rotation_days (
        id TEXT PRIMARY KEY,
        schedule_id TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        workout_id TEXT,
        is_rest_day INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (schedule_id) REFERENCES rotation_schedules (id) ON DELETE CASCADE,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE SET NULL
      )
    ''');

    // Workout sessions table (logged workouts)
    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        workout_id TEXT,
        workout_name TEXT,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        notes TEXT,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE SET NULL
      )
    ''');

    // Session sets table (logged sets)
    await db.execute('''
      CREATE TABLE session_sets (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT,
        set_number INTEGER NOT NULL,
        weight REAL,
        reps INTEGER,
        logged_at TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX idx_exercises_profile ON exercises (profile_id)');
    await db.execute(
        'CREATE INDEX idx_workouts_profile ON workouts (profile_id)');
    await db.execute(
        'CREATE INDEX idx_workout_exercises_workout ON workout_exercises (workout_id)');
    await db.execute(
        'CREATE INDEX idx_rotation_schedules_profile ON rotation_schedules (profile_id)');
    await db.execute(
        'CREATE INDEX idx_rotation_days_schedule ON rotation_days (schedule_id)');
    await db.execute(
        'CREATE INDEX idx_workout_sessions_profile ON workout_sessions (profile_id)');
    await db.execute(
        'CREATE INDEX idx_workout_sessions_date ON workout_sessions (started_at)');
    await db.execute(
        'CREATE INDEX idx_session_sets_session ON session_sets (session_id)');
    await db.execute(
        'CREATE INDEX idx_session_sets_exercise ON session_sets (exercise_id)');
  }

  /// Handles database upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  // ============== Profile Operations ==============

  /// Inserts a new profile.
  Future<void> insertProfile(Profile profile) async {
    final db = await database;
    await db.insert('profiles', profile.toMap());
  }

  /// Gets all profiles.
  Future<List<Profile>> getProfiles() async {
    final db = await database;
    final maps = await db.query('profiles', orderBy: 'name ASC');
    return maps.map((map) => Profile.fromMap(map)).toList();
  }

  /// Gets a profile by ID.
  Future<Profile?> getProfile(String id) async {
    final db = await database;
    final maps = await db.query('profiles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Profile.fromMap(maps.first);
  }

  /// Updates a profile.
  Future<void> updateProfile(Profile profile) async {
    final db = await database;
    await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Deletes a profile and all associated data.
  Future<void> deleteProfile(String id) async {
    final db = await database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }

  // ============== Exercise Operations ==============

  /// Inserts a new exercise.
  Future<void> insertExercise(Exercise exercise) async {
    final db = await database;
    await db.insert('exercises', exercise.toMap());
  }

  /// Gets all exercises for a profile.
  Future<List<Exercise>> getExercises(String profileId) async {
    final db = await database;
    final maps = await db.query(
      'exercises',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  /// Gets an exercise by ID.
  Future<Exercise?> getExercise(String id) async {
    final db = await database;
    final maps = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  /// Updates an exercise.
  Future<void> updateExercise(Exercise exercise) async {
    final db = await database;
    await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  /// Deletes an exercise.
  Future<void> deleteExercise(String id) async {
    final db = await database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ============== Workout Operations ==============

  /// Inserts a new workout.
  Future<void> insertWorkout(Workout workout) async {
    final db = await database;
    await db.insert('workouts', workout.toMap());
  }

  /// Gets all workouts for a profile.
  Future<List<Workout>> getWorkouts(String profileId) async {
    final db = await database;
    final maps = await db.query(
      'workouts',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'sort_order ASC, name ASC',
    );
    return maps.map((map) => Workout.fromMap(map)).toList();
  }

  /// Gets a workout by ID.
  Future<Workout?> getWorkout(String id) async {
    final db = await database;
    final maps = await db.query('workouts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Workout.fromMap(maps.first);
  }

  /// Updates a workout.
  Future<void> updateWorkout(Workout workout) async {
    final db = await database;
    await db.update(
      'workouts',
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  /// Deletes a workout.
  Future<void> deleteWorkout(String id) async {
    final db = await database;
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  // ============== Workout Exercise Operations ==============

  /// Inserts a workout exercise.
  Future<void> insertWorkoutExercise(WorkoutExercise workoutExercise) async {
    final db = await database;
    await db.insert('workout_exercises', workoutExercise.toMap());
  }

  /// Gets all exercises for a workout.
  Future<List<WorkoutExercise>> getWorkoutExercises(String workoutId) async {
    final db = await database;
    final maps = await db.query(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((map) => WorkoutExercise.fromMap(map)).toList();
  }

  /// Updates a workout exercise.
  Future<void> updateWorkoutExercise(WorkoutExercise workoutExercise) async {
    final db = await database;
    await db.update(
      'workout_exercises',
      workoutExercise.toMap(),
      where: 'id = ?',
      whereArgs: [workoutExercise.id],
    );
  }

  /// Deletes a workout exercise.
  Future<void> deleteWorkoutExercise(String id) async {
    final db = await database;
    await db.delete('workout_exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ============== Rotation Schedule Operations ==============

  /// Inserts a rotation schedule with its days.
  Future<void> insertRotationSchedule(RotationSchedule schedule) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('rotation_schedules', schedule.toMap());
      for (final day in schedule.days) {
        await txn.insert('rotation_days', day.toMap());
      }
    });
  }

  /// Gets all rotation schedules for a profile.
  Future<List<RotationSchedule>> getRotationSchedules(String profileId) async {
    final db = await database;
    final scheduleMaps = await db.query(
      'rotation_schedules',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'created_at DESC',
    );

    final schedules = <RotationSchedule>[];
    for (final map in scheduleMaps) {
      final dayMaps = await db.query(
        'rotation_days',
        where: 'schedule_id = ?',
        whereArgs: [map['id']],
        orderBy: 'day_number ASC',
      );
      final days = dayMaps.map((d) => RotationDay.fromMap(d)).toList();
      schedules.add(RotationSchedule.fromMap(map, days: days));
    }
    return schedules;
  }

  /// Gets the active rotation schedule for a profile.
  Future<RotationSchedule?> getActiveRotationSchedule(String profileId) async {
    final db = await database;
    final maps = await db.query(
      'rotation_schedules',
      where: 'profile_id = ? AND is_active = 1',
      whereArgs: [profileId],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final dayMaps = await db.query(
      'rotation_days',
      where: 'schedule_id = ?',
      whereArgs: [maps.first['id']],
      orderBy: 'day_number ASC',
    );
    final days = dayMaps.map((d) => RotationDay.fromMap(d)).toList();
    return RotationSchedule.fromMap(maps.first, days: days);
  }

  /// Updates a rotation schedule.
  Future<void> updateRotationSchedule(RotationSchedule schedule) async {
    final db = await database;
    await db.update(
      'rotation_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  /// Deletes a rotation schedule.
  Future<void> deleteRotationSchedule(String id) async {
    final db = await database;
    await db.delete('rotation_schedules', where: 'id = ?', whereArgs: [id]);
  }

  // ============== Workout Session Operations ==============

  /// Inserts a workout session.
  Future<void> insertWorkoutSession(WorkoutSession session) async {
    final db = await database;
    await db.insert('workout_sessions', session.toMap());
  }

  /// Gets all workout sessions for a profile.
  Future<List<WorkoutSession>> getWorkoutSessions(String profileId) async {
    final db = await database;
    final maps = await db.query(
      'workout_sessions',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  /// Gets workout sessions for a profile within a date range.
  Future<List<WorkoutSession>> getWorkoutSessionsInRange(
    String profileId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'workout_sessions',
      where: 'profile_id = ? AND started_at >= ? AND started_at <= ?',
      whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  /// Gets a workout session by ID.
  Future<WorkoutSession?> getWorkoutSession(String id) async {
    final db = await database;
    final maps =
        await db.query('workout_sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return WorkoutSession.fromMap(maps.first);
  }

  /// Updates a workout session.
  Future<void> updateWorkoutSession(WorkoutSession session) async {
    final db = await database;
    await db.update(
      'workout_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Deletes a workout session.
  Future<void> deleteWorkoutSession(String id) async {
    final db = await database;
    await db.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // ============== Session Set Operations ==============

  /// Inserts a session set.
  Future<void> insertSessionSet(SessionSet set) async {
    final db = await database;
    await db.insert('session_sets', set.toMap());
  }

  /// Gets all sets for a session.
  Future<List<SessionSet>> getSessionSets(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      'session_sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'exercise_id ASC, set_number ASC',
    );
    return maps.map((map) => SessionSet.fromMap(map)).toList();
  }

  /// Gets all sets for an exercise across all sessions (for history/graphs).
  Future<List<SessionSet>> getExerciseHistory(String exerciseId) async {
    final db = await database;
    final maps = await db.query(
      'session_sets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'logged_at ASC',
    );
    return maps.map((map) => SessionSet.fromMap(map)).toList();
  }

  /// Updates a session set.
  Future<void> updateSessionSet(SessionSet set) async {
    final db = await database;
    await db.update(
      'session_sets',
      set.toMap(),
      where: 'id = ?',
      whereArgs: [set.id],
    );
  }

  /// Deletes a session set.
  Future<void> deleteSessionSet(String id) async {
    final db = await database;
    await db.delete('session_sets', where: 'id = ?', whereArgs: [id]);
  }

  // ============== Utility Operations ==============

  /// Closes the database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Deletes all data (for testing/reset purposes).
  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('session_sets');
    await db.delete('workout_sessions');
    await db.delete('rotation_days');
    await db.delete('rotation_schedules');
    await db.delete('workout_exercises');
    await db.delete('workouts');
    await db.delete('exercises');
    await db.delete('profiles');
  }
}
