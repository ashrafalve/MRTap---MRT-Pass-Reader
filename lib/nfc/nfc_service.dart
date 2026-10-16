import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import 'package:mrtap/nfc/felica/felica_frame.dart';
import 'package:mrtap/nfc/felica/felica_reader.dart';

/// Machine-readable reasons a scan did not produce data.
enum NfcError {
  /// NFC hardware is absent.
  unsupported,

  /// NFC exists but is switched off in system settings.
  disabled,

  /// A scan is already running.
  busy,

  /// No card was presented in time.
  timeout,

  /// The tag presented is not a FeliCa card.
  notFelica,

  /// The card was removed (or moved) before the read finished and no records
  /// had been collected yet.
  incompleteRead,

  /// The transport failed for another reason.
  io,

  /// The user backed out of the scan.
  cancelled,
}

/// A scan failure with a stable [code] the UI maps to a localised message.
class NfcException implements Exception {
  NfcException(this.code, [this.detail]);

  final NfcError code;
  final Object? detail;

  @override
  String toString() => 'NfcException(${code.name}${detail == null ? '' : ': $detail'})';
}

/// Wraps `nfc_manager` with the parts MRTap needs.
///
/// Android-only in practice, but written against the cross-platform facade so
/// it compiles and runs elsewhere without changes.
class NfcService {
  NfcService();

  bool _sessionActive = false;
  Completer<CardReadResult>? _pending;
  void Function(CardReadResult result)? _onAutoDiscovered;
  void Function(Object error)? _onAutoError;

  /// Whether the device supports NFC and has it enabled right now.
  Future<NfcAvailability> availability() async {
    try {
      return await NfcManager.instance.checkAvailability();
    } catch (_) {
      return NfcAvailability.unsupported;
    }
  }

  /// Whether a background or active session is currently running.
  bool get isSessionActive => _sessionActive;

  /// Starts listening continuously for cards in the background.
  /// When a card is touched to the back of the phone, it is automatically
  /// read and delivered via [onCard] without needing to press any button.
  Future<void> startBackgroundListening({
    required void Function(CardReadResult result) onCard,
    void Function(Object error)? onError,
  }) async {
    if (_sessionActive) {
      return;
    }
    final NfcAvailability state = await availability();
    if (state != NfcAvailability.enabled) {
      return;
    }

    _onAutoDiscovered = onCard;
    _onAutoError = onError;
    _sessionActive = true;

    try {
      await NfcManager.instance.startSession(
        pollingOptions: const <NfcPollingOption>{NfcPollingOption.iso18092},
        onDiscovered: (NfcTag tag) async {
          try {
            final CardReadResult result = await _read(tag);
            _onAutoDiscovered?.call(result);
          } catch (error) {
            _onAutoError?.call(error);
          } finally {
            // Keep background listening alive by restarting session after tag handled
            await _endSession();
            _sessionActive = false;
            if (_onAutoDiscovered != null) {
              Future<void>.delayed(const Duration(milliseconds: 400), () {
                if (_onAutoDiscovered != null && !_sessionActive) {
                  startBackgroundListening(
                    onCard: _onAutoDiscovered!,
                    onError: _onAutoError,
                  );
                }
              });
            }
          }
        },
      );
    } catch (_) {
      _sessionActive = false;
    }
  }

  /// Stops background continuous listening.
  Future<void> stopBackgroundListening() async {
    _onAutoDiscovered = null;
    _onAutoError = null;
    await cancel();
  }

  /// Runs one read session.
  ///
  /// Polls for ISO 18092 (FeliCa) tags only, so Android does not open a
  /// browser for NDEF tags. Completes as soon as one card has been read or
  /// [timeout] elapses, and always tears the session down.
  Future<CardReadResult> scan({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (_sessionActive) {
      throw NfcException(NfcError.busy);
    }
    final NfcAvailability state = await availability();
    switch (state) {
      case NfcAvailability.unsupported:
        throw NfcException(NfcError.unsupported);
      case NfcAvailability.disabled:
        throw NfcException(NfcError.disabled);
      case NfcAvailability.enabled:
        break;
    }

    final Completer<CardReadResult> completer = Completer<CardReadResult>();
    Timer? timer;
    _sessionActive = true;
    _pending = completer;

    try {
      await NfcManager.instance.startSession(
        pollingOptions: const <NfcPollingOption>{NfcPollingOption.iso18092},
        onDiscovered: (NfcTag tag) async {
          try {
            final CardReadResult result = await _read(tag);
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          } catch (error, stack) {
            if (!completer.isCompleted) {
              completer.completeError(error, stack);
            }
          } finally {
            await _endSession();
          }
        },
      );

      timer = Timer(timeout, () async {
        await _endSession();
        if (!completer.isCompleted) {
          completer.completeError(NfcException(NfcError.timeout));
        }
      });

      return await completer.future;
    } finally {
      timer?.cancel();
      _sessionActive = false;
      _pending = null;
      // Belt and braces: a session left open blocks the next scan.
      await _endSession();
    }
  }

  /// Aborts an in-flight scan. Safe to call when nothing is running.
  Future<void> cancel() async {
    final Completer<CardReadResult>? pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(NfcException(NfcError.cancelled));
    }
    await _endSession();
  }

  Future<CardReadResult> _read(NfcTag tag) async {
    final NfcFAndroid? nfcF = NfcFAndroid.from(tag);
    if (nfcF == null) {
      throw NfcException(NfcError.notFelica);
    }
    final Uint8List idm = nfcF.tag.id;
    if (idm.length != 8) {
      throw NfcException(NfcError.notFelica);
    }
    try {
      final CardReadResult result =
          await FelicaReader(_NfcFTransceiver(nfcF, idm)).readTransactionHistory();
      if (result.hasError && result.transactions.isEmpty) {
        throw NfcException(NfcError.incompleteRead, result.error);
      }
      return result;
    } on CardTransceiverException catch (error) {
      throw NfcException(NfcError.incompleteRead, error);
    } on NfcException {
      rethrow;
    } catch (error) {
      throw NfcException(NfcError.io, error);
    }
  }

  Future<void> _endSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // Stopping a session that is already gone is not an error.
    }
  }
}

/// Adapts an Android FeliCa tag to the reader's transport interface.
class _NfcFTransceiver implements CardTransceiver {
  _NfcFTransceiver(this._nfcF, this.idm);

  final NfcFAndroid _nfcF;

  @override
  final Uint8List idm;

  @override
  Future<Uint8List> transceive(Uint8List command) async {
    try {
      return await _nfcF.transceive(command);
    } catch (error) {
      throw CardTransceiverException(error.toString());
    }
  }
}
