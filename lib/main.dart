import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mrtap/app/app.dart';
import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/data/db/app_database.dart';
import 'package:mrtap/data/repositories/backup_service.dart';
import 'package:mrtap/data/repositories/library_repository.dart';
import 'package:mrtap/data/repositories/settings_repository.dart';
import 'package:mrtap/nfc/nfc_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppDatabase database = AppDatabase();
  final LibraryRepository library = LibraryRepository(database);
  final SettingsRepository settings = await SettingsRepository.load();

  runApp(
    MRTapApp(
      controller: AppController(settings),
      services: AppServices(
        library: library,
        settings: settings,
        backup: BackupService(library),
        nfc: NfcService(),
      ),
    ),
  );
}
