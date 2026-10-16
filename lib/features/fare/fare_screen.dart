import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/util/format.dart';
import 'package:mrtap/data/fares/fare_data.dart';
import 'package:mrtap/data/stations/station.dart';
import 'package:mrtap/widgets/common.dart';
import 'package:mrtap/widgets/station_picker.dart';

/// Offline fare calculator.
///
/// Usable both as the Fare tab ([embedded] true) and as a pushed page. Only
/// operational stations can be chosen, and fares come from the bundled chart —
/// nothing is fetched and nothing is estimated.
class FareScreen extends StatefulWidget {
  const FareScreen({
    super.key,
    this.embedded = false,
    this.initialFrom,
    this.initialTo,
  });

  final bool embedded;
  final Station? initialFrom;
  final Station? initialTo;

  @override
  State<FareScreen> createState() => _FareScreenState();
}

class _FareScreenState extends State<FareScreen> {
  late Station? _from = widget.initialFrom;
  late Station? _to = widget.initialTo;

  FareQuote? get _quote {
    final Station? from = _from;
    final Station? to = _to;
    if (from == null || to == null) {
      return null;
    }
    return context.services.fares.quote(from, to);
  }

  Future<void> _pickFrom() async {
    final Station? picked = await pickStation(context, exclude: _to);
    if (picked != null) {
      setState(() => _from = picked);
    }
  }

  Future<void> _pickTo() async {
    final Station? picked = await pickStation(context, exclude: _from);
    if (picked != null) {
      setState(() => _to = picked);
    }
  }

  void _swap() {
    setState(() {
      final Station? tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    final Widget body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        if (widget.embedded) ...<Widget>[
          Text(s.t(S.fareTitle), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
        ],
        StationField(label: s.t(S.fromStation), station: _from, onTap: _pickFrom),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: (_from == null && _to == null) ? null : _swap,
              icon: const Icon(Icons.swap_vert, size: 20),
              label: Text(s.t(S.swap)),
            ),
          ),
        ),
        StationField(label: s.t(S.toStation), station: _to, onTap: _pickTo),
        const SizedBox(height: 20),
        _ResultSection(quote: _quote, from: _from, to: _to),
        const SizedBox(height: 16),
        const _FareFacts(),
      ],
    );

    if (widget.embedded) {
      return Scaffold(body: SafeArea(child: body));
    }
    return Scaffold(appBar: AppBar(title: Text(s.t(S.fareTitle))), body: body);
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.quote, required this.from, required this.to});

  final FareQuote? quote;
  final Station? from;
  final Station? to;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    final String language = context.languageCode;
    final ThemeData theme = Theme.of(context);

    if (from == null || to == null) {
      return SectionCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            s.t(S.chooseTwoStations),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final FareQuote? q = quote;
    if (q == null) {
      return SectionCard(child: Text(s.t(S.fareUnavailable)));
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            s.t(S.estimatedFare),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            formatTaka(q.fare, language),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${q.from.name(language)}  →  ${q.to.name(language)}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Divider(height: 32),
          KeyValue(
            label: s.t(S.withPass),
            value: formatTaka(q.withPass, language),
          ),
          KeyValue(
            label: s.t(S.seniorDiscount),
            value: formatTaka(q.withSeniorDiscount, language),
          ),
        ],
      ),
    );
  }
}

class _FareFacts extends StatelessWidget {
  const _FareFacts();

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    final String language = context.languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              KeyValue(
                label: s.t(S.minFare),
                value: formatTaka(FareRules.minFare, language),
              ),
              KeyValue(
                label: s.t(S.maxFare),
                value: formatTaka(FareRules.maxFare, language),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoNote(icon: Icons.percent, message: s.t(S.mrtPassDiscount)),
        const SizedBox(height: 8),
        InfoNote(icon: Icons.elderly, message: s.t(S.seniorDiscount)),
        const SizedBox(height: 8),
        InfoNote(icon: Icons.child_care, message: s.t(S.childFree)),
        const SizedBox(height: 8),
        InfoNote(icon: Icons.credit_card, message: s.t(S.mrtPassPrice)),
        const SizedBox(height: 8),
        InfoNote(icon: Icons.receipt_long_outlined, message: s.t(S.fareChartNote)),
      ],
    );
  }
}
