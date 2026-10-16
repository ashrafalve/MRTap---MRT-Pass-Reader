import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/data/stations/station.dart';

/// Opens a searchable station picker and returns the chosen station.
///
/// Only operational stations can be picked, so the fare calculator can never
/// quote a station that is not open. [disabled] names a station to grey out
/// (used to stop "from" and "to" being the same station).
Future<Station?> pickStation(
  BuildContext context, {
  Station? exclude,
  String? title,
}) {
  return showModalBottomSheet<Station>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _StationPickerSheet(
      exclude: exclude,
      title: title ?? context.t(S.selectStation),
    ),
  );
}

class _StationPickerSheet extends StatefulWidget {
  const _StationPickerSheet({required this.exclude, required this.title});

  final Station? exclude;
  final String title;

  @override
  State<_StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends State<_StationPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String language = context.languageCode;
    final String query = _query.trim().toLowerCase();

    final List<Station> stations = kStations.where((Station s) {
      if (query.isEmpty) {
        return true;
      }
      return s.nameEn.toLowerCase().contains(query) ||
          s.nameBn.contains(_query.trim()) ||
          (s.code?.toString().contains(query) ?? false);
    }).toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              autofocus: false,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: context.t(S.stationSearch),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: stations.isEmpty
                  ? Center(
                      child: Text(
                        context.t(S.noResults),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: stations.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final Station station = stations[index];
                        final bool disabled = !station.operational ||
                            station.id == widget.exclude?.id;
                        return ListTile(
                          enabled: !disabled,
                          leading: _CodeBadge(code: station.code),
                          title: Text(station.name(language)),
                          subtitle: !station.operational
                              ? Text(context.t(S.underConstruction))
                              : null,
                          trailing: disabled
                              ? null
                              : const Icon(Icons.chevron_right, size: 20),
                          onTap: disabled
                              ? null
                              : () => Navigator.of(context).pop(station),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final int? code;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code?.toString() ?? '—',
        style: theme.textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w700, fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
      ),
    );
  }
}

/// A tappable field that shows the current station or a prompt.
class StationField extends StatelessWidget {
  const StationField({
    super.key,
    required this.label,
    required this.station,
    required this.onTap,
  });

  final String label;
  final Station? station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    station?.name(context.languageCode) ?? context.t(S.selectStation),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: station == null
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      fontWeight: station == null ? null : FontWeight.w600,
                    ),
                  ),
                ),
                if (station?.code != null)
                  Text(
                    '${station!.code}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.expand_more, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
