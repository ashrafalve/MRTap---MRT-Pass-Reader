import 'package:mrtap/nfc/felica/transaction_record.dart';

/// A card the user has read at least once, as stored on this device.
class SavedCard {
  const SavedCard({
    required this.idm,
    required this.nickname,
    required this.kind,
    required this.firstSeen,
    required this.lastScan,
  });

  /// FeliCa IDm as `01 27 ...`.
  final String idm;

  /// User-assigned name, or `null` if never renamed.
  final String? nickname;

  final CardKind kind;

  /// Epoch milliseconds when the card was first seen.
  final int firstSeen;

  /// Epoch milliseconds of the most recent successful read.
  final int lastScan;

  SavedCard copyWith({String? nickname, int? lastScan}) => SavedCard(
    idm: idm,
    nickname: nickname ?? this.nickname,
    kind: kind,
    firstSeen: firstSeen,
    lastScan: lastScan ?? this.lastScan,
  );

  /// Short, stable identifier shown in the UI since an IDm is long.
  String get shortId {
    final List<String> parts = idm.split(' ');
    if (parts.length >= 6) {
      return parts.sublist(parts.length - 4).join(' ');
    }
    return idm;
  }
}

/// A transaction as stored, with the amount derived from balance deltas.
class SavedTransaction {
  const SavedTransaction({
    required this.cardIdm,
    required this.fingerprint,
    required this.occurredAt,
    required this.fixedHeader,
    required this.type,
    required this.fromCode,
    required this.toCode,
    required this.balance,
    required this.balancePlausible,
    required this.rawBlock,
    required this.blockIndex,
    this.amount,
  });

  final String cardIdm;
  final String fingerprint;

  /// Epoch milliseconds of the (hour-accurate) card timestamp.
  final int occurredAt;

  final String fixedHeader;
  final TxnType type;
  final int fromCode;
  final int toCode;

  /// Balance after the transaction, in paisa.
  final int balance;

  final bool balancePlausible;
  final String rawBlock;
  final int blockIndex;

  /// Change in balance relative to the next-older record, in paisa.
  ///
  /// Negative for a journey, positive for a top-up. `null` when the next-older
  /// record is not on the device, in which case the app shows no amount instead
  /// of guessing.
  final int? amount;

  bool get isTopUp => type == TxnType.topUp;

  /// Money spent on a journey, as a positive amount in paisa.
  int? get farePaisa {
    final int? delta = amount;
    if (delta == null || delta >= 0) {
      return null;
    }
    return -delta;
  }

  /// Money added by a top-up, as a positive amount in paisa.
  int? get topUpPaisa {
    final int? delta = amount;
    if (delta == null || delta <= 0) {
      return null;
    }
    return delta;
  }

  SavedTransaction withAmount(int? value) => SavedTransaction(
    cardIdm: cardIdm,
    fingerprint: fingerprint,
    occurredAt: occurredAt,
    fixedHeader: fixedHeader,
    type: type,
    fromCode: fromCode,
    toCode: toCode,
    balance: balance,
    balancePlausible: balancePlausible,
    rawBlock: rawBlock,
    blockIndex: blockIndex,
    amount: value,
  );
}

/// Aggregates shown on a card's header.
class CardSummary {
  const CardSummary({
    required this.balancePaisa,
    required this.totalSpentPaisa,
    required this.journeyCount,
    required this.topUpCount,
    required this.transactionCount,
  });

  const CardSummary.empty()
      : balancePaisa = null,
        totalSpentPaisa = 0,
        journeyCount = 0,
        topUpCount = 0,
        transactionCount = 0;

  /// Latest plausible balance in paisa, or `null` when none is known.
  final int? balancePaisa;
  final int totalSpentPaisa;
  final int journeyCount;
  final int topUpCount;
  final int transactionCount;
}
