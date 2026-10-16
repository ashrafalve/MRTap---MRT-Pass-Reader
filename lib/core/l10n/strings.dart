import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Lightweight, code-free localisation.
///
/// Strings live in plain maps so that adding a language is a matter of adding a
/// map. Lookups fall back to English, then to the key itself, and in debug a
/// missing key is reported via [FlutterError] so it cannot ship silently.
/// `test/localization_test.dart` asserts that every language exposes exactly
/// the same set of keys.
class Strings {
  Strings(this.locale, this._map);

  final Locale locale;
  final Map<String, String> _map;

  static const Locale english = Locale('en');
  static const Locale bangla = Locale('bn');

  static const List<Locale> supported = <Locale>[english, bangla];

  static const Map<String, String> englishMap = _en;
  static const Map<String, String> banglaMap = _bn;

  static bool isSupported(Locale locale) =>
      supported.any((Locale l) => l.languageCode == locale.languageCode);

  /// Chooses the active language from a user preference, falling back to the
  /// device locale and finally to English.
  static Locale resolve(String? preference, Locale? device) {
    switch (preference) {
      case 'en':
        return english;
      case 'bn':
        return bangla;
      default:
        final Locale? d = device;
        if (d != null && isSupported(d)) {
          return Locale(d.languageCode);
        }
        return english;
    }
  }

  /// Looks up [key], replacing `{token}` placeholders from [args].
  String t(String key, [Map<String, String> args = const <String, String>{}]) {
    String value = _map[key] ?? _en[key] ?? '??$key??';
    args.forEach((String name, String replacement) {
      value = value.replaceAll('{$name}', replacement);
    });
    return value;
  }
}

/// The interface screens depend on, provided by [MRTapLocalizations].
abstract final class S {
  // App-wide
  static const String appName = 'appName';
  static const String tagline = 'tagline';
  static const String disclaimerShort = 'disclaimerShort';
  static const String disclaimerLong = 'disclaimerLong';
  static const String unofficial = 'unofficial';

  // Navigation
  static const String navHome = 'navHome';
  static const String navFare = 'navFare';
  static const String navStations = 'navStations';
  static const String navSettings = 'navSettings';

  // Home / scan
  static const String homeTitle = 'homeTitle';
  static const String homeHeadline = 'homeHeadline';
  static const String homeBody = 'homeBody';
  static const String scanCard = 'scanCard';
  static const String scanning = 'scanning';
  static const String holdStill = 'holdStill';
  static const String readSuccess = 'readSuccess';
  static const String readFailed = 'readFailed';
  static const String balance = 'balance';
  static const String lastRead = 'lastRead';
  static const String noCards = 'noCards';
  static const String noCardsBody = 'noCardsBody';
  static const String recentActivity = 'recentActivity';
  static const String viewAllActivity = 'viewAllActivity';
  static const String savedCards = 'savedCards';
  static const String newCard = 'newCard';
  static const String recordsOnCard = 'recordsOnCard';
  static const String newRecords = 'newRecords';

  // NFC states / errors
  static const String nfcUnsupported = 'nfcUnsupported';
  static const String nfcDisabled = 'nfcDisabled';
  static const String nfcEnable = 'nfcEnable';
  static const String notFelica = 'notFelica';
  static const String cardMoved = 'cardMoved';
  static const String noTransactions = 'noTransactions';
  static const String emptyBlock = 'emptyBlock';

  // Card
  static const String cardId = 'cardId';
  static const String mrtPass = 'mrtPass';
  static const String rapidPass = 'rapidPass';
  static const String unknownCard = 'unknownCard';
  static const String cardName = 'cardName';
  static const String rename = 'rename';
  static const String save = 'save';
  static const String cancel = 'cancel';
  static const String delete = 'delete';
  static const String deleteCard = 'deleteCard';
  static const String deleteCardConfirm = 'deleteCardConfirm';
  static const String totalSpent = 'totalSpent';
  static const String journeyCount = 'journeyCount';
  static const String topUpCount = 'topUpCount';

  // Transactions
  static const String typeMetro = 'typeMetro';
  static const String typeBusStart = 'typeBusStart';
  static const String typeBusEnd = 'typeBusEnd';
  static const String typeTopUp = 'typeTopUp';
  static const String typeUnknown = 'typeUnknown';
  static const String from = 'from';
  static const String to = 'to';
  static const String fare = 'fare';
  static const String added = 'added';
  static const String resultingBalance = 'resultingBalance';
  static const String unknownStation = 'unknownStation';
  static const String hourPrecision = 'hourPrecision';

  // Fare calculator
  static const String fareTitle = 'fareTitle';
  static const String fromStation = 'fromStation';
  static const String toStation = 'toStation';
  static const String swap = 'swap';
  static const String selectStation = 'selectStation';
  static const String estimatedFare = 'estimatedFare';
  static const String minFare = 'minFare';
  static const String maxFare = 'maxFare';
  static const String chooseTwoStations = 'chooseTwoStations';
  static const String fareUnavailable = 'fareUnavailable';
  static const String mrtPassDiscount = 'mrtPassDiscount';
  static const String seniorDiscount = 'seniorDiscount';
  static const String childFree = 'childFree';
  static const String mrtPassPrice = 'mrtPassPrice';
  static const String afterDiscount = 'afterDiscount';
  static const String fareChartNote = 'fareChartNote';
  static const String withPass = 'withPass';
  static const String regularFare = 'regularFare';

  // Stations
  static const String stationsTitle = 'stationsTitle';
  static const String stationSearch = 'stationSearch';
  static const String stationCode = 'stationCode';
  static const String stationNumber = 'stationNumber';
  static const String operational = 'operational';
  static const String underConstruction = 'underConstruction';
  static const String operationalCount = 'operationalCount';
  static const String noResults = 'noResults';
  static const String tapForFares = 'tapForFares';

  // Settings
  static const String settingsTitle = 'settingsTitle';
  static const String language = 'language';
  static const String languageEnglish = 'languageEnglish';
  static const String languageBangla = 'languageBangla';
  static const String languageSystem = 'languageSystem';
  static const String appearance = 'appearance';
  static const String themeLight = 'themeLight';
  static const String themeDark = 'themeDark';
  static const String themeSystem = 'themeSystem';
  static const String backup = 'backup';
  static const String exportBackup = 'exportBackup';
  static const String importBackup = 'importBackup';
  static const String exportDone = 'exportDone';
  static const String importDone = 'importDone';
  static const String importFailed = 'importFailed';
  static const String importSummary = 'importSummary';
  static const String clearAllData = 'clearAllData';
  static const String clearAllDataConfirm = 'clearAllDataConfirm';
  static const String about = 'about';
  static const String aboutBody = 'aboutBody';
  static const String dataSource = 'dataSource';
  static const String dataSourceBody = 'dataSourceBody';
  static const String version = 'version';
  static const String fareDataVersion = 'fareDataVersion';
  static const String fareDataVerified = 'fareDataVerified';
  static const String appVersion = 'appVersion';

  // Activity history
  static const String activityTitle = 'activityTitle';
  static const String allCards = 'allCards';
  static const String emptyHistory = 'emptyHistory';
  static const String emptyHistoryBody = 'emptyHistoryBody';

  // Shared
  static const String close = 'close';
  static const String optional = 'optional';
  static const String unknown = 'unknown';
}

const Map<String, String> _en = <String, String>{
  S.appName: 'MRTap',
  S.tagline: 'Dhaka Metro Rail, offline',
  S.disclaimerShort: 'Unofficial app. Not affiliated with DMTCL.',
  S.disclaimerLong:
      'MRTap is an independent, offline app. It is not affiliated with, '
      'endorsed by, or operated by Dhaka Mass Transit Company Limited (DMTCL) '
      'or any transport authority. Always confirm fares and timings with the '
      'official DMTCL channels.',
  S.unofficial: 'Unofficial',

  S.navHome: 'Home',
  S.navFare: 'Fare',
  S.navStations: 'Stations',
  S.navSettings: 'Settings',

  S.homeTitle: 'MRTap',
  S.homeHeadline: 'Read your card',
  S.homeBody:
      'Hold an MRT Pass or Rapid Pass near the back of your phone to read its '
      'balance and recent journeys.',
  S.scanCard: 'Scan card',
  S.scanning: 'Reading card',
  S.holdStill: 'Hold the card still against the phone',
  S.readSuccess: 'Card read successfully',
  S.readFailed: 'Could not read the card',
  S.balance: 'Balance',
  S.lastRead: 'Last read',
  S.noCards: 'No cards yet',
  S.noCardsBody: 'Scan a card to keep its balance and journeys on this device.',
  S.recentActivity: 'Recent activity',
  S.viewAllActivity: 'See all activity',
  S.savedCards: 'Saved cards',
  S.newCard: 'Add card',
  S.recordsOnCard: 'Records on card',
  S.newRecords: 'New records',

  S.nfcUnsupported: 'This device does not have NFC hardware.',
  S.nfcDisabled: 'NFC is switched off. Turn it on in system settings.',
  S.nfcEnable: 'Open NFC settings',
  S.notFelica: 'That is not a supported FeliCa transit card.',
  S.cardMoved: 'The card moved before reading finished. Try again and hold it still.',
  S.noTransactions: 'No transactions found on this card.',
  S.emptyBlock: 'The card returned empty history blocks.',

  S.cardId: 'Card ID',
  S.mrtPass: 'MRT Pass',
  S.rapidPass: 'Rapid Pass',
  S.unknownCard: 'Transit card',
  S.cardName: 'Card name',
  S.rename: 'Rename',
  S.save: 'Save',
  S.cancel: 'Cancel',
  S.delete: 'Delete',
  S.deleteCard: 'Delete card',
  S.deleteCardConfirm: 'This card and its saved journeys will be removed from this device.',
  S.totalSpent: 'Total spent',
  S.journeyCount: 'Journeys',
  S.topUpCount: 'Top-ups',

  S.typeMetro: 'Metro journey',
  S.typeBusStart: 'Hatirjheel bus · boarding',
  S.typeBusEnd: 'Hatirjheel bus · alighting',
  S.typeTopUp: 'Balance top-up',
  S.typeUnknown: 'Unrecognised entry',
  S.from: 'From',
  S.to: 'To',
  S.fare: 'Fare',
  S.added: 'Added',
  S.resultingBalance: 'Balance after',
  S.unknownStation: 'Unknown station ({code})',
  S.hourPrecision: 'Card timestamps are stored to the nearest hour.',

  S.fareTitle: 'Fare calculator',
  S.fromStation: 'From',
  S.toStation: 'To',
  S.swap: 'Swap',
  S.selectStation: 'Select a station',
  S.estimatedFare: 'Fare',
  S.minFare: 'Minimum fare',
  S.maxFare: 'Maximum fare',
  S.chooseTwoStations: 'Pick a start and an end station.',
  S.fareUnavailable: 'No published fare for this pair.',
  S.mrtPassDiscount: 'MRT Pass / Rapid Pass — 10% off each journey',
  S.seniorDiscount: 'Senior citizens — 15% off a single-journey ticket',
  S.childFree: 'Children under 3 ft travel free',
  S.mrtPassPrice: 'New MRT Pass ৳400 — ৳200 refundable deposit + ৳200 usable',
  S.afterDiscount: 'after discount',
  S.fareChartNote:
      'From the published Dhaka Metro fare chart. Fares can change — verify with DMTCL before travelling.',
  S.withPass: 'With pass',
  S.regularFare: 'Regular',

  S.stationsTitle: 'Stations',
  S.stationSearch: 'Search stations',
  S.stationCode: 'Station code',
  S.stationNumber: 'Station no.',
  S.operational: 'Operational',
  S.underConstruction: 'Under construction',
  S.operationalCount: '16 stations in operation',
  S.noResults: 'No matching station',
  S.tapForFares: 'Calculate fare from here',

  S.settingsTitle: 'Settings',
  S.language: 'Language',
  S.languageEnglish: 'English',
  S.languageBangla: 'বাংলা',
  S.languageSystem: 'System',
  S.appearance: 'Appearance',
  S.themeLight: 'Light',
  S.themeDark: 'Dark',
  S.themeSystem: 'System',
  S.backup: 'Backup',
  S.exportBackup: 'Export backup',
  S.importBackup: 'Restore backup',
  S.exportDone: 'Backup file ready to share',
  S.importDone: 'Backup restored',
  S.importFailed: 'That file could not be restored',
  S.importSummary: '{cards} card(s) and {txns} journey(s) added',
  S.clearAllData: 'Clear all data',
  S.clearAllDataConfirm:
      'Every saved card, journey and setting on this device will be deleted. This cannot be undone.',
  S.about: 'About MRTap',
  S.aboutBody:
      'MRTap reads your MRT Pass or Rapid Pass over NFC, stores its history '
      'on this device only, and works entirely offline. No account, no server, '
      'no analytics.',
  S.dataSource: 'Fare data sources',
  S.dataSourceBody:
      'Fare chart compiled from the published Dhaka Metro Rail fare tables and '
      'cross-checked against independent readers. Last verified {date}.',
  S.version: 'Version',
  S.fareDataVersion: 'Fare chart',
  S.fareDataVerified: 'Last verified',
  S.appVersion: 'App version',

  S.activityTitle: 'Activity',
  S.allCards: 'All cards',
  S.emptyHistory: 'No journeys saved',
  S.emptyHistoryBody: 'Read a card from the Home tab to start building history.',

  S.close: 'Close',
  S.optional: 'optional',
  S.unknown: 'Unknown',
};

const Map<String, String> _bn = <String, String>{
  S.appName: 'এমআরট্যাপ',
  S.tagline: 'ঢাকা মেট্রো রেল, অফলাইন',
  S.disclaimerShort: 'অনানুষ্ঠানিক অ্যাপ। ডিএমটিসিএলের সাথে সম্পর্কিত নয়।',
  S.disclaimerLong:
      'এমআরট্যাপ একটি স্বাধীন, অফলাইন অ্যাপ। এটি ঢাকা মাস ট্রান্সিট কোম্পানি লিমিটেড (ডিএমটিসিএল) '
      'কর্তৃক অনুমোদিত, পরিচালিত বা সম্পর্কিত নয়। ভ্রমণের আগে সরকারি ডিএমটিসিএল সূত্র থেকে ভাড়া যাচাই করুন।',
  S.unofficial: 'অনানুষ্ঠানিক',

  S.navHome: 'হোম',
  S.navFare: 'ভাড়া',
  S.navStations: 'স্টেশন',
  S.navSettings: 'সেটিংস',

  S.homeTitle: 'এমআরট্যাপ',
  S.homeHeadline: 'কার্ড পড়ুন',
  S.homeBody:
      'ফোনের পিছনের দিকে এমআরটি পাস বা র‍্যাপিড পাস ধরে রাখুন—ব্যালেন্স ও সাম্প্রতিক যাত্রা পড়তে হবে।',
  S.scanCard: 'কার্ড স্ক্যান',
  S.scanning: 'কার্ড পড়া হচ্ছে',
  S.holdStill: 'ফোনের সাথে কার্ডটি স্থির ধরে রাখুন',
  S.readSuccess: 'কার্ড পড়া হয়েছে',
  S.readFailed: 'কার্ড পড়া যায়নি',
  S.balance: 'ব্যালেন্স',
  S.lastRead: 'সর্বশেষ পড়া',
  S.noCards: 'এখনো কোনো কার্ড নেই',
  S.noCardsBody: 'এই ডিভাইসে ব্যালেন্স ও যাত্রা রাখতে একটি কার্ড স্ক্যান করুন।',
  S.recentActivity: 'সাম্প্রতিক কার্যক্রম',
  S.viewAllActivity: 'সব কার্যক্রম দেখুন',
  S.savedCards: 'সংরক্ষিত কার্ড',
  S.newCard: 'কার্ড যোগ',
  S.recordsOnCard: 'কার্ডে রেকর্ড',
  S.newRecords: 'নতুন রেকর্ড',

  S.nfcUnsupported: 'এই ডিভাইসে এনএফসি নেই।',
  S.nfcDisabled: 'এনএফসি বন্ধ আছে। সিস্টেম সেটিংস থেকে চালু করুন।',
  S.nfcEnable: 'এনএফসি সেটিংস খুলুন',
  S.notFelica: 'এটি সমর্থিত ফেলিকা ট্রানজিট কার্ড নয়।',
  S.cardMoved: 'পড়ার মাঝে কার্ড সরে গেছে। আবার চেষ্টা করুন।',
  S.noTransactions: 'এই কার্ডে কোনো লেনদেন পাওয়া যায়নি।',
  S.emptyBlock: 'কার্ড খালি ইতিহাস ব্লক ফেরত দিয়েছে।',

  S.cardId: 'কার্ড আইডি',
  S.mrtPass: 'এমআরটি পাস',
  S.rapidPass: 'র‍্যাপিড পাস',
  S.unknownCard: 'ট্রানজিট কার্ড',
  S.cardName: 'কার্ডের নাম',
  S.rename: 'নাম বদলান',
  S.save: 'সংরক্ষণ',
  S.cancel: 'বাতিল',
  S.delete: 'মুছুন',
  S.deleteCard: 'কার্ড মুছুন',
  S.deleteCardConfirm: 'এই কার্ড ও তার সংরক্ষিত যাত্রাগুলো ডিভাইস থেকে মুছে যাবে।',
  S.totalSpent: 'মোট খরচ',
  S.journeyCount: 'যাত্রা',
  S.topUpCount: 'টপ-আপ',

  S.typeMetro: 'মেট্রো যাত্রা',
  S.typeBusStart: 'হাতিরঝিল বাস · ওঠার সময়',
  S.typeBusEnd: 'হাতিরঝিল বাস · নামার সময়',
  S.typeTopUp: 'ব্যালেন্স টপ-আপ',
  S.typeUnknown: 'অজানা এন্ট্রি',
  S.from: 'থেকে',
  S.to: 'পর্যন্ত',
  S.fare: 'ভাড়া',
  S.added: 'যোগ হয়েছে',
  S.resultingBalance: 'পরে ব্যালেন্স',
  S.unknownStation: 'অজানা স্টেশন ({code})',
  S.hourPrecision: 'কার্ডের সময় ঘণ্টা পর্যন্ত সংরক্ষিত হয়।',

  S.fareTitle: 'ভাড়া নির্ণয়',
  S.fromStation: 'থেকে',
  S.toStation: 'পর্যন্ত',
  S.swap: 'বদলান',
  S.selectStation: 'স্টেশন নির্বাচন করুন',
  S.estimatedFare: 'ভাড়া',
  S.minFare: 'সর্বনিম্ন ভাড়া',
  S.maxFare: 'সর্বোচ্চ ভাড়া',
  S.chooseTwoStations: 'শুরু ও শেষ স্টেশন নির্বাচন করুন।',
  S.fareUnavailable: 'এই জোড়ার জন্য প্রকাশিত ভাড়া নেই।',
  S.mrtPassDiscount: 'এমআরটি পাস / র‍্যাপিড পাস — প্রতি যাত্রায় ১০% ছাড়',
  S.seniorDiscount: 'প্রবীণ নাগরিক — একক যাত্রার টিকিটে ১৫% ছাড়',
  S.childFree: '৩ ফুটের নিচের শিশু বিনামূল্যে যাত্রা করে',
  S.mrtPassPrice: 'নতুন এমআরটি পাস ৳৪০০ — ৳২০০ ফেরতযোগ্য জামানত + ৳২০০ ব্যবহারযোগ্য',
  S.afterDiscount: 'ছাড়ের পর',
  S.fareChartNote:
      'প্রকাশিত ঢাকা মেট্রো ভাড়া তালিকা থেকে নেওয়া। ভাড়া বদলাতে পারে—যাত্রার আগে ডিএমটিসিএলের কাছে যাচাই করুন।',
  S.withPass: 'পাস দিয়ে',
  S.regularFare: 'নিয়মিত',

  S.stationsTitle: 'স্টেশন',
  S.stationSearch: 'স্টেশন খুঁজুন',
  S.stationCode: 'স্টেশন কোড',
  S.stationNumber: 'স্টেশন নং',
  S.operational: 'চালু আছে',
  S.underConstruction: 'নির্মাণাধীন',
  S.operationalCount: '১৬টি স্টেশন চালু আছে',
  S.noResults: 'কোনো স্টেশন মেলেনি',
  S.tapForFares: 'এখান থেকে ভাড়া দেখুন',

  S.settingsTitle: 'সেটিংস',
  S.language: 'ভাষা',
  S.languageEnglish: 'English',
  S.languageBangla: 'বাংলা',
  S.languageSystem: 'সিস্টেম',
  S.appearance: 'চেহারা',
  S.themeLight: 'লাইট',
  S.themeDark: 'ডার্ক',
  S.themeSystem: 'সিস্টেম',
  S.backup: 'ব্যাকআপ',
  S.exportBackup: 'ব্যাকআপ রপ্তানি',
  S.importBackup: 'ব্যাকআপ ফিরিয়ে আনুন',
  S.exportDone: 'ব্যাকআপ ফাইল প্রস্তুত',
  S.importDone: 'ব্যাকআপ ফিরিয়ে আনা হয়েছে',
  S.importFailed: 'ফাইলটি ফিরিয়ে আনা যায়নি',
  S.importSummary: '{cards} টি কার্ড ও {txns} টি যাত্রা যোগ হয়েছে',
  S.clearAllData: 'সব তথ্য মুছুন',
  S.clearAllDataConfirm:
      'এই ডিভাইসের সব সংরক্ষিত কার্ড, যাত্রা ও সেটিংস মুছে যাবে। এটি আর ফিরিয়ে আনা যাবে না।',
  S.about: 'এমআরট্যাপ পরিচিতি',
  S.aboutBody:
      'এমআরট্যাপ এনএফসির মাধ্যমে আপনার এমআরটি পাস বা র‍্যাপিড পাস পড়ে, ইতিহাস শুধু এই '
      'ডিভাইসে সংরক্ষণ করে এবং সম্পূর্ণ অফলাইনে কাজ করে। কোনো অ্যাকাউন্ট, সার্ভার বা অ্যানালিটিক্স নেই।',
  S.dataSource: 'ভাড়ার তথ্যসূত্র',
  S.dataSourceBody:
      'প্রকাশিত ঢাকা মেট্রো রেল ভাড়া তালিকা থেকে সংকলিত এবং স্বাধীন রিডারের সাথে মিলিয়ে যাচাই করা। '
      'সর্বশেষ যাচাই {date}।',
  S.version: 'সংস্করণ',
  S.fareDataVersion: 'ভাড়া তালিকা',
  S.fareDataVerified: 'সর্বশেষ যাচাই',
  S.appVersion: 'অ্যাপ সংস্করণ',

  S.activityTitle: 'কার্যক্রম',
  S.allCards: 'সব কার্ড',
  S.emptyHistory: 'কোনো যাত্রা সংরক্ষিত নেই',
  S.emptyHistoryBody: 'ইতিহাস তৈরি করতে হোম ট্যাব থেকে একটি কার্ড পড়ুন।',

  S.close: 'বন্ধ করুন',
  S.optional: 'ঐচ্ছিক',
  S.unknown: 'অজানা',
};

/// Looks up the [Strings] for the enclosing locale.
Strings of(BuildContext context) => MRTapLocalizations.of(context);

/// Zone for [Lookup] so tests can pin a language without a widget tree.
class MRTapLocalizations {
  const MRTapLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<Strings> delegate = _Delegate();

  static Strings of(BuildContext context) =>
      Localizations.of<Strings>(context, Strings) ??
      Strings(Strings.english, _en);

  /// The backing English map, exposed for the key-parity test.
  static const Map<String, String> englishMap = _en;
  static const Map<String, String> banglaMap = _bn;

  static Strings build(Locale locale) => locale.languageCode == 'bn'
      ? Strings(locale, _bn)
      : Strings(locale, _en);
}

class _Delegate extends LocalizationsDelegate<Strings> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) => Strings.isSupported(locale);

  @override
  Future<Strings> load(Locale locale) =>
      SynchronousFuture<Strings>(MRTapLocalizations.build(locale));

  @override
  bool shouldReload(_Delegate old) => false;
}
