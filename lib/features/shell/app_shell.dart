import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/data/repositories/library_repository.dart';
import 'package:mrtap/features/cards/card_detail_screen.dart';
import 'package:mrtap/features/fare/fare_screen.dart';
import 'package:mrtap/features/home/home_screen.dart';
import 'package:mrtap/features/settings/settings_screen.dart';
import 'package:mrtap/features/stations/stations_screen.dart';
import 'package:mrtap/nfc/felica/felica_reader.dart';

/// The bottom-navigation shell: Home, Fare, Stations, Settings.
///
/// Also runs background NFC listening so if the user touches a card to the
/// back of the phone anywhere in the app, it automatically scans and pops up
/// the card details immediately without having to tap "Scan card".
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoListening());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.services.nfc.stopBackgroundListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoListening();
    } else if (state == AppLifecycleState.paused) {
      context.services.nfc.stopBackgroundListening();
      _listening = false;
    }
  }

  void _startAutoListening() {
    if (!mounted || _listening) {
      return;
    }
    _listening = true;
    final AppServices services = context.services;
    services.nfc.startBackgroundListening(
      onCard: (CardReadResult result) async {
        if (!mounted) {
          return;
        }
        // Save read to local SQLite database
        final SaveOutcome outcome = await services.library.saveRead(result);
        services.invalidate();

        if (!mounted) {
          return;
        }
        // Instantly navigate to card details to show balance & all transactions
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CardDetailScreen(idm: outcome.card.idm),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          HomeScreen(),
          FareScreen(embedded: true),
          StationsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.t(S.navHome),
          ),
          NavigationDestination(
            icon: const Icon(Icons.confirmation_number_outlined),
            selectedIcon: const Icon(Icons.confirmation_number),
            label: s.t(S.navFare),
          ),
          NavigationDestination(
            icon: const Icon(Icons.train_outlined),
            selectedIcon: const Icon(Icons.train),
            label: s.t(S.navStations),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: s.t(S.navSettings),
          ),
        ],
      ),
    );
  }
}
