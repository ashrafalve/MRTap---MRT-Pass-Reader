import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/theme/app_theme.dart';
import 'package:mrtap/features/splash/splash_screen.dart';

/// The application root.
///
/// Owns the [AppController] so a language or theme change rebuilds the whole
/// tree, and installs [AppScope] below `MaterialApp` so the resolved locale is
/// available to every screen.
class MRTapApp extends StatefulWidget {
  const MRTapApp({super.key, required this.services, required this.controller});

  final AppServices services;
  final AppController controller;

  @override
  State<MRTapApp> createState() => _MRTapAppState();
}

class _MRTapAppState extends State<MRTapApp> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final Locale device = WidgetsBinding.instance.platformDispatcher.locale;
        final Locale locale =
            Strings.resolve(widget.controller.languagePreference, device);
        final Strings strings = MRTapLocalizations.build(locale);

        return AppScope(
          services: widget.services,
          controller: widget.controller,
          strings: strings,
          child: MaterialApp(
            title: strings.t(S.appName),
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light, locale.languageCode),
            darkTheme: buildAppTheme(Brightness.dark, locale.languageCode),
            themeMode: widget.controller.themeMode,
            locale: locale,
            supportedLocales: Strings.supported,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              MRTapLocalizations.delegate,
            ],
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
