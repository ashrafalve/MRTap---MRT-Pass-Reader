import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:mrtap/core/app_info.dart';
import 'package:mrtap/data/repositories/library_repository.dart';

/// Result of writing a backup file.
class BackupFile {
  const BackupFile({required this.path, required this.bytes, required this.cards, required this.transactions});

  final String path;
  final int bytes;
  final int cards;
  final int transactions;
}

/// JSON export / import of everything MRTap stores.
///
/// The format is a plain, self-describing document. Import is additive and
/// idempotent: rows that already exist are ignored, so restoring an old backup
/// cannot clobber current data.
class BackupService {
  BackupService(this._repository);

  static const String documentType = 'mrtap.backup';
  static const int documentVersion = 1;

  final LibraryRepository _repository;

  Future<BackupFile> exportToFile() async {
    final List<Map<String, Object?>> cards = await _repository.rawCards();
    final List<Map<String, Object?>> transactions = await _repository.rawTransactions();

    final Map<String, Object?> document = <String, Object?>{
      'type': documentType,
      'version': documentVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': AppInfo.version,
      'fareDataVersion': AppInfo.fareDataVersion,
      'cards': cards,
      'transactions': transactions,
    };

    final String encoded = const JsonEncoder.withIndent('  ').convert(document);
    final Directory dir = await getApplicationDocumentsDirectory();
    final String stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-');
    final File file = File(p.join(dir.path, 'mrtap-backup-$stamp.json'));
    await file.writeAsString(encoded, flush: true);

    return BackupFile(
      path: file.path,
      bytes: encoded.length,
      cards: cards.length,
      transactions: transactions.length,
    );
  }

  Future<ImportOutcome> importFromFile(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw const FormatException('Backup file not found');
    }
    final Object? decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Backup is not a JSON object');
    }
    if (decoded['type'] != documentType) {
      throw const FormatException('Not an MRTap backup');
    }
    final int version = (decoded['version'] as num?)?.toInt() ?? 0;
    if (version > documentVersion) {
      throw const FormatException('Backup was written by a newer version of MRTap');
    }

    return _repository.importRaw(
      cards: _rows(decoded['cards']),
      transactions: _rows(decoded['transactions']),
    );
  }

  static List<Map<String, Object?>> _rows(Object? value) {
    if (value is! List) {
      return const <Map<String, Object?>>[];
    }
    return value
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> row) =>
            row.map((Object? k, Object? v) => MapEntry<String, Object?>('$k', v)))
        .toList(growable: false);
  }
}
