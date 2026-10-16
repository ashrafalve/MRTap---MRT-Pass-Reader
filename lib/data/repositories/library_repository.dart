import 'package:sqflite/sqflite.dart';

import 'package:mrtap/core/app_info.dart';
import 'package:mrtap/data/db/app_database.dart';
import 'package:mrtap/data/fares/fare_data.dart';
import 'package:mrtap/data/models/models.dart';
import 'package:mrtap/nfc/felica/felica_reader.dart';
import 'package:mrtap/nfc/felica/transaction_record.dart';

/// Result of persisting one card read.
class SaveOutcome {
  const SaveOutcome({
    required this.card,
    required this.found,
    required this.inserted,
  });

  final SavedCard card;

  /// Records decoded from the card in this read.
  final int found;

  /// Records that were not already on the device.
  final int inserted;
}

/// How much a restore added.
class ImportOutcome {
  const ImportOutcome({required this.cardsAdded, required this.transactionsAdded});

  final int cardsAdded;
  final int transactionsAdded;
}

/// Reads and writes cards and transactions.
/// All the FeliCa parsing happens before this point; the repository only deals
/// in already-validated records, which keeps the "never invent data" rule in one
/// place (the parser and the amount derivation below).
class LibraryRepository {
  LibraryRepository(this._database);

  final AppDatabase _database;

  /// Persists the outcome of a card read.
  ///
  /// Cards are upserted, one scan row is recorded, and transactions are
  /// inserted with the composite key as the de-duplication guard so re-reading
  /// the same card never duplicates history.
  Future<SaveOutcome> saveRead(CardReadResult result) async {
    final Database db = await _database.database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final CardKind kind = cardKindFromIdm(result.idm);

    return db.transaction<SaveOutcome>((Transaction txn) async {
      await txn.rawInsert(
        '''
        INSERT INTO cards (idm, nickname, card_kind, first_seen, last_scan)
        VALUES (?, NULL, ?, ?, ?)
        ON CONFLICT(idm) DO UPDATE SET last_scan = excluded.last_scan
        ''',
        <Object?>[result.idm, kind.name, now, now],
      );

      int inserted = 0;
      for (final ParsedTransaction record in result.transactions) {
        final int rowId = await txn.insert(
          'transactions',
          <String, Object?>{
            'card_idm': result.idm,
            'fingerprint': record.fingerprint,
            'occurred_at': record.timestamp!.millisecondsSinceEpoch,
            'fixed_header': record.fixedHeader,
            'txn_type': record.type.name,
            'from_code': record.fromCode,
            'to_code': record.toCode,
            'balance': record.balance,
            'balance_plausible': record.balancePlausible ? 1 : 0,
            'raw_block': record.rawBlock,
            'block_index': record.blockIndex,
            'first_seen': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (rowId != 0) {
          inserted++;
        }
      }

      await txn.insert('scans', <String, Object?>{
        'card_idm': result.idm,
        'read_at': now,
        'found': result.transactions.length,
        'inserted': inserted,
      });

      final SavedCard card = await _readCard(txn, result.idm);
      return SaveOutcome(
        card: card,
        found: result.transactions.length,
        inserted: inserted,
      );
    });
  }

  Future<List<SavedCard>> cards() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      'cards',
      orderBy: 'last_scan DESC',
    );
    return rows.map(_mapCard).toList(growable: false);
  }

  Future<SavedCard?> card(String idm) async {
    final Database db = await _database.database;
    return _readCard(db, idm);
  }

  Future<bool> hasCards() async {
    final Database db = await _database.database;
    final int? count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cards'),
    );
    return (count ?? 0) > 0;
  }

  Future<void> renameCard(String idm, String? nickname) async {
    final Database db = await _database.database;
    final String? trimmed = nickname?.trim();
    await db.update(
      'cards',
      <String, Object?>{'nickname': (trimmed == null || trimmed.isEmpty) ? null : trimmed},
      where: 'idm = ?',
      whereArgs: <Object?>[idm],
    );
  }

  Future<void> deleteCard(String idm) async {
    final Database db = await _database.database;
    await db.transaction((Transaction txn) async {
      await txn.delete('transactions', where: 'card_idm = ?', whereArgs: <Object?>[idm]);
      await txn.delete('scans', where: 'card_idm = ?', whereArgs: <Object?>[idm]);
      await txn.delete('cards', where: 'idm = ?', whereArgs: <Object?>[idm]);
    });
  }

  Future<void> clearAll() => _database.wipe();

  /// Transactions for one card, newest first, with amounts derived from
  /// balance deltas against the next-older record on the device.
  Future<List<SavedTransaction>> transactionsForCard(String idm) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      'transactions',
      where: 'card_idm = ?',
      whereArgs: <Object?>[idm],
      orderBy: 'occurred_at DESC, block_index ASC',
    );
    return _withAmounts(rows);
  }

  /// Every transaction on the device, newest first.
  Future<List<SavedTransaction>> allTransactions() async {
    final List<String> cardIds = (await cards()).map((SavedCard c) => c.idm).toList();
    final List<SavedTransaction> merged = <SavedTransaction>[];
    for (final String idm in cardIds) {
      merged.addAll(await transactionsForCard(idm));
    }
    merged.sort((SavedTransaction a, SavedTransaction b) {
      final int byTime = b.occurredAt.compareTo(a.occurredAt);
      if (byTime != 0) {
        return byTime;
      }
      return a.blockIndex.compareTo(b.blockIndex);
    });
    return merged;
  }

  Future<CardSummary> summary(String idm) async {
    final List<SavedTransaction> transactions = await transactionsForCard(idm);
    if (transactions.isEmpty) {
      return const CardSummary.empty();
    }
    int spent = 0;
    int journeys = 0;
    int topUps = 0;
    int? balance;
    for (final SavedTransaction t in transactions) {
      if (t.balancePlausible && balance == null) {
        balance = t.balance;
      }
      if (t.type.isJourney && t.farePaisa != null) {
        spent += t.farePaisa!;
        journeys++;
      } else if (t.type.isTopUp && t.topUpPaisa != null) {
        topUps++;
      }
    }
    return CardSummary(
      balancePaisa: balance,
      totalSpentPaisa: spent,
      journeyCount: journeys,
      topUpCount: topUps,
      transactionCount: transactions.length,
    );
  }

  /// Raw card rows, for backup export.
  Future<List<Map<String, Object?>>> rawCards() async {
    final Database db = await _database.database;
    return db.query('cards', orderBy: 'first_seen ASC');
  }

  /// Raw transaction rows, for backup export.
  Future<List<Map<String, Object?>>> rawTransactions() async {
    final Database db = await _database.database;
    return db.query(
      'transactions',
      orderBy: 'card_idm ASC, occurred_at ASC, block_index DESC',
    );
  }

  /// Merges a backup back in. Existing rows win, so importing the same file
  /// twice changes nothing and importing an older backup cannot overwrite newer
  /// local data.
  Future<ImportOutcome> importRaw({
    required List<Map<String, Object?>> cards,
    required List<Map<String, Object?>> transactions,
  }) async {
    final Database db = await _database.database;
    int cardsAdded = 0;
    int txnsAdded = 0;

    await db.transaction((Transaction txn) async {
      for (final Map<String, Object?> row in cards) {
        final int id = await txn.insert(
          'cards',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (id != 0) {
          cardsAdded++;
        }
      }
      for (final Map<String, Object?> row in transactions) {
        final int id = await txn.insert(
          'transactions',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (id != 0) {
          txnsAdded++;
        }
      }
    });

    return ImportOutcome(cardsAdded: cardsAdded, transactionsAdded: txnsAdded);
  }

  Future<SavedCard> _readCard(DatabaseExecutor db, String idm) async {
    final List<Map<String, Object?>> rows = await db.query(
      'cards',
      where: 'idm = ?',
      whereArgs: <Object?>[idm],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Card $idm disappeared mid-transaction');
    }
    return _mapCard(rows.first);
  }

  SavedCard _mapCard(Map<String, Object?> row) => SavedCard(
    idm: row['idm']! as String,
    nickname: row['nickname'] as String?,
    kind: CardKind.values.firstWhere(
      (CardKind k) => k.name == row['card_kind'],
      orElse: () => CardKind.mrtPass,
    ),
    firstSeen: row['first_seen']! as int,
    lastScan: row['last_scan']! as int,
  );

  List<SavedTransaction> _withAmounts(List<Map<String, Object?>> rows) {
    final List<SavedTransaction> enriched = <SavedTransaction>[];
    for (int i = 0; i < rows.length; i++) {
      final Map<String, Object?> row = rows[i];
      final SavedTransaction current = _mapTransaction(row);
      int? amount;
      if (i + 1 < rows.length) {
        final int olderBalance = rows[i + 1]['balance']! as int;
        amount = _plausibleDelta(current.type, current.balance - olderBalance);
      }
      enriched.add(current.withAmount(amount));
    }
    return enriched;
  }

  /// Filters a raw balance delta down to "this is a single real transaction".
  ///
  /// A negative delta is money charged to the card and must fit within the
  /// highest published fare. A positive delta is a top-up and cannot exceed the
  /// card's cap. A sign that contradicts the record type, or a magnitude that
  /// cannot belong to one transaction, means records are missing between the
  /// two — the app then shows no amount rather than a wrong one.
  static int? _plausibleDelta(TxnType type, int delta) {
    if (delta == 0) {
      return null;
    }
    const int fareCeiling = FareRules.maxFare * FelicaSpec.takaToPaisa;
    if (delta < 0) {
      if (type.isTopUp) {
        return null;
      }
      return (-delta) <= fareCeiling ? delta : null;
    }
    if (type.isJourney) {
      return null;
    }
    if (type == TxnType.unknown) {
      return delta <= fareCeiling ? delta : null;
    }
    return delta <= FelicaSpec.maxBalance ? delta : null;
  }

  SavedTransaction _mapTransaction(Map<String, Object?> row) => SavedTransaction(
    cardIdm: row['card_idm']! as String,
    fingerprint: row['fingerprint']! as String,
    occurredAt: row['occurred_at']! as int,
    fixedHeader: row['fixed_header']! as String,
    type: TxnType.values.firstWhere(
      (TxnType t) => t.name == row['txn_type'],
      orElse: () => TxnType.unknown,
    ),
    fromCode: row['from_code']! as int,
    toCode: row['to_code']! as int,
    balance: row['balance']! as int,
    balancePlausible: (row['balance_plausible']! as int) == 1,
    rawBlock: row['raw_block']! as String,
    blockIndex: row['block_index']! as int,
  );
}
