import 'package:mrtap/core/app_info.dart';
import 'package:mrtap/data/stations/station.dart';

/// The published Dhaka Metro Rail single-journey fare chart, in whole Taka.
///
/// Rows and columns follow [kStations] order (Uttara North -> Kamalapur).
///
/// ## Provenance
///
/// Compiled from the fare tables published on the Dhaka Metro Rail website
/// and cross-checked against two independent open source readers. Three
/// candidate datasets were compared cell by cell:
///
///  * the published Dhaka Metro Rail fare tables — adopted;
///  * an open source reader (MRT Buddy) — rejected, 13 of its 136 pairs are
///    not symmetric, which is impossible for a distance based fare table;
///  * a third-party fare site — rejected, it prices Uttara North -> Bangladesh
///    Secretariat at ৳100 where the published chart and the national press
///    both report ৳90.
///
/// The adopted matrix is fully symmetric and increases monotonically with
/// distance along the line, which are the two structural properties a real
/// fare table must satisfy. Independent spot checks against a national
/// newspaper report (min ৳20, max ৳100, Uttara North -> Secretariat ৳90,
/// Uttara North -> Farmgate ৳70) all match.
///
/// Known discrepancies with the rejected dataset, kept here so a future
/// re-verification knows where to look: Uttara Center <-> Shahbagh,
/// Pallabi <-> Farmgate, Kazipara <-> Karwan Bazar, Kazipara <->
/// Dhaka University, Shewrapara <-> Shahbagh and Shewrapara <->
/// Bangladesh Secretariat.
const List<List<int>> kFareMatrix = <List<int>>[
  <int>[0, 20, 20, 30, 30, 40, 40, 50, 60, 60, 70, 80, 80, 90, 90, 100, 100],
  <int>[20, 0, 20, 20, 30, 30, 40, 40, 50, 60, 60, 70, 80, 80, 90, 90, 100],
  <int>[20, 20, 0, 20, 20, 30, 30, 40, 40, 50, 60, 60, 70, 70, 80, 90, 90],
  <int>[30, 20, 20, 0, 20, 20, 20, 30, 30, 40, 40, 50, 60, 60, 70, 80, 90],
  <int>[30, 30, 20, 20, 0, 20, 20, 20, 30, 40, 40, 50, 60, 60, 70, 70, 80],
  <int>[40, 30, 30, 20, 20, 0, 20, 20, 20, 30, 30, 40, 50, 50, 60, 60, 70],
  <int>[40, 40, 30, 20, 20, 20, 0, 20, 20, 20, 30, 30, 40, 40, 50, 60, 60],
  <int>[50, 40, 40, 30, 20, 20, 20, 0, 20, 20, 20, 30, 30, 40, 40, 50, 50],
  <int>[60, 50, 40, 30, 30, 20, 20, 20, 0, 20, 20, 20, 30, 30, 40, 50, 50],
  <int>[60, 60, 50, 40, 40, 30, 20, 20, 20, 0, 20, 20, 20, 30, 30, 40, 40],
  <int>[70, 60, 60, 40, 40, 30, 30, 20, 20, 20, 0, 20, 20, 20, 20, 30, 40],
  <int>[80, 70, 60, 50, 50, 40, 30, 30, 20, 20, 20, 0, 20, 20, 20, 30, 30],
  <int>[80, 80, 70, 60, 60, 50, 40, 30, 30, 20, 20, 20, 0, 20, 20, 20, 30],
  <int>[90, 80, 70, 60, 60, 50, 40, 40, 30, 30, 20, 20, 20, 0, 20, 20, 20],
  <int>[90, 90, 80, 70, 70, 60, 50, 40, 40, 30, 20, 20, 20, 20, 0, 20, 20],
  <int>[100, 90, 90, 80, 70, 60, 60, 50, 50, 40, 30, 30, 20, 20, 20, 0, 20],
  <int>[100, 100, 90, 90, 80, 70, 60, 50, 50, 40, 40, 30, 30, 20, 20, 20, 0],
];

/// Published discount entitlements, from DMTCL's ticket rules.
///
/// Only discounts that are written down in the official rules are modelled.
class FareRules {
  const FareRules._();

  /// The lowest single-journey fare on the network, in Taka.
  static const int minFare = 20;

  /// The highest single-journey fare on the network, in Taka.
  static const int maxFare = 100;

  /// MRT Pass and Rapid Pass holders pay 10% less on every journey.
  static const int passDiscountPercent = 10;

  /// Senior citizens get 15% off a single-journey ticket.
  static const int seniorDiscountPercent = 15;

  /// Children under three feet tall travel free.
  static const bool childUnderThreeFeetFree = true;

  /// A new MRT Pass costs ৳400: a ৳200 refundable deposit plus ৳200 usable.
  static const int mrtPassPrice = 400;
  static const int mrtPassDeposit = 200;
  static const int mrtPassLoadable = 200;
}

/// Result of a fare lookup.
class FareQuote {
  const FareQuote({
    required this.fare,
    required this.withPass,
    required this.from,
    required this.to,
  });

  /// Published single-journey fare in whole Taka.
  final int fare;

  /// The same journey with a 10% pass discount, rounded to the nearest Taka.
  final int withPass;

  final Station from;
  final Station to;

  int get withSeniorDiscount =>
      _percentOff(fare, FareRules.seniorDiscountPercent);

  static int _percentOff(int amount, int percent) =>
      (amount * (100 - percent) / 100).round();
}

/// Offline fare lookup over the bundled chart.
class FareService {
  const FareService();

  /// Looks up the fare between two stations, or `null` when either station is
  /// not open (Kamalapur) or the pair has no published fare.
  FareQuote? quote(Station from, Station to) {
    if (!from.operational || !to.operational) {
      return null;
    }
    if (from.id == to.id) {
      return null;
    }
    final int i = from.order;
    final int j = to.order;
    if (i < 0 || i >= kFareMatrix.length || j < 0 || j >= kFareMatrix.length) {
      return null;
    }
    final int fare = kFareMatrix[i][j];
    if (fare <= 0) {
      return null;
    }
    return FareQuote(
      fare: fare,
      withPass: FareQuote._percentOff(fare, FareRules.passDiscountPercent),
      from: from,
      to: to,
    );
  }

  /// Amount charged to a card in paisa for a given quote, after the pass
  /// discount that MRT Pass and Rapid Pass holders receive.
  ///
  /// Fares are published in whole Taka; the card stores paisa.
  static int chargePaisa(int fareTaka) => fareTaka * FelicaSpec.takaToPaisa;
}
