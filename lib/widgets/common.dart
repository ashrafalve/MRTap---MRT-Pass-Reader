import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/theme/app_colors.dart';

/// A bordered white panel. The only container used for grouped content.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
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
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A small heading used above grouped content.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A quiet explanatory note with an icon.
class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = InfoTone.neutral,
  });

  final String message;
  final IconData icon;
  final InfoTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final (Color fg, Color bg) = switch (tone) {
      InfoTone.neutral => (
        theme.colorScheme.onSurfaceVariant,
        theme.colorScheme.surfaceContainerHighest,
      ),
      InfoTone.warning => (
        dark ? AppDarkColors.warning : AppColors.warning,
        dark ? AppDarkColors.warningContainer : AppColors.warningContainer,
      ),
      InfoTone.danger => (
        dark ? AppDarkColors.danger : AppColors.danger,
        dark ? AppDarkColors.dangerContainer : AppColors.dangerContainer,
      ),
      InfoTone.success => (
        dark ? AppDarkColors.success : AppColors.success,
        dark ? AppDarkColors.successContainer : AppColors.successContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: fg, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

enum InfoTone { neutral, success, warning, danger }

/// A centred placeholder with an icon, title and optional body.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.customIcon,
    required this.title,
    this.body,
    this.action,
  }) : assert(icon != null || customIcon != null);

  final IconData? icon;
  final Widget? customIcon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (customIcon != null)
            customIcon!
          else
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (body != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}

/// A compact label/value pair.
class KeyValue extends StatelessWidget {
  const KeyValue({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "unofficial app" badge.
class UnofficialBadge extends StatelessWidget {
  const UnofficialBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        context.t(S.unofficial),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The persistent unofficial-app disclaimer used on Home and Settings.
class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({super.key, this.long = false});

  final bool long;

  @override
  Widget build(BuildContext context) => InfoNote(
        icon: Icons.gavel_outlined,
        message: context.t(long ? S.disclaimerLong : S.disclaimerShort),
      );
}
