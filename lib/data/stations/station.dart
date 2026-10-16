/// One station on MRT Line 6.
///
/// Only facts that are public and verifiable are carried: the card code that
/// appears in a FeliCa history block, the position on the line, the bilingual
/// names and whether the station is open to passengers. Interchange partners,
/// opening times and facilities are deliberately absent — they are not
/// verified and inventing them would mislead a traveller.
class Station {
  const Station({
    required this.id,
    required this.code,
    required this.order,
    required this.nameEn,
    required this.nameBn,
    required this.operational,
  });

  /// Stable slug, used as a key everywhere in the app.
  final String id;

  /// Numeric code stored in the card's history block (byte 8 / byte 10).
  ///
  /// `null` for Kamalapur, which has no published code because the station is
  /// still under construction.
  final int? code;

  /// Position on the line, 0 at Uttara North. Matches the fare-chart order.
  final int order;

  final String nameEn;
  final String nameBn;

  /// True for the 16 stations that are open to passengers today.
  final bool operational;

  String name(String languageCode) => languageCode == 'bn' ? nameBn : nameEn;

  @override
  bool operator ==(Object other) => other is Station && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Station($id, code=$code, order=$order)';
}

/// MRT Line 6 stations, north to south.
///
/// The 16 operational stations are ordered exactly as they appear in the
/// published fare chart. Kamalapur is listed for completeness but is excluded
/// from the fare calculator until it opens.
const List<Station> kStations = <Station>[
  Station(
    id: 'uttara-north',
    code: 90,
    order: 0,
    nameEn: 'Uttara North',
    nameBn: 'উত্তরা উত্তর',
    operational: true,
  ),
  Station(
    id: 'uttara-center',
    code: 85,
    order: 1,
    nameEn: 'Uttara Center',
    nameBn: 'উত্তরা সেন্টার',
    operational: true,
  ),
  Station(
    id: 'uttara-south',
    code: 80,
    order: 2,
    nameEn: 'Uttara South',
    nameBn: 'উত্তরা দক্ষিণ',
    operational: true,
  ),
  Station(
    id: 'pallabi',
    code: 75,
    order: 3,
    nameEn: 'Pallabi',
    nameBn: 'পল্লবী',
    operational: true,
  ),
  Station(
    id: 'mirpur-11',
    code: 70,
    order: 4,
    nameEn: 'Mirpur 11',
    nameBn: 'মিরপুর ১১',
    operational: true,
  ),
  Station(
    id: 'mirpur-10',
    code: 65,
    order: 5,
    nameEn: 'Mirpur 10',
    nameBn: 'মিরপুর ১০',
    operational: true,
  ),
  Station(
    id: 'kazipara',
    code: 60,
    order: 6,
    nameEn: 'Kazipara',
    nameBn: 'কাজীপাড়া',
    operational: true,
  ),
  Station(
    id: 'shewrapara',
    code: 55,
    order: 7,
    nameEn: 'Shewrapara',
    nameBn: 'শেওড়াপাড়া',
    operational: true,
  ),
  Station(
    id: 'agargaon',
    code: 50,
    order: 8,
    nameEn: 'Agargaon',
    nameBn: 'আগারগাঁও',
    operational: true,
  ),
  Station(
    id: 'bijoy-sarani',
    code: 45,
    order: 9,
    nameEn: 'Bijoy Sarani',
    nameBn: 'বিজয় সরণি',
    operational: true,
  ),
  Station(
    id: 'farmgate',
    code: 40,
    order: 10,
    nameEn: 'Farmgate',
    nameBn: 'ফার্মগেট',
    operational: true,
  ),
  Station(
    id: 'karwan-bazar',
    code: 35,
    order: 11,
    nameEn: 'Karwan Bazar',
    nameBn: 'কারওয়ান বাজার',
    operational: true,
  ),
  Station(
    id: 'shahbagh',
    code: 30,
    order: 12,
    nameEn: 'Shahbagh',
    nameBn: 'শাহবাগ',
    operational: true,
  ),
  Station(
    id: 'dhaka-university',
    code: 25,
    order: 13,
    nameEn: 'Dhaka University',
    nameBn: 'ঢাকা বিশ্ববিদ্যালয়',
    operational: true,
  ),
  Station(
    id: 'bangladesh-secretariat',
    code: 20,
    order: 14,
    nameEn: 'Bangladesh Secretariat',
    nameBn: 'বাংলাদেশ সচিবালয়',
    operational: true,
  ),
  Station(
    id: 'motijheel',
    code: 10,
    order: 15,
    nameEn: 'Motijheel',
    nameBn: 'মতিঝিল',
    operational: true,
  ),
  Station(
    id: 'kamalapur',
    code: null,
    order: 16,
    nameEn: 'Kamalapur',
    nameBn: 'কমলাপুর',
    operational: false,
  ),
];

/// Stations a passenger can actually buy a ticket to or from.
List<Station> get kOperationalStations =>
    kStations.where((Station s) => s.operational).toList(growable: false);

/// Hatirjheel bus stops that appear on Rapid Pass cards.
///
/// MRT Line 6 stations use the codes above; these five codes belong to the
/// Hatirjheel bus service and are kept so a bus leg on a card is not shown as
/// "unknown station".
const Map<int, String> kBhatirjheelBusCodes = <int, String>{
  13: 'Mohanagar',
  16: 'Rampura',
  17: 'Badda',
  19: 'Police Plaza',
  28: 'FDC',
};

/// Looks up a station by its card code.
///
/// Returns `null` when the code is not recognised; callers surface the raw
/// number rather than inventing a name.
Station? stationByCode(int? code) {
  if (code == null) {
    return null;
  }
  for (final Station s in kStations) {
    if (s.code == code) {
      return s;
    }
  }
  return null;
}

Station? stationById(String? id) {
  if (id == null) {
    return null;
  }
  for (final Station s in kStations) {
    if (s.id == id) {
      return s;
    }
  }
  return null;
}

/// English label for a card code, including the Hatirjheel bus stops.
///
/// Falls back to a visible placeholder carrying the raw code so nothing is
/// ever silently dropped.
String labelForCode(int code) {
  final Station? s = stationByCode(code);
  if (s != null) {
    return s.nameEn;
  }
  final String? bus = kBhatirjheelBusCodes[code];
  if (bus != null) {
    return '$bus (Hatirjheel)';
  }
  return 'Unknown ($code)';
}
