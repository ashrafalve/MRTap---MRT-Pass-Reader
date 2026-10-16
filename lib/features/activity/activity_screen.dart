import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/data/models/models.dart';
import 'package:mrtap/widgets/common.dart';
import 'package:mrtap/widgets/transaction_tile.dart';

/// All saved transactions across every card, with an optional per-card filter.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  ValueNotifier<int>? _revision;
  bool _loading = true;
  List<SavedCard> _cards = const <SavedCard>[];
  List<SavedTransaction> _transactions = const <SavedTransaction>[];
  String? _filter;

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
    final List<SavedTransaction> transactions = await services.library.allTransactions();
    if (!mounted) {
      return;
    }
    setState(() {
      _cards = cards;
      _transactions = transactions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    final List<SavedTransaction> visible = _filter == null
        ? _transactions
        : _transactions
            .where((SavedTransaction t) => t.cardIdm == _filter)
            .toList(growable: false);

    final Map<String, SavedCard> byId = <String, SavedCard>{
      for (final SavedCard card in _cards) card.idm: card,
    };

    return Scaffold(
      appBar: AppBar(title: Text(s.t(S.activityTitle))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_cards.length > 1)
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                          child: FilterChip(
                            label: Text(s.t(S.allCards)),
                            selected: _filter == null,
                            onSelected: (_) => setState(() => _filter = null),
                          ),
                        ),
                        for (final SavedCard card in _cards)
                          Padding(
                            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                            child: FilterChip(
                              label: Text(
                                card.nickname ?? cardKindLabel(context, card.kind),
                              ),
                              selected: _filter == card.idm,
                              onSelected: (_) => setState(() => _filter = card.idm),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: s.t(S.emptyHistory),
                          body: s.t(S.emptyHistoryBody),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final SavedTransaction txn = visible[index];
                            final SavedCard? card = byId[txn.cardIdm];
                            return SectionCard(
                              padding: EdgeInsets.zero,
                              child: TransactionTile(
                                transaction: txn,
                                cardLabel: card == null
                                    ? null
                                    : (card.nickname ??
                                        cardKindLabel(context, card.kind)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
