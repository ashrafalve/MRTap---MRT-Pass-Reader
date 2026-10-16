import 'package:mrtap/core/app_info.dart';

/// What a history record represents, derived from its fixed header only.
///
/// The mapping is taken from the card format as implemented by independent
/// readers; nothing is inferred from the timestamp or balance.
enum TxnType {
  /// A metro journey. Used by both MRT Pass and Rapid Pass.
  metro,

  /// A Hatirjheel bus leg — boarding. Rapid Pass only.
  busStart,

  /// A Hatirjheel bus leg — alighting. Rapid Pass only.
  busEnd,

  /// A balance top-up.
  topUp,

  /// A header that is not recognised. Kept so the user can see that data
  /// exists on the card rather than having it silently discarded.
  unknown;

  /// Classifies a record from its 4-byte fixed header, formatted as
  /// `08 52 10 00`.
  static TxnType fromHeader(String fixedHeader) {
    switch (fixedHeader) {
      case TxnHeader.metro:
        return TxnType.metro;
      case TxnHeader.busStart:
        return TxnType.busStart;
      case TxnHeader.busEnd:
        return TxnType.busEnd;
      case TxnHeader.topUpMrt:
      case TxnHeader.topUpRapid:
        return TxnType.topUp;
      default:
        return TxnType.unknown;
    }
  }

  bool get isTopUp => this == TxnType.topUp;

  bool get isJourney =>
      this == TxnType.metro || this == TxnType.busStart || this == TxnType.busEnd;
}

/// A single parsed history record.
///
/// Every field is either read straight off the card or explicitly `null` when
/// the card did not provide a usable value. Nothing is synthesised.
class ParsedTransaction {
  ParsedTransaction({
    required this.fixedHeader,
    required this.timestampRaw,
    required this.timestamp,
    required this.type,
    required this.typeBytes,
    required this.fromCode,
    required this.toCode,
    required this.balance,
    required this.trailing,
    required this.blockIndex,
    required this.rawBlock,
  });

  /// Fixed header (bytes 0-3) as `08 52 10 00`.
  final String fixedHeader;

  /// The packed 24-bit timestamp exactly as stored on the card.
  final int timestampRaw;

  /// Decoded timestamp, or `null` when the packed value is not a valid date.
  final DateTime? timestamp;

  final TxnType type;

  /// Bytes 6-7, shown for auditability since they overlap the timestamp.
  final String typeBytes;

  /// Station code in byte 8.
  final int fromCode;

  /// Station code in byte 10.
  final int toCode;

  /// Balance after the transaction, in paisa.
  final int balance;

  /// Bytes 14-15, retained so a record can be reproduced verbatim.
  final String trailing;

  /// Absolute block number on the card (0 is the newest record).
  final int blockIndex;

  /// The full 16 bytes, hex encoded, as read from the card.
  final String rawBlock;

  /// A record is usable when it carries a decodable timestamp after 2020.
  ///
  /// Empty or unwritten blocks decode to an out-of-range year and are dropped
  /// here rather than being shown as a 2000-01-01 entry.
  bool get isValid {
    final DateTime? ts = timestamp;
    return ts != null && ts.isAfter(DateTime(2020, 1, 1));
  }

  /// Whether the balance looks like a real value rather than an unwritten
  /// block. The card firmware caps balances at [FelicaSpec.maxBalance].
  bool get balancePlausible =>
      balance >= 0 && balance <= FelicaSpec.maxBalance;

  /// Natural key of the record, used to de-duplicate across scans.
  ///
  /// Card timestamps have one-hour resolution, so two distinct records could in
  /// theory collide; in practice the balance and station codes differ.
  String get fingerprint =>
      '$fixedHeader|$timestampRaw|$fromCode|$toCode|$balance';
}

/// Whether an IDm belongs to a Rapid Pass.
///
/// Rapid Pass cards use an IDm starting `01 27`; MRT Pass cards do not.
bool isRapidPassIdm(String hexIdm) {
  final String compact = hexIdm.replaceAll(' ', '').toUpperCase();
  return compact.startsWith('0127');
}

/// Human-independent card kind stored in the database.
enum CardKind { mrtPass, rapidPass }

CardKind cardKindFromIdm(String hexIdm) =>
    isRapidPassIdm(hexIdm) ? CardKind.rapidPass : CardKind.mrtPass;
