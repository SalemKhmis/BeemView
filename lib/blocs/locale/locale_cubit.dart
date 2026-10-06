import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cubit managing the application language locale (English / Arabic).
class LocaleCubit extends Cubit<Locale> {
  final FlutterSecureStorage _storage;
  static const _localeKey = 'app_locale';

  LocaleCubit({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final savedCode = await _storage.read(key: _localeKey);
      if (savedCode != null && (savedCode == 'en' || savedCode == 'ar')) {
        emit(Locale(savedCode));
      }
    } catch (_) {
      // Default to English on error
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state.languageCode == locale.languageCode) return;
    emit(locale);
    try {
      await _storage.write(key: _localeKey, value: locale.languageCode);
    } catch (_) {}
  }

  Future<void> toggleLocale() async {
    final nextCode = state.languageCode == 'en' ? 'ar' : 'en';
    await setLocale(Locale(nextCode));
  }
}
