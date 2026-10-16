import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the on-device SQLite database.
///
/// The schema is deliberately tiny and fully local: three tables, no foreign
/// keys that could cascade a card deletion into the wrong place, and a
/// composite key on transactions that makes de-duplication a database
/// constraint rather than application logic.
class AppDatabase {
  AppDatabase({this.overridePath});

  /// Where the database lives. Only set by tests, which point it at a
  /// temporary file.
  final String? overridePath;

  static const String fileName = 'mrtap.db';
  static const int schemaVersion = 1;

  Database? _database;

  Future<Database> get database async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }
    return _database = await _open();
  }

  Future<Database> _open() async {
    final String path = overridePath ?? p.join(await getDatabasesPath(), fileName);
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: _create,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards (
        idm        TEXT    PRIMARY KEY,
        nickname   TEXT,
        card_kind  TEXT    NOT NULL,
        first_seen INTEGER NOT NULL,
        last_scan  INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE scans (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        card_idm    TEXT    NOT NULL,
        read_at     INTEGER NOT NULL,
        found       INTEGER NOT NULL,
        inserted    INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        card_idm          TEXT    NOT NULL,
        fingerprint       TEXT    NOT NULL,
        occurred_at       INTEGER NOT NULL,
        fixed_header      TEXT    NOT NULL,
        txn_type          TEXT    NOT NULL,
        from_code         INTEGER NOT NULL,
        to_code           INTEGER NOT NULL,
        balance           INTEGER NOT NULL,
        balance_plausible INTEGER NOT NULL,
        raw_block         TEXT    NOT NULL,
        block_index       INTEGER NOT NULL,
        first_seen        INTEGER NOT NULL,
        PRIMARY KEY (card_idm, fingerprint)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_txn_card_time ON transactions (card_idm, occurred_at DESC, block_index ASC)',
    );
    await db.execute(
      'CREATE INDEX idx_scans_card ON scans (card_idm, read_at DESC)',
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Wipes every table. Used by "clear all data".
  Future<void> wipe() async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      await txn.delete('transactions');
      await txn.delete('scans');
      await txn.delete('cards');
    });
  }
}
