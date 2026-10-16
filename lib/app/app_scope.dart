import 'package:flutter/material.dart';

import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/data/repositories/backup_service.dart';
import 'package:mrtap/data/repositories/library_repository.dart';
import 'package:mrtap/data/repositories/settings_repository.dart';
import 'package:mrtap/data/fares/fare_data.dart';
import 'package:mrtap/nfc/nfc_service.dart';

/// Everything the widget tree needs, created once at startup and never rebuilt.
class AppServices {
  AppServices({
    required this.library,
    required this.settings,
    required this.backup,
    required this.nfc,
    this.fares = const FareService(),
  });

  final LibraryRepository library;
  final SettingsRepository settings;
  final BackupService backup;
  final NfcService nfc;
  final FareService fares;

  /// Bumped whenever stored cards or transactions change, so screens showing
  /// that data can reload. A plain counter instead of a full state-management
  /// package, because that is all this app needs.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void invalidate() => revision.value++;
}

/// Observable app-wide preferences (language, theme).
class AppController extends ChangeNotifier {
  AppController(this.settings)
      : _languagePreference = settings.language,
        _themeModeName = settings.themeModeName;

  final SettingsRepository settings;

  String _languagePreference;
  String _themeModeName;

  String get languagePreference => _languagePreference;

  ThemeMode get themeMode => switch (_themeModeName) {
    SettingsRepository.themeLight => ThemeMode.light,
    SettingsRepository.themeDark => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> setLanguage(String value) async {
    if (value == _languagePreference) {
      return;
    }
    _languagePreference = value;
    notifyListeners();
    await settings.setLanguage(value);
  }

  Future<void> setThemeMode(String value) async {
    if (value == _themeModeName) {
      return;
    }
    _themeModeName = value;
    notifyListeners();
    await settings.setThemeMode(value);
  }
}

/// Exposes [AppServices], the active [Strings] and the [AppController] to the
/// tree below the [MaterialApp].
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.services,
    required this.controller,
    required this.strings,
    required super.child,
  });

  final AppServices services;
  final AppController controller;
  final Strings strings;

  static AppScope of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.strings != strings ||
      oldWidget.services != services ||
      oldWidget.controller != controller;
}

/// Convenience accessors used everywhere in the UI.
extension AppScopeX on BuildContext {
  AppScope get scope => AppScope.of(this);

  AppServices get services => AppScope.of(this).services;

  AppController get appController => AppScope.of(this).controller;

  /// Localised strings for the active language.
  Strings get s => AppScope.of(this).strings;

  /// Shortcut for [Strings.t].
  String t(String key, [Map<String, String> args = const <String, String>{}]) =>
      AppScope.of(this).strings.t(key, args);

  /// The active language code, `en` or `bn`.
  String get languageCode => AppScope.of(this).strings.locale.languageCode;
}
