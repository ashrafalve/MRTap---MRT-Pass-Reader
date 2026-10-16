/// Global, non-secret app constants.
///
/// Nothing here is sensitive: the FeliCa service code and the block layout are
/// public knowledge published by the card vendors and reused by every open
/// source reader. No credentials, no keys, no backend endpoints — MRTap is
/// offline-first by design.
library;

class AppInfo {
  const AppInfo._();

  static const String appName = 'MRTap';
  static const String appFullTitle = 'MRTap — MRT Pass Reader';

  /// Semver shown to the user. Keep in sync with `pubspec.yaml` version.
  static const String version = '1.0.0';

  /// Version of the bundled fare chart data, not the app.
  static const String fareDataVersion = '2026.10.1';

  /// When the bundled fare chart was last re-verified against sources.
  static const String fareDataLastVerified = '2026-10-15';

  /// ISO 4217 code for the display currency.
  static const String currencyCode = 'BDT';

  /// Symbol used when writing amounts. `intl` supplies this too, but the app
  /// also formats amounts without a [BuildContext], so the literal is kept.
  static const String currencySymbol = '৳';
}

/// FeliCa / Suica-family protocol constants used by Dhaka Metro MRT Pass and
/// Rapid Pass cards.
class FelicaSpec {
  const FelicaSpec._();

  /// Service code that holds the transaction history on both card types.
  ///
  /// Confirmed by every open source reader for the Dhaka Metro cards.
  static const int transactionServiceCode = 0x220F;

  /// A history record occupies one 16-byte block.
  static const int blockSize = 16;

  /// The card retains a rolling window of 20 records.
  ///
  /// Read as two 10-block windows: blocks 0-9 then 10-19.
  static const int blocksPerWindow = 10;
  static const List<int> readWindows = <int>[0, 10];

  /// Highest balance the card firmware accepts, in whole Taka.
  static const int maxBalance = 9999;

  /// Fares are expressed in whole Taka in the official chart.
  static const int takaToPaisa = 1;
}

/// Service codes seen in the fixed header (bytes 0-3) of a history block.
///
/// These classify a record as a journey, a Hatirjheel bus leg, or a balance
/// top-up. Anything else is surfaced to the user as unrecognised rather than
/// guessed at.
class TxnHeader {
  const TxnHeader._();

  /// Metro journey, MRT Pass and Rapid Pass alike.
  static const String metro = '08 52 10 00';

  /// Rapid Pass — Hatirjheel bus, boarding.
  static const String busStart = '08 D2 20 00';

  /// Rapid Pass — Hatirjheel bus, alighting.
  static const String busEnd = '42 D6 30 00';

  /// Balance top-up, MRT Pass.
  static const String topUpMrt = '1D 60 02 01';

  /// Balance top-up, Rapid Pass.
  static const String topUpRapid = '42 60 02 00';
}
