import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/util/format.dart';
import 'package:mrtap/data/models/models.dart';
import 'package:mrtap/features/scan/scan_screen.dart';
import 'package:mrtap/widgets/card_widgets.dart';
import 'package:mrtap/widgets/common.dart';
import 'package:mrtap/widgets/transaction_tile.dart';

/// Full history for one card.
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.idm});

  final String idm;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  ValueNotifier<int>? _revision;
  bool _loading = true;
  SavedCard? _card;
  CardSummary _summary = const CardSummary.empty();
  List<SavedTransaction> _transactions = const <SavedTransaction>[];

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
    final SavedCard? card = await services.library.card(widget.idm);
    if (card == null) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
      return;
    }
    final CardSummary summary = await services.library.summary(widget.idm);
    final List<SavedTransaction> transactions =
        await services.library.transactionsForCard(widget.idm);
    if (!mounted) {
      return;
    }
    setState(() {
      _card = card;
      _summary = summary;
      _transactions = transactions;
      _loading = false;
    });
  }

  Future<void> _scan() async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const ScanScreen()),
    );
  }

  Future<void> _rename() async {
    final SavedCard? card = _card;
    if (card == null) {
      return;
    }
    final AppServices services = context.services;
    final TextEditingController controller =
        TextEditingController(text: card.nickname ?? '');
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.t(S.rename)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: context.t(S.cardName)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.t(S.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(context.t(S.save)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) {
      return;
    }
    await services.library.renameCard(card.idm, result);
    services.invalidate();
  }

  Future<void> _delete() async {
    final AppServices services = context.services;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.t(S.deleteCard)),
        content: Text(context.t(S.deleteCardConfirm)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.t(S.cancel)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.t(S.delete)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await services.library.deleteCard(widget.idm);
    services.invalidate();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    final SavedCard? card = _card;
    return Scaffold(
      appBar: AppBar(
        title: Text(card?.nickname ?? s.t(S.unknownCard)),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'rename') {
                _rename();
              } else if (value == 'delete') {
                _delete();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'rename', child: Text(s.t(S.rename))),
              PopupMenuItem<String>(value: 'delete', child: Text(s.t(S.deleteCard))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : card == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: <Widget>[
                    BalanceHero(
                      card: card,
                      summary: _summary,
                      onScan: _scan,
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(title: s.t(S.recentActivity)),
                    if (_transactions.isEmpty)
                      SectionCard(child: Text(s.t(S.emptyHistory)))
                    else
                      SectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: _groupedTiles(context, _transactions),
                        ),
                      ),
                    const SizedBox(height: 12),
                    InfoNote(message: s.t(S.hourPrecision)),
                  ],
                ),
    );
  }

  List<Widget> _groupedTiles(
    BuildContext context,
    List<SavedTransaction> transactions,
  ) {
    final List<Widget> widgets = <Widget>[];
    String? lastDay;
    for (int i = 0; i < transactions.length; i++) {
      final SavedTransaction txn = transactions[i];
      final String day = dateKey(txn.occurredAt);
      if (day != lastDay) {
        lastDay = day;
        if (i > 0) {
          widgets.add(const Divider(height: 1));
        }
        widgets.add(
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              formatDateOnly(txn.occurredAt, context.languageCode),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        );
      } else {
        widgets.add(const Divider(height: 1));
      }
      widgets.add(TransactionTile(transaction: txn));
    }
    return widgets;
  }
}
