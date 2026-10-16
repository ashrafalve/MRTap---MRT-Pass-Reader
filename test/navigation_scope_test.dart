import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/data/db/app_database.dart';
import 'package:mrtap/data/repositories/backup_service.dart';
import 'package:mrtap/data/repositories/library_repository.dart';
import 'package:mrtap/data/repositories/settings_repository.dart';
import 'package:mrtap/features/fare/fare_screen.dart';
import 'package:mrtap/features/stations/stations_screen.dart';
import 'package:mrtap/nfc/nfc_service.dart';

/// Regression tests for the bug where [AppScope] was installed below
/// `MaterialApp`, so pushed routes and modal bottom sheets (built by the root
/// Navigator, which sits above `home`) could not see it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppServices services;
  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsRepository settings = await SettingsRepository.load();
    final LibraryRepository library = LibraryRepository(AppDatabase());
    services = AppServices(
      library: library,
      settings: settings,
      backup: BackupService(library),
      nfc: NfcService(),
    );
    controller = AppController(settings);
  });

  Widget wrap(Widget child) => AppScope(
    services: services,
    controller: controller,
    strings: MRTapLocalizations.build(const Locale('en')),
    child: MaterialApp(home: child),
  );

  testWidgets('station tap opens a detail sheet that can read AppScope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const StationsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uttara North'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The sheet renders station details via context.t(...), which needs AppScope.
    expect(find.text('Station code'), findsOneWidget);
  });

  testWidgets('fare station picker opens and selects without error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const FareScreen(embedded: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select a station').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uttara Center').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Uttara Center'), findsWidgets);
  });
}
