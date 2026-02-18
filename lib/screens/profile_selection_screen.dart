import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'home_screen.dart';

/// Screen for selecting or creating a user profile.
class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Load profiles when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfiles();
    });
  }

  Future<void> _createProfile() async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      final profileProvider = context.read<ProfileProvider>();
      final profile = await profileProvider.createProfile(name);
      await _selectProfile(profile);
    }
  }

  Future<void> _selectProfile(Profile profile) async {
    final profileProvider = context.read<ProfileProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();
    final workoutProvider = context.read<WorkoutProvider>();
    final sessionProvider = context.read<SessionProvider>();

    await profileProvider.setActiveProfile(profile);
    if (!mounted) return;

    // Load data for the selected profile
    await exerciseProvider.loadExercises(profile.id);
    if (!mounted) return;

    await workoutProvider.loadWorkouts(profile.id);
    if (!mounted) return;

    await sessionProvider.loadSessions(profile.id);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profiles = profileProvider.profiles;

          if (profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Workout Tracker!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Create a profile to get started'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createProfile,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select a profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(profile.name),
                        subtitle: profile.lastActiveAt != null
                            ? Text(
                                'Last active: ${_formatDate(profile.lastActiveAt!)}')
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectProfile(profile),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.profiles.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: _createProfile,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
