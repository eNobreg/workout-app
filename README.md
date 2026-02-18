# The Simple Workout Tracker

A simple, local-first workout tracking app for gym-goers following structured workout rotations (Push/Pull/Legs, etc.).

## Core Features
- **Multi-user profiles** (local device only)
- **Custom workouts & exercises** (no predefined database)
- **Rotation scheduling** (flexible X-day cycles with rest days)
- **Set logging** (weight + reps per set, log in any order)
- **Exercise history graphs** (weight & reps over time, overlay capability)
- **Workout history** (calendar view of all sessions)
- **Edit/delete** past workout data

## Tech Stack
- **Flutter** (Dart) - Cross-platform framework
- **sqflite** - Local SQLite database
- **provider** - State management
- **fl_chart** - Progress visualization
- **iOS-first**, then Android

## Project Status
✅ Phase 1: Foundation & Setup - **Complete**
🚧 Phase 2: Core Functionality - In Progress

## Project Structure
```
lib/
├── main.dart              # App entry point
├── app_theme.dart         # Theme configuration
├── models/                # Data models
│   ├── profile.dart       # User profiles
│   ├── exercise.dart      # Custom exercises
│   ├── workout.dart       # Workout templates
│   ├── workout_exercise.dart
│   ├── rotation_schedule.dart
│   ├── workout_session.dart
│   └── session_set.dart   # Logged sets
├── services/              # Database & services
│   └── database_service.dart
├── providers/             # State management
│   ├── profile_provider.dart
│   ├── exercise_provider.dart
│   ├── workout_provider.dart
│   └── session_provider.dart
├── screens/               # UI screens
│   ├── home_screen.dart
│   └── profile_selection_screen.dart
└── widgets/               # Reusable widgets
```

## Documentation
- [Technical Plan](https://app.warp.dev) - Detailed architecture and implementation plan
- [Linear Project](https://linear.app/humdub/project/the-simple-workout-tracker-c9b59f36e2d5) - Project management and tasks

## Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd workout-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```
