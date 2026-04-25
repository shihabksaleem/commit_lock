import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSection('Account', [
            FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final prefs = snapshot.data!;
                final name = prefs.getString(AppConstants.userNameKey) ?? 'Achiever';
                final email = prefs.getString(AppConstants.userEmailKey) ?? '';
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () => _showLogoutConfirm(context),
                  ),
                );
              },
            ),
          ]),
          _buildSection('Data Management', [
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Clear All History', style: TextStyle(color: Colors.redAccent)),
              onTap: () => _showClearConfirm(context),
            ),
          ]),
          _buildSection('Appearance', [
            ListTile(
              title: const Text('Theme Mode'),
              subtitle: Text(settings.themeMode.name[0].toUpperCase() + settings.themeMode.name.substring(1)),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                onChanged: (mode) => notifier.setThemeMode(mode!),
                items: ThemeMode.values.map((mode) {
                  final label = mode.name[0].toUpperCase() + mode.name.substring(1);
                  return DropdownMenuItem(value: mode, child: Text(label));
                }).toList(),
              ),
            ),
          ]),
          _buildSection('Notifications & Sound', [
            SwitchListTile(
              title: const Text('Completion Notifications'),
              value: settings.notificationsEnabled,
              onChanged: notifier.toggleNotifications,
            ),
            SwitchListTile(
              title: const Text('Sound Effects'),
              value: settings.soundEnabled,
              onChanged: notifier.toggleSound,
            ),
          ]),
          _buildSection('Mock Blocked Categories', [
            ...AppConstants.blockedCategories.map((cat) {
              return SwitchListTile(
                title: Text(cat),
                value: settings.blockedCategories[cat] ?? false,
                onChanged: (val) => notifier.toggleBlockedCategory(cat, val),
              );
            }),
          ]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: AppTheme.primaryColor.withOpacity(0.05),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.1)),
              ),
              child: const AboutListTile(
                applicationName: 'CommitLock',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.lock, color: AppTheme.primaryColor),
                aboutBoxChildren: [
                  Text('CommitLock is designed to help you build focus habits by locking your commitments.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        ...children,
      ],
    );
  }

  Future<void> _showLogoutConfirm(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout? you will need to sign in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _showClearConfirm(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('This will delete all your session history and streaks. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CLEAR ALL', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Hive.box(AppConstants.sessionsBox).clear();
      await Hive.box(AppConstants.userStatsBox).clear();
    }
  }
}
