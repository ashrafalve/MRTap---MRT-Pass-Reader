import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/app_info.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/util/format.dart';
import 'package:mrtap/data/repositories/backup_service.dart';
import 'package:mrtap/data/repositories/library_repository.dart';
import 'package:mrtap/core/theme/app_colors.dart';
import 'package:mrtap/data/repositories/settings_repository.dart';
import 'package:mrtap/widgets/common.dart';
import 'package:mrtap/widgets/metro_logo.dart';

/// Settings: language, appearance, backup and the honest small print.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Strings s = context.s;
    setState(() => _busy = true);
    try {
      final BackupFile file = await context.services.backup.exportToFile();
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path)],
          subject: '${AppInfo.appName} backup',
        ),
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(s.t(S.exportDone))));
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(s.t(S.importFailed))));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _import() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Strings s = context.s;
    final String language = context.languageCode;
    final AppServices services = context.services;
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        const XTypeGroup(label: 'JSON', extensions: <String>['json']),
      ],
    );
    if (file == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final ImportOutcome outcome = await services.backup.importFromFile(file.path);
      services.invalidate();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            s.t(S.importSummary, <String, String>{
              'cards': localizeDigits('${outcome.cardsAdded}', language),
              'txns': localizeDigits('${outcome.transactionsAdded}', language),
            }),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(s.t(S.importFailed))));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _clearAll() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Strings s = context.s;
    final AppServices services = context.services;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(s.t(S.clearAllData)),
        content: Text(s.t(S.clearAllDataConfirm)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.t(S.cancel)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.t(S.delete)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await services.library.clearAll();
    await services.settings.clear();
    if (!mounted) {
      return;
    }
    services.invalidate();
    messenger.showSnackBar(SnackBar(content: Text(s.t(S.clearAllData))));
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.s;
    final AppController controller = context.appController;
    final String language = context.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t(S.settingsTitle)),
        actions: const <Widget>[
          Padding(padding: EdgeInsets.only(right: 16), child: UnofficialBadge()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          SectionHeader(title: s.t(S.language)),
          SectionCard(
            child: SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: SettingsRepository.languageSystem,
                  label: Text(s.t(S.languageSystem)),
                ),
                ButtonSegment<String>(
                  value: 'en',
                  label: Text(s.t(S.languageEnglish)),
                ),
                ButtonSegment<String>(
                  value: 'bn',
                  label: Text(s.t(S.languageBangla)),
                ),
              ],
              selected: <String>{controller.languagePreference},
              onSelectionChanged: (Set<String> value) =>
                  controller.setLanguage(value.first),
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: s.t(S.appearance)),
          SectionCard(
            child: SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: SettingsRepository.themeSystem,
                  label: Text(s.t(S.themeSystem)),
                  icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                ),
                ButtonSegment<String>(
                  value: SettingsRepository.themeLight,
                  label: Text(s.t(S.themeLight)),
                  icon: const Icon(Icons.light_mode_outlined, size: 18),
                ),
                ButtonSegment<String>(
                  value: SettingsRepository.themeDark,
                  label: Text(s.t(S.themeDark)),
                  icon: const Icon(Icons.dark_mode_outlined, size: 18),
                ),
              ],
              selected: <String>{controller.themeMode.name},
              onSelectionChanged: (Set<String> value) =>
                  controller.setThemeMode(value.first),
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: s.t(S.backup)),
          SectionCard(
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file_outlined),
                  title: Text(s.t(S.exportBackup)),
                  enabled: !_busy,
                  onTap: _busy ? null : _export,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download_outlined),
                  title: Text(s.t(S.importBackup)),
                  enabled: !_busy,
                  onTap: _busy ? null : _import,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: s.t(S.about)),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    MetroLogo(
                      size: 32,
                      color: AppColors.primary,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? AppDarkColors.surfaceVariant
                          : AppColors.surfaceVariant,
                      showBackground: true,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppInfo.appName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          s.t(S.tagline),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(s.t(S.aboutBody), style: Theme.of(context).textTheme.bodyMedium),
                const Divider(height: 32),
                KeyValue(
                  label: s.t(S.appVersion),
                  value: localizeDigits(AppInfo.version, language),
                ),
                KeyValue(
                  label: s.t(S.fareDataVersion),
                  value: localizeDigits(AppInfo.fareDataVersion, language),
                ),
                KeyValue(
                  label: s.t(S.fareDataVerified),
                  value: localizeDigits(AppInfo.fareDataLastVerified, language),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InfoNote(
            icon: Icons.source_outlined,
            message: s.t(S.dataSourceBody, <String, String>{
              'date': localizeDigits(AppInfo.fareDataLastVerified, language),
            }),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: s.t(S.clearAllData)),
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text(
                s.t(S.clearAllData),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: _busy ? null : _clearAll,
            ),
          ),
          const SizedBox(height: 24),
          const DisclaimerNote(long: true),
        ],
      ),
    );
  }
}
