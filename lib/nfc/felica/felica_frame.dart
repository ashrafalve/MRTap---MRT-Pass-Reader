import 'dart:typed_data';

import 'package:mrtap/core/app_info.dart';

/// Builds the FeliCa "Read Without Encryption" command (0x06) that fetches a
/// window of 16-byte blocks from the transaction-history service.
///
/// Layout: `[LEN][0x06][IDm x8][0x01][svcLo][svcHi][count][0x80][block]*count`
/// where `LEN = 14 + 2 * count`.
Uint8List buildReadCommand({
  required Uint8List idm,
  required int startBlock,
  int count = FelicaSpec.blocksPerWindow,
  int serviceCode = FelicaSpec.transactionServiceCode,
}) {
  if (idm.length != 8) {
    throw ArgumentError.value(idm.length, 'idm', 'FeliCa IDm must be 8 bytes');
  }
  final int length = 14 + count * 2;
  final Uint8List command = Uint8List(length);
  int i = 0;
  command[i++] = length;
  command[i++] = 0x06;
  command.setRange(i, i + 8, idm);
  i += 8;
  command[i++] = 0x01;
  command[i++] = serviceCode & 0xFF;
  command[i++] = (serviceCode >> 8) & 0xFF;
  command[i++] = count;
  for (int block = 0; block < count; block++) {
    command[i++] = 0x80;
    command[i++] = (startBlock + block) & 0xFF;
  }
  return command;
}

/// A decoded FeliCa response frame.
///
/// Frame layout: `[LEN][respCode][IDm x8][statusFlag1][statusFlag2][blockCount]`
/// followed by `blockCount` 16-byte blocks. A frame that is too short, or whose
/// payload cannot hold the declared number of blocks, carries no blocks.
class FelicaFrame {
  const FelicaFrame({
    required this.statusFlag1,
    required this.statusFlag2,
    required this.blocks,
    required this.declaredBlockCount,
  });

  static const int _errorFlag = -1;

  /// Sentinels returned when the frame is structurally invalid.
  static const FelicaFrame invalid = FelicaFrame(
    statusFlag1: _errorFlag,
    statusFlag2: _errorFlag,
    blocks: <Uint8List>[],
    declaredBlockCount: 0,
  );

  final int statusFlag1;
  final int statusFlag2;
  final List<Uint8List> blocks;
  final int declaredBlockCount;

  /// A window is usable only when both status flags are zero.
  ///
  /// A non-zero flag is the card's way of saying "that block range holds
  /// nothing", which is the normal answer for the second window of a card that
  /// has fewer than eleven records.
  bool get isSuccess => statusFlag1 == 0 && statusFlag2 == 0;

  bool get isStructurallyValid => statusFlag1 != _errorFlag;

  /// Parses a raw transceive response.
  static FelicaFrame decode(Uint8List frame) {
    const int headerSize = 13;
    if (frame.length < headerSize) {
      return invalid;
    }
    final int statusFlag1 = frame[10] & 0xFF;
    final int statusFlag2 = frame[11] & 0xFF;
    final int declared = frame[12] & 0xFF;
    final int payload = frame.length - headerSize;
    final List<Uint8List> blocks = <Uint8List>[];
    if (payload >= declared * FelicaSpec.blockSize) {
      for (int i = 0; i < declared; i++) {
        final int start = headerSize + i * FelicaSpec.blockSize;
        blocks.add(
          Uint8List.sublistView(frame, start, start + FelicaSpec.blockSize),
        );
      }
    }
    return FelicaFrame(
      statusFlag1: statusFlag1,
      statusFlag2: statusFlag2,
      blocks: blocks,
      declaredBlockCount: declared,
    );
  }
}

/// The transport a [FelicaReader] talks over.
///
/// Abstracted so the reader can be exercised in tests against canned frames
/// without any NFC hardware.
abstract class CardTransceiver {
  /// The 8-byte FeliCa IDm of the card.
  Uint8List get idm;

  /// Sends a raw command and returns the raw response.
  ///
  /// Implementations throw [CardTransceiverException] on I/O failure.
  Future<Uint8List> transceive(Uint8List command);
}

/// Raised when the transport fails.
class CardTransceiverException implements Exception {
  CardTransceiverException(this.message);

  final String? message;

  @override
  String toString() => 'CardTransceiverException: ${message ?? 'unknown'}';
}
