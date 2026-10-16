import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/util/format.dart';
import 'package:mrtap/data/models/models.dart';
import 'package:mrtap/widgets/metro_logo.dart';
import 'package:mrtap/widgets/transaction_tile.dart';

/// The large balance readout for a card, used on Home and the card detail page.
class BalanceHero extends StatelessWidget {
  const BalanceHero({
    super.key,
    required this.card,
    required this.summary,
    required this.onScan,
    this.onTap,
  });

  final SavedCard card;
  final CardSummary summary;
  final VoidCallback onScan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String language = context.languageCode;
    final String name = card.nickname ?? cardKindLabel(context, card.kind);
    final String? balance = summary.balancePaisa == null
        ? null
        : formatTaka(summary.balancePaisa!, language);

    return SectionCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CardKindChip(kind: card.kind),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            card.shortId,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            context.t(S.balance),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            balance ?? '—',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${context.t(S.lastRead)} · ${formatCardTime(card.lastScan, language)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _Stat(
                label: context.t(S.journeyCount),
                value: localizeDigits('${summary.journeyCount}', language),
              ),
              _Stat(
                label: context.t(S.topUpCount),
                value: localizeDigits('${summary.topUpCount}', language),
              ),
              _Stat(
                label: context.t(S.totalSpent),
                value: formatTaka(summary.totalSpentPaisa, language),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.nfc, size: 20),
              label: Text(context.t(S.scanCard)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A row in the saved-cards list.
class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.summary,
    required this.onTap,
  });

  final SavedCard card;
  final CardSummary? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String language = context.languageCode;
    final String name = card.nickname ?? cardKindLabel(context, card.kind);
    final String? balance = summary?.balancePaisa == null
        ? null
        : formatTaka(summary!.balancePaisa!, language);

    return ListTile(
      onTap: onTap,
      leading: MetroLogo(
        size: 20,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.primaryContainer,
        showBackground: true,
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(card.shortId),
      trailing: Text(
        balance ?? '',
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// The bordered panel primitive shared by the card widgets.
class SectionCardShell extends StatelessWidget {
  const SectionCardShell({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    );
  }
}
