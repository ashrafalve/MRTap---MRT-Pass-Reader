import 'dart:typed_data';

import 'package:mrtap/core/app_info.dart';
import 'package:mrtap/core/util/bytes.dart';
import 'package:mrtap/nfc/felica/felica_frame.dart';
import 'package:mrtap/nfc/felica/transaction_record.dart';

/// Turns raw 16-byte history blocks into [ParsedTransaction]s.
///
/// The layout, confirmed against independent readers of the Dhaka Metro cards:
///
/// ```text
///  0..3   fixed header        e.g. 08 52 10 00 (metro journey)
///  4..6   timestamp           24-bit big-endian, bit-packed (see below)
///  6..7   type bytes          overlap byte 6; retained for reference
///  8      from station code
///  9      separator
///  10     to station code
///  11..13 balance             little-endian, in paisa
///  14..15 trailing
/// ```
///
/// The packed timestamp uses bits 3-7 for the hour, 8-12 for the day, 13-16 for
/// the month and 17-21 for a year offset. There is no minute field: card
/// timestamps are accurate to the hour, and the app says so rather than
/// inventing minutes.
class TransactionParser {
  const TransactionParser._();

  /// Year added to the packed year offset. Chosen so the stored offset is small.
  static const int baseYear = 2000;

  /// Records at or before this date are treated as unwritten card memory.
  static final DateTime cutoff = DateTime(2020, 1, 1);

  /// Parses every usable record in a decoded window frame.
  ///
  /// Returns an empty list for a window whose status flags are non-zero.
  static List<ParsedTransaction> parseWindow(
    FelicaFrame frame, {
    required int startBlock,
  }) {
    if (!frame.isSuccess) {
      return const <ParsedTransaction>[];
    }
    final List<ParsedTransaction> out = <ParsedTransaction>[];
    for (int i = 0; i < frame.blocks.length; i++) {
      final Uint8List block = frame.blocks[i];
      if (block.length != FelicaSpec.blockSize) {
        continue;
      }
      final ParsedTransaction parsed =
          parseBlock(block, blockIndex: startBlock + i);
      if (parsed.isValid) {
        out.add(parsed);
      }
    }
    return out;
  }

  /// Parses one block without the validity filter, for diagnostics and tests.
  static ParsedTransaction parseBlock(
    Uint8List block, {
    int blockIndex = 0,
  }) {
    if (block.length != FelicaSpec.blockSize) {
      throw ArgumentError.value(
        block.length,
        'block',
        'history block must be ${FelicaSpec.blockSize} bytes',
      );
    }
    final String fixedHeader = toHex(Uint8List.sublistView(block, 0, 4));
    final int timestampRaw = readUint24BE(block, 4);
    return ParsedTransaction(
      fixedHeader: fixedHeader,
      timestampRaw: timestampRaw,
      timestamp: decodeTimestamp(timestampRaw),
      type: TxnType.fromHeader(fixedHeader),
      typeBytes: toHex(Uint8List.sublistView(block, 6, 8)),
      fromCode: block[8] & 0xFF,
      toCode: block[10] & 0xFF,
      balance: readUint24LE(block, 11),
      trailing: toHex(Uint8List.sublistView(block, 14, 16)),
      blockIndex: blockIndex,
      rawBlock: toHex(block),
    );
  }

  /// Decodes the packed 24-bit timestamp.
  ///
  /// Returns `null` when any field is out of range, so a corrupt or unwritten
  /// block can never masquerade as a real timestamp.
  static DateTime? decodeTimestamp(int value) {
    final int hour = (value >> 3) & 0x1F;
    final int day = (value >> 8) & 0x1F;
    final int month = (value >> 13) & 0x0F;
    final int year = ((value >> 17) & 0x1F) + baseYear;

    if (month < 1 || month > 12) {
      return null;
    }
    if (day < 1 || day > 31) {
      return null;
    }
    if (hour > 23) {
      return null;
    }
    if (year < 2020 || year > 2100) {
      return null;
    }
    final DateTime candidate = DateTime(year, month, day, hour);
    // DateTime silently rolls invalid dates (31 Feb) forward; reject those.
    if (candidate.month != month || candidate.day != day) {
      return null;
    }
    return candidate;
  }
}
