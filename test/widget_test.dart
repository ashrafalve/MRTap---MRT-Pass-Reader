import 'package:flutter_test/flutter_test.dart';
import 'package:mrtap/core/app_info.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/util/format.dart';
import 'package:mrtap/data/fares/fare_data.dart';
import 'package:mrtap/data/stations/station.dart';
import 'package:mrtap/nfc/felica/transaction_parser.dart';
import 'package:mrtap/nfc/felica/transaction_record.dart';
import 'dart:typed_data';

void main() {
  test('localization has same keys in en and bn', () {
    final Set<String> en = Strings.englishMap.keys.toSet();
    final Set<String> bn = Strings.banglaMap.keys.toSet();
    expect(bn.containsAll(en), isTrue);
    expect(en.containsAll(bn), isTrue);
  });

  test('fare chart is symmetric and monotonic with distance', () {
    final int n = kFareMatrix.length;
    for (int i = 0; i < n; i++) {
      expect(kFareMatrix[i][i], 0);
      for (int j = 0; j < n; j++) {
        expect(kFareMatrix[i][j], kFareMatrix[j][i]);
      }
      for (int j = i + 1; j < n; j++) {
        expect(kFareMatrix[i][j] >= kFareMatrix[i][j - 1] || kFareMatrix[i][j - 1] == 0, isTrue);
      }
    }
  });

  test('fare spot checks', () {
    final int un = kStations[0].order; // Uttara North
    final int sc = kStations[14].order; // Secretariat
    final int fg = kStations[10].order; // Farmgate
    expect(kFareMatrix[un][sc], 90);
    expect(kFareMatrix[un][fg], 70);
    expect(FareRules.minFare, 20);
    expect(FareRules.maxFare, 100);
  });

  test('timestamp decode uses base 2000', () {
    // encodeTimestamp from fixture: 2024-07-15 14:00 -> offset 24, month 7, day 15, hour 14
    // encoded: (24<<17)|(7<<13)|(15<<8)|(14<<3)
    final int ts = (24 << 17) | (7 << 13) | (15 << 8) | (14 << 3);
    final DateTime? d = TransactionParser.decodeTimestamp(ts);
    expect(d != null, isTrue);
    expect(d!.year, 2024);
    expect(d.month, 7);
    expect(d.day, 15);
    expect(d.hour, 14);
    expect(d.minute, 0);
  });

  test('transaction parser handles pre-2020 block', () {
    // build minimal metro block with pre-2020 timestamp (2015)
    final Uint8List block = Uint8List(FelicaSpec.blockSize);
    block[0] = 0x08; block[1] = 0x52; block[2] = 0x10; block[3] = 0x00;
    final int pre2020Ts = (15 << 17) | (3 << 13) | (10 << 8) | (9 << 3);
    block[4] = (pre2020Ts >> 16) & 0xFF;
    block[5] = (pre2020Ts >> 8) & 0xFF;
    block[6] = pre2020Ts & 0xFF;
    block[8] = 90; block[9] = 0; block[10] = 10;
    block[11] = 50; block[12] = 0; block[13] = 0; // 50 paisa? not relevant
    final ParsedTransaction p = TransactionParser.parseBlock(block);
    expect(p.isValid, isFalse);
  });

  test('formatTaka handles language', () {
    final String en = formatTaka(89, 'en');
    final String bn = formatTaka(89, 'bn');
    expect(en, '৳89');
    expect(bn, '৳৮৯');
  });
}