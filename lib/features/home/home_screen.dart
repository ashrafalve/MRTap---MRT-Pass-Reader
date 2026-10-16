import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/data/models/models.dart';
import 'package:mrtap/features/activity/activity_screen.dart';
import 'package:mrtap/features/cards/card_detail_screen.dart';
import 'package:mrtap/features/scan/scan_screen.dart';
import 'package:mrtap/widgets/card_widgets.dart';
import 'package:mrtap/widgets/common.dart';
import 'package:mrtap/widgets/transaction_tile.dart';

import 'package:mrtap/core/theme/app_colors.dart';
import 'package:mrtap/widgets/metro_logo.dart';

/// Home: the balance of the most recently read card, its recent activity, and
/// the entry point to scanning.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ValueNotifier<int>? _revision;
  bool _loading = true;
  List<SavedCard> _cards = const <SavedCard>[];
  Map<String, CardSummary> _summaries = const <String, CardSummary>{};
  List<SavedTransaction> _recent = const <SavedTransaction>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_revision == null) {
      _revision = context.services.revision;
      _revision!.addListener(_load);
      _load();
    }
  }

  @override
  void dispose() {
    _revision?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final AppServices services = context.services;
    final List<SavedCard> cards = await services.library.cards();
    final Map<String, CardSummary> summaries = <String, CardSummary>{};
    for (final SavedCard card in cards) {
      summaries[card.idm] = await services.library.summary(card.idm);
    }
    final List<SavedTransaction> all = await services.library.allTransactions();
    if (!mounted) {
      return;
    }
    setState(() {
      _cards = cards;
      _summaries = summaries;
      _recent = all.take(6).toList(growable: false);
      _loading = false;
    });
  }

  Future<void> _scan() async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const ScanScreen()),
    );
  }

  void _openCard(SavedCard card) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => CardDetailScreen(idm: card.idm)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MetroLogo(
              size: 24,
              color: AppColors.primary,
              backgroundColor: dark ? AppDarkColors.surfaceVariant : Colors.white,
              showBackground: true,
            ),
            const SizedBox(width: 10),
            Text(s.t(S.homeTitle)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: <Widget>[
                  if (_cards.isEmpty)
                    SectionCard(
                      child: EmptyState(
                        customIcon: MetroLogo(
                          size: 48,
                          color: AppColors.primary,
                          backgroundColor: dark
                              ? AppDarkColors.surfaceVariant
                              : AppColors.surfaceVariant,
                          showBackground: true,
                        ),
                        title: s.t(S.noCards),
                        body: s.t(S.noCardsBody),
                        action: FilledButton.icon(
                          onPressed: _scan,
                          icon: const Icon(Icons.nfc, size: 20),
                          label: Text(s.t(S.scanCard)),
                        ),
                      ),
                    )
                  else ...<Widget>[
                    BalanceHero(
                      card: _cards.first,
                      summary: _summaries[_cards.first.idm] ??
                          const CardSummary.empty(),
                      onScan: _scan,
                      onTap: () => _openCard(_cards.first),
                    ),
                    if (_cards.length > 1) ...<Widget>[
                      const SizedBox(height: 24),
                      SectionHeader(title: s.t(S.savedCards)),
                      SectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: <Widget>[
                            for (int i = 0; i < _cards.length; i++) ...<Widget>[
                              if (i > 0) const Divider(height: 1),
                              CardTile(
                                card: _cards[i],
                                summary: _summaries[_cards[i].idm],
                                onTap: () => _openCard(_cards[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: s.t(S.recentActivity),
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const ActivityScreen(),
                          ),
                        ),
                        child: Text(s.t(S.viewAllActivity)),
                      ),
                    ),
                    if (_recent.isEmpty)
                      SectionCard(child: Text(s.t(S.emptyHistory)))
                    else
                      SectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: <Widget>[
                            for (int i = 0; i < _recent.length; i++) ...<Widget>[
                              if (i > 0) const Divider(height: 1),
                              TransactionTile(transaction: _recent[i]),
                            ],
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
