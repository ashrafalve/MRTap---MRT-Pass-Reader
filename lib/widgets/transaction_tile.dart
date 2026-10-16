import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';

import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/theme/app_colors.dart';
import 'package:mrtap/core/util/format.dart';
import 'package:mrtap/data/models/models.dart';
import 'package:mrtap/data/stations/station.dart';
import 'package:mrtap/nfc/felica/transaction_record.dart';
import 'package:mrtap/widgets/common.dart';

/// Localised station label for a card code, including Hatirjheel bus stops.
String stationLabel(BuildContext context, int code) {
  final String language = context.languageCode;
  final Station? station = stationByCode(code);
  if (station != null) {
    return station.name(language);
  }
  final String? bus = kBhatirjheelBusCodes[code];
  if (bus != null) {
    return language == 'bn' ? '$bus (হাতিরঝিল)' : '$bus (Hatirjheel)';
  }
  return context.t(S.unknownStation, <String, String>{
    'code': localizeDigits('$code', language),
  });
}

String transactionTypeLabel(BuildContext context, TxnType type) => switch (type) {
      TxnType.metro => context.t(S.typeMetro),
      TxnType.busStart => context.t(S.typeBusStart),
      TxnType.busEnd => context.t(S.typeBusEnd),
      TxnType.topUp => context.t(S.typeTopUp),
      TxnType.unknown => context.t(S.typeUnknown),
    };

IconData transactionIcon(TxnType type) => switch (type) {
      TxnType.metro => Icons.subway_outlined,
      TxnType.busStart || TxnType.busEnd => Icons.directions_bus_outlined,
      TxnType.topUp => Icons.add_card_outlined,
      TxnType.unknown => Icons.help_outline,
    };

/// One row in a transaction list.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.cardLabel,
    this.onTap,
  });

  final SavedTransaction transaction;

  /// Shown in the all-cards activity feed to say which card this came from.
  final String? cardLabel;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String language = context.languageCode;
    final bool topUp = transaction.isTopUp;
    final bool dark = theme.brightness == Brightness.dark;

    final String title = transactionTypeLabel(context, transaction.type);
    final String subtitle = transaction.type.isJourney
        ? '${stationLabel(context, transaction.fromCode)}  →  ${stationLabel(context, transaction.toCode)}'
        : formatCardTime(transaction.occurredAt, language);

    final TextStyle amountStyle = theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w700,
      color: topUp
          ? (dark ? AppDarkColors.success : AppColors.success)
          : theme.colorScheme.onSurface,
    );

    final String? amountText = topUp
        ? (transaction.topUpPaisa == null
            ? null
            : '+${formatTaka(transaction.topUpPaisa!, language)}')
        : (transaction.farePaisa == null
            ? null
            : '−${formatTaka(transaction.farePaisa!, language)}');

    final String balanceText = transaction.balancePlausible
        ? formatTaka(transaction.balance, language)
        : '—';

    return InkWell(
      onTap: onTap ?? () => showTransactionDetails(context, transaction),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                transactionIcon(transaction.type),
                size: 19,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (transaction.type.isJourney)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        formatCardTime(transaction.occurredAt, language),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  if (cardLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        cardLabel!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(amountText ?? '—', style: amountStyle),
                const SizedBox(height: 2),
                Text(
                  '${context.t(S.resultingBalance)} $balanceText',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows everything known about a record, including the raw bytes.
///
/// The raw block is shown on purpose: it is the only fully trustworthy view of
/// what the card said, and it makes the app auditable.
void showTransactionDetails(BuildContext context, SavedTransaction txn) {
  final String language = context.languageCode;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final String balance =
          txn.balancePlausible ? formatTaka(txn.balance, language) : '—';
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(transactionIcon(txn.type)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      transactionTypeLabel(context, txn.type),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (txn.type.isJourney) ...<Widget>[
                KeyValueRow(
                  label: context.t(S.from),
                  value: stationLabel(context, txn.fromCode),
                ),
                KeyValueRow(
                  label: context.t(S.to),
                  value: stationLabel(context, txn.toCode),
                ),
              ],
              KeyValueRow(
                label: context.t(S.lastRead),
                value: formatCardTime(txn.occurredAt, language),
              ),
              KeyValueRow(label: context.t(S.resultingBalance), value: balance),
              KeyValueRow(
                label: 'Header',
                value: txn.fixedHeader,
              ),
              KeyValueRow(label: 'Block', value: '${txn.blockIndex}'),
              KeyValueRow(label: 'Raw', value: txn.rawBlock),
              const SizedBox(height: 12),
              InfoNote(message: context.t(S.hourPrecision)),
            ],
          ),
        ),
      );
    },
  );
}

/// Minimal label/value row used inside sheets.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card kind label used by the card widgets.
String cardKindLabel(BuildContext context, CardKind kind) => switch (kind) {
      CardKind.mrtPass => context.t(S.mrtPass),
      CardKind.rapidPass => context.t(S.rapidPass),
    };

/// A compact chip for a card kind.
class CardKindChip extends StatelessWidget {
  const CardKindChip({super.key, required this.kind});

  final CardKind kind;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        cardKindLabel(context, kind),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
