import 'dart:typed_data';

import 'package:mrtap/core/app_info.dart';
import 'package:mrtap/core/util/bytes.dart';
import 'package:mrtap/nfc/felica/felica_frame.dart';
import 'package:mrtap/nfc/felica/transaction_parser.dart';
import 'package:mrtap/nfc/felica/transaction_record.dart';

/// What a single read produced.
class CardReadResult {
  const CardReadResult({
    required this.idm,
    required this.transactions,
    this.error,
    this.windows = const <FelicaWindow>[],
  });

  /// FeliCa IDm, formatted as `01 27 ...`.
  final String idm;

  final List<ParsedTransaction> transactions;

  /// Set when the transport failed. [transactions] still holds whatever was
  /// read before the failure, so a half read is never thrown away.
  final Object? error;

  /// Per-window detail, kept for the diagnostics screen and for tests.
  final List<FelicaWindow> windows;

  bool get hasError => error != null;

  /// True when the card answered but carried no usable records.
  bool get isEmpty => transactions.isEmpty && error == null;
}

/// Outcome of reading one 10-block window.
class FelicaWindow {
  const FelicaWindow({
    required this.startBlock,
    required this.frame,
    required this.parsed,
    this.error,
  });

  final int startBlock;
  final FelicaFrame? frame;
  final int parsed;
  final Object? error;
}

/// Reads the rolling transaction history off an MRT Pass / Rapid Pass.
///
/// Two 10-block windows are fetched (blocks 0-9 and 10-19). If the transport
/// fails part-way through, the records already read are returned alongside the
/// error rather than being discarded — pulling the phone away mid-read is the
/// single most common failure and a partial history is still useful.
class FelicaReader {
  FelicaReader(this.transceiver);

  final CardTransceiver transceiver;

  Future<CardReadResult> readTransactionHistory() async {
    final List<ParsedTransaction> transactions = <ParsedTransaction>[];
    final List<FelicaWindow> windows = <FelicaWindow>[];
    Object? failure;

    for (final int startBlock in FelicaSpec.readWindows) {
      try {
        final Uint8List command = buildReadCommand(
          idm: transceiver.idm,
          startBlock: startBlock,
        );
        final Uint8List response = await transceiver.transceive(command);
        final FelicaFrame frame = FelicaFrame.decode(response);
        final List<ParsedTransaction> parsed = TransactionParser.parseWindow(
          frame,
          startBlock: startBlock,
        );
        transactions.addAll(parsed);
        windows.add(
          FelicaWindow(
            startBlock: startBlock,
            frame: frame,
            parsed: parsed.length,
          ),
        );
      } catch (error) {
        failure = error;
        windows.add(
          FelicaWindow(
            startBlock: startBlock,
            frame: null,
            parsed: 0,
            error: error,
          ),
        );
        break;
      }
    }

    return CardReadResult(
      idm: toHex(transceiver.idm),
      transactions: transactions,
      error: failure,
      windows: windows,
    );
  }
}
