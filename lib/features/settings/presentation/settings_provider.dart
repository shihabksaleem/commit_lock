import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final Map<String, bool> blockedCategories;

  AppSettings({
    required this.themeMode,
    required this.soundEnabled,
    required this.notificationsEnabled,
    required this.blockedCategories,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? notificationsEnabled,
    Map<String, bool>? blockedCategories,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      blockedCategories: blockedCategories ?? this.blockedCategories,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(AppSettings(
          themeMode: ThemeMode.system,
          soundEnabled: true,
          notificationsEnabled: true,
          blockedCategories: {
            for (var cat in AppConstants.blockedCategories) cat: false,
          },
        )) {
    _loadSettings();
  }

  late Box _settingsBox;

  Future<void> _loadSettings() async {
    _settingsBox = Hive.box(AppConstants.settingsBox);
    
    final themeIndex = _settingsBox.get('themeMode', defaultValue: 0);
    final sound = _settingsBox.get('soundEnabled', defaultValue: true);
    final notifications = _settingsBox.get('notificationsEnabled', defaultValue: true);
    final blockedRaw = _settingsBox.get('blockedCategories', defaultValue: {});
    final blocked = Map<String, bool>.from(blockedRaw);

    state = AppSettings(
      themeMode: ThemeMode.values[themeIndex],
      soundEnabled: sound,
      notificationsEnabled: notifications,
      blockedCategories: blocked.isEmpty 
          ? {for (var cat in AppConstants.blockedCategories) cat: false}
          : blocked,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _settingsBox.put('themeMode', mode.index);
  }

  void toggleSound(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    _settingsBox.put('soundEnabled', enabled);
  }

  void toggleNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    _settingsBox.put('notificationsEnabled', enabled);
  }

  void toggleBlockedCategory(String category, bool enabled) {
    final newBlocked = Map<String, bool>.from(state.blockedCategories);
    newBlocked[category] = enabled;
    state = state.copyWith(blockedCategories: newBlocked);
    _settingsBox.put('blockedCategories', newBlocked);
  }
}
