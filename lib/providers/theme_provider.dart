import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather_provider.dart' show sharedPrefsProvider;

/// 主题模式枚举：跟随系统 / 浅色 / 深色。
enum AppThemeMode {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };
}

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier(this._prefs) : super(AppThemeMode.system) {
    _load();
  }

  final SharedPreferences _prefs;
  static const String _kThemeKey = 'app_theme_mode';

  void _load() {
    final v = _prefs.getString(_kThemeKey);
    state = switch (v) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeKey, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPrefsProvider));
});
