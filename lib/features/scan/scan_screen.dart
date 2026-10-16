import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/theme/app_colors.dart';
import 'package:mrtap/core/util/format.dart';
import 'package:mrtap/data/models/models.dart';
import 'package:mrtap/data/repositories/library_repository.dart';
import 'package:mrtap/nfc/felica/felica_reader.dart';
import 'package:mrtap/nfc/nfc_service.dart';
import 'package:mrtap/widgets/animated_shapes.dart';
import 'package:mrtap/widgets/common.dart';
import 'package:mrtap/widgets/transaction_tile.dart';

/// The focused read experience.
///
/// Starts a scan as soon as it opens, shows a clear "hold still" state, saves
/// whatever was read and then reports it. Pops with the card's IDm so the
/// caller can refresh.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _Phase { preparing, unavailable, scanning, done, failed }

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  _Phase _phase = _Phase.preparing;
  NfcError? _error;
  SaveOutcome? _outcome;
  CardSummary _summary = const CardSummary.empty();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final AppServices services = context.services;
    final NfcService nfc = services.nfc;

    final NfcAvailability state = await nfc.availability();
    if (!mounted) {
      return;
    }
    if (state != NfcAvailability.enabled) {
      setState(() {
        _phase = _Phase.unavailable;
        _error = state == NfcAvailability.unsupported
            ? NfcError.unsupported
            : NfcError.disabled;
      });
      return;
    }

    setState(() {
      _phase = _Phase.scanning;
      _error = null;
    });

    try {
      final CardReadResult result = await nfc.scan();
      if (!mounted) {
        return;
      }
      final SaveOutcome outcome = await services.library.saveRead(result);
      final CardSummary summary = await services.library.summary(outcome.card.idm);
      services.invalidate();
      if (!mounted) {
        return;
      }
      setState(() {
        _outcome = outcome;
        _summary = summary;
        _phase = _Phase.done;
      });
    } on NfcException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.code == NfcError.cancelled) {
        return;
      }
      setState(() {
        _phase = _Phase.failed;
        _error = error.code;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _phase = _Phase.failed;
        _error = NfcError.io;
      });
    }
  }

  Future<void> _retry() async {
    await context.services.nfc.cancel();
    if (!mounted) {
      return;
    }
    setState(() => _phase = _Phase.preparing);
    await _start();
  }

  Future<void> _close() async {
    await context.services.nfc.cancel();
    if (mounted) {
      Navigator.of(context).pop(_outcome?.card.idm);
    }
  }

  String _messageFor(NfcError error) => switch (error) {
        NfcError.unsupported => context.t(S.nfcUnsupported),
        NfcError.disabled => context.t(S.nfcDisabled),
        NfcError.notFelica => context.t(S.notFelica),
        NfcError.incompleteRead => context.t(S.cardMoved),
        NfcError.timeout => context.t(S.cardMoved),
        NfcError.busy => context.t(S.readFailed),
        NfcError.io => context.t(S.readFailed),
        NfcError.cancelled => context.t(S.readFailed),
      };

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t(S.scanCard)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: s.t(S.close),
          onPressed: _close,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (_phase) {
              _Phase.preparing => const Center(child: CircularProgressIndicator()),
              _Phase.scanning => _ScanningView(pulse: _pulse),
              _Phase.unavailable => _MessageView(
                  icon: Icons.nfc,
                  title: s.t(S.readFailed),
                  message: _error == null ? '' : _messageFor(_error!),
                  primaryLabel: s.t(S.close),
                  onPrimary: _close,
                  tone: InfoTone.warning,
                ),
              _Phase.failed => _MessageView(
                  icon: Icons.error_outline,
                  title: s.t(S.readFailed),
                  message: _error == null ? '' : _messageFor(_error!),
                  primaryLabel: s.t(S.scanCard),
                  onPrimary: _retry,
                  secondaryLabel: s.t(S.close),
                  onSecondary: _close,
                  tone: InfoTone.danger,
                ),
              _Phase.done => _SuccessView(
                  outcome: _outcome!,
                  summary: _summary,
                  onDone: _close,
                  onScanAgain: _retry,
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _ScanningView extends StatelessWidget {
  const _ScanningView({required this.pulse});

  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Strings s = context.s;
    return Column(
      key: const ValueKey<String>('scanning'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedBuilder(
          animation: pulse,
          builder: (BuildContext context, Widget? child) {
            return SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  AnimatedSolidRadarRings(
                    progress: pulse.value,
                    color: theme.colorScheme.primary,
                    size: 220,
                    strokeWidth: 2.2,
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.nfc,
                      size: 54,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(s.t(S.scanning), style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          s.t(S.holdStill),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.outcome,
    required this.summary,
    required this.onDone,
    required this.onScanAgain,
  });

  final SaveOutcome outcome;
  final CardSummary summary;
  final VoidCallback onDone;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Strings s = context.s;
    final String language = context.languageCode;
    final SavedCard card = outcome.card;
    final String balance = summary.balancePaisa == null
        ? '—'
        : formatTaka(summary.balancePaisa!, language);

    return ListView(
      key: const ValueKey<String>('done'),
      children: <Widget>[
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.brightness == Brightness.dark
                  ? AppDarkColors.successContainer
                  : AppColors.successContainer,
            ),
            child: Icon(
              Icons.check,
              size: 36,
              color: theme.brightness == Brightness.dark
                  ? AppDarkColors.success
                  : AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: Text(s.t(S.readSuccess), style: theme.textTheme.titleLarge)),
        const SizedBox(height: 24),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                CardKindChip(kind: card.kind),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(card.shortId, style: theme.textTheme.bodySmall),
                ),
              ]),
              const SizedBox(height: 16),
              Text(
                s.t(S.balance),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                balance,
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Divider(height: 32),
              KeyValueRow(
                label: s.t(S.recordsOnCard),
                value: localizeDigits('${outcome.found}', language),
              ),
              KeyValueRow(
                label: s.t(S.newRecords),
                value: localizeDigits('${outcome.inserted}', language),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (outcome.found == 0 && outcome.inserted == 0)
          InfoNote(message: s.t(S.noTransactions)),
        const SizedBox(height: 24),
        FilledButton(onPressed: onDone, child: Text(s.t(S.close))),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onScanAgain, child: Text(s.t(S.scanCard))),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.tone = InfoTone.neutral,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final InfoTone tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>('msg-$title-$message'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        EmptyState(icon: icon, title: title, body: message.isEmpty ? null : message),
        const SizedBox(height: 8),
        FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        if (secondaryLabel != null) ...<Widget>[
          const SizedBox(height: 8),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
      ],
    );
  }
}
