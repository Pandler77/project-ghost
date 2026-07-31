import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_theme_mode.dart';
import '../models/home_layout.dart';
import '../models/home_section.dart';

class SettingsService {
  static const String _themeModeKey = 'theme_mode';
  static const String _homeLayoutKey = 'home_layout';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<AppThemeMode> getThemeMode() async {
    final savedValue = await _preferences.getString(_themeModeKey);

    return switch (savedValue) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  Future<void> saveThemeMode(AppThemeMode themeMode) async {
    await _preferences.setString(_themeModeKey, themeMode.name);
  }

  Future<HomeLayout> getHomeLayout() async {
    final savedValues = await _preferences.getStringList(_homeLayoutKey);

    if (savedValues == null || savedValues.isEmpty) {
      return HomeLayout.defaultLayout;
    }

    final sections = savedValues
        .map(HomeSectionDetails.fromStorageValue)
        .whereType<HomeSection>()
        .toList();

    if (sections.isEmpty) {
      return HomeLayout.defaultLayout;
    }

    return HomeLayout(visibleSections: sections);
  }

  Future<void> saveHomeLayout(HomeLayout layout) async {
    final values = layout.visibleSections
        .map((section) => section.storageValue)
        .toList();

    await _preferences.setStringList(_homeLayoutKey, values);
  }

  Future<void> resetHomeLayout() async {
    await _preferences.remove(_homeLayoutKey);
  }
}
