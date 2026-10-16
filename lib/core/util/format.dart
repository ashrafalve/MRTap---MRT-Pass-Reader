/// Number, money and date formatting.
///
/// Written by hand rather than pulled from `intl` so the app has exactly one
/// source of truth for Bangla digits and month names and no locale-data
/// initialisation to forget. Card timestamps only carry an hour, so every
/// formatter here deliberately renders minutes as `:00` rather than implying a
/// precision the card does not have.
library;

const List<String> _enMonths = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _bnMonths = <String>[
  'জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে',
];

const List<String> _bnDigits = <String>['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Replaces ASCII digits with Bangla ones when [language] is `bn`.
String localizeDigits(String value, String language) {
  if (language != 'bn') {
    return value;
  }
  final StringBuffer buffer = StringBuffer();
  for (final String ch in value.split('')) {
    final int index = '0123456789'.indexOf(ch);
    buffer.write(index >= 0 ? _bnDigits[index] : ch);
  }
  return buffer.toString();
}

/// Inserts thousands separators into an integer.
String groupThousands(int value) {
  final bool negative = value < 0;
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return (negative ? '-' : '') + buffer.toString();
}

/// Formats an amount as Taka, e.g. `৳1,250` or `৳89`.
///
/// Dhaka Metro Rail cards (MRT Pass & Rapid Pass) store balance and transactions
/// in whole Taka integers directly.
String formatTaka(int taka, String language, {bool withSymbol = true}) {
  final String text = groupThousands(taka);
  return (withSymbol ? '৳' : '') + localizeDigits(text, language);
}

String _month(int month, String language) =>
    (language == 'bn' ? _bnMonths : _enMonths)[month - 1];

/// `15 Oct 2026, 09:00` — hour-accurate, as stored on the card.
String formatCardTime(int epochMillis, String language) {
  final DateTime t = DateTime.fromMillisecondsSinceEpoch(epochMillis);
  final String text =
      '${t.day} ${_month(t.month, language)} ${t.year}, ${t.hour.toString().padLeft(2, '0')}:00';
  return localizeDigits(text, language);
}

/// `15 Oct 2026` — the date part only, used as a list group header.
String formatDateOnly(int epochMillis, String language) {
  final DateTime t = DateTime.fromMillisecondsSinceEpoch(epochMillis);
  return localizeDigits('${t.day} ${_month(t.month, language)} ${t.year}', language);
}

/// Day key used to group transactions, e.g. `2026-10-15`.
String dateKey(int epochMillis) {
  final DateTime t = DateTime.fromMillisecondsSinceEpoch(epochMillis);
  return '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
}

/// Formats a balance for the big readout, omitting the symbol.
String formatTakaBare(int paisa, String language) =>
    formatTaka(paisa, language, withSymbol: false);
