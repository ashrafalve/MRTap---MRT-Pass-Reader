import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences. Everything here is trivial and non-identifying.
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const String _kLanguage = 'language';
  static const String _kThemeMode = 'theme_mode';

  static const String languageSystem = 'system';
  static const String themeSystem = 'system';
  static const String themeLight = 'light';
  static const String themeDark = 'dark';

  static Future<SettingsRepository> load() async =>
      SettingsRepository(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  /// `system`, `en` or `bn`.
  String get language => _prefs.getString(_kLanguage) ?? languageSystem;

  Future<void> setLanguage(String value) => _prefs.setString(_kLanguage, value);

  /// `system`, `light` or `dark`.
  String get themeModeName => _prefs.getString(_kThemeMode) ?? themeSystem;

  ThemeMode get themeMode => switch (themeModeName) {
    themeLight => ThemeMode.light,
    themeDark => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> setThemeMode(String value) => _prefs.setString(_kThemeMode, value);

  Future<void> clear() async {
    await _prefs.remove(_kLanguage);
    await _prefs.remove(_kThemeMode);
  }
}
