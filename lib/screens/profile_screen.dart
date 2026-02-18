import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/providers.dart';
import '../providers/history_provider.dart';

/// Profile and settings screen.
/// Allows editing profile name, switching users, and managing data.
class ProfileScreen extends StatefulWidget {
  /// If true, shows the app bar. Set to false when embedded in another scaffold.
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().activeProfile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final profile = context.read<ProfileProvider>().activeProfile;
    final hasChanges = _nameController.text.trim() != (profile?.name ?? '');
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  /// Validates the profile name.
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length > 100) {
      return 'Name must be 100 characters or less';
    }
    return null;
  }

  /// Saves the updated profile name.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final profileProvider = context.read<ProfileProvider>();
      final currentProfile = profileProvider.activeProfile;

      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          name: _nameController.text.trim(),
        );
        await profileProvider.updateProfile(updatedProfile);

        if (mounted) {
          setState(() => _hasChanges = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Switches to a different user profile.
  Future<void> _switchUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Switch User'),
        content: const Text(
          'You will be taken to the profile selection screen. '
          'Any unsaved changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );

      try {
        // Clear all provider data
        context.read<ExerciseProvider>().clear();
        context.read<WorkoutProvider>().clear();
        context.read<SessionProvider>().clear();
        context.read<RotationProvider>().clear();
        context.read<HistoryProvider>().clear();
        context.read<TemplateProvider>().clear();
        await context.read<ProfileProvider>().setActiveProfile(null);

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pushReplacementNamed(Routes.profileSelection);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error switching user: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Deletes all data with confirmation.
  Future<void> _deleteAllData() async {
    final profile = context.read<ProfileProvider>().activeProfile;
    if (profile == null) return;

    // First confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete ALL your workout data, exercises, '
          'and history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return;

    // Second confirmation with profile name
    final nameController = TextEditingController();
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To confirm, type your profile name: "${profile.name}"',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Profile name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim() == profile.name) {
                Navigator.pop(dialogContext, true);
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Profile name does not match'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    nameController.dispose();

    if (secondConfirm != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting all data...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Delete profile (cascades to all related data)
      await context.read<ProfileProvider>().deleteProfile(profile.id);

      // Clear all provider data
      context.read<ExerciseProvider>().clear();
      context.read<WorkoutProvider>().clear();
      context.read<SessionProvider>().clear();
      context.read<RotationProvider>().clear();
      context.read<HistoryProvider>().clear();
      context.read<TemplateProvider>().clear();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushReplacementNamed(Routes.profileSelection);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting data: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    final theme = Theme.of(context);

    if (profile == null) {
      if (widget.showAppBar) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: const Center(child: Text('No profile selected')),
        );
      }
      return const Center(child: Text('No profile selected'));
    }

    final body = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile avatar and name section
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name edit section
              Text(
                'Profile Name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: _validateName,
                maxLength: 100,
              ),
              const SizedBox(height: 8),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _hasChanges && !_isSaving ? _saveProfile : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                ),
              ),
              const SizedBox(height: 32),

              // Account section
              Text(
                'Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.swap_horiz),
                      title: const Text('Switch User'),
                      subtitle: const Text('Sign in with a different profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _switchUser,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Delete All Data',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      subtitle: const Text('Permanently delete this profile'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.error,
                      ),
                      onTap: _deleteAllData,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Profile info section
              Text(
                'Profile Info',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Profile ID',
                        value: profile.id.substring(0, 8) + '...',
                      ),
                      const Divider(),
                      _InfoRow(
                        label: 'Created',
                        value: _formatDate(profile.createdAt),
                      ),
                      if (profile.lastActiveAt != null) ...[
                        const Divider(),
                        _InfoRow(
                          label: 'Last Active',
                          value: _formatDate(profile.lastActiveAt!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // App info section
              Text(
                'About',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'App Name',
                        value: 'Workout Tracker',
                      ),
                      const Divider(),
                      _InfoRow(
                        label: 'Version',
                        value: '1.0.0',
                      ),
                      const Divider(),
                      _InfoRow(
                        label: 'Build',
                        value: '1',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Center(
                child: Text(
                  'Made with ❤️ for fitness enthusiasts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile & Settings'),
        ),
        body: body,
      );
    }

    return body;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// A simple row widget for displaying label-value pairs.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
