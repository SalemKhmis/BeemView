import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cubit managing the application visual theme mode (Light ↔ Dark).
class ThemeCubit extends Cubit<ThemeMode> {
  final FlutterSecureStorage _storage;
  static const _themeKey = 'app_theme_mode';

  ThemeCubit({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(ThemeMode.light) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final savedTheme = await _storage.read(key: _themeKey);
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'dark':
            emit(ThemeMode.dark);
            break;
          case 'light':
            emit(ThemeMode.light);
            break;
          case 'system':
            emit(ThemeMode.system);
            break;
        }
      }
    } catch (_) {
      // Default to light theme on error
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    emit(mode);
    try {
      final String modeString = switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };
      await _storage.write(key: _themeKey, value: modeString);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
