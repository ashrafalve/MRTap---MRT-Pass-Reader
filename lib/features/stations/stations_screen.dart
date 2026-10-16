import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/util/format.dart';
import 'package:mrtap/data/stations/station.dart';
import 'package:mrtap/features/fare/fare_screen.dart';
import 'package:mrtap/widgets/common.dart';

/// The Line 6 station directory.
///
/// Stations are listed in line order with their card code. Kamalapur is shown
/// but clearly marked as not yet open.
class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    final String language = context.languageCode;
    final String query = _query.trim().toLowerCase();

    final List<Station> stations = kStations.where((Station station) {
      if (query.isEmpty) {
        return true;
      }
      return station.nameEn.toLowerCase().contains(query) ||
          station.nameBn.contains(_query.trim()) ||
          (station.code?.toString().contains(query) ?? false);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(s.t(S.stationsTitle))),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: s.t(S.stationSearch),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: stations.isEmpty
                ? Center(
                    child: Text(
                      s.t(S.noResults),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: stations.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: InfoNote(
                            icon: Icons.train_outlined,
                            message: s.t(S.operationalCount),
                          ),
                        );
                      }
                      final Station station = stations[index - 1];
                      return SectionCard(
                        onTap: () => _openStation(station),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                station.code == null
                                    ? '—'
                                    : localizeDigits('${station.code}', language),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    station.name(language),
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  if (!station.operational)
                                    Text(
                                      s.t(S.underConstruction),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openStation(Station station) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        final String language = sheetContext.languageCode;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  station.name(language),
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                KeyValue(
                  label: sheetContext.t(S.stationCode),
                  value: station.code == null
                      ? '—'
                      : localizeDigits('${station.code}', language),
                ),
                KeyValue(
                  label: sheetContext.t(S.stationNumber),
                  value: localizeDigits('${station.order + 1}', language),
                ),
                KeyValue(
                  label: sheetContext.t(S.operational),
                  value: station.operational
                      ? sheetContext.t(S.operational)
                      : sheetContext.t(S.underConstruction),
                ),
                const SizedBox(height: 16),
                if (station.operational)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.confirmation_number_outlined, size: 20),
                      label: Text(sheetContext.t(S.tapForFares)),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => FareScreen(initialFrom: station),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
