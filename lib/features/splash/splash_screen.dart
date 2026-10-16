import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mrtap/app/app_scope.dart';
import 'package:mrtap/core/app_info.dart';
import 'package:mrtap/core/l10n/strings.dart';
import 'package:mrtap/core/theme/app_colors.dart';
import 'package:mrtap/features/shell/app_shell.dart';
import 'package:mrtap/widgets/metro_logo.dart';

/// Clean, minimal solid-color splash screen.
///
/// Follows flat design principles: solid colors, no gradients, no drop shadows,
/// no cluttered background shapes. Solid green background with centered solid
/// metro logo on a white container.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    // Clean, quick splash delay
    _timer = Timer(const Duration(milliseconds: 1600), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (BuildContext context, _, _) => const AppShell(),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder:
            (BuildContext context, Animation<double> animation, _, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Strings s = context.s;

    // Solid color palette
    final Color bgColor = dark ? AppDarkColors.background : AppColors.primary;
    final Color logoColor = AppColors.primary;
    final Color logoBgColor = Colors.white;
    final Color textColor = dark ? AppDarkColors.textPrimary : Colors.white;
    final Color subtextColor =
        dark ? AppDarkColors.textSecondary : Colors.white.withAlpha(220);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Spacer(flex: 3),

            // Clean, elegant Metro Icon badge with smooth subtle entrance
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _entrance,
                  curve: Curves.easeOutBack,
                ),
                child: MetroLogo(
                  size: 76,
                  color: logoColor,
                  backgroundColor: logoBgColor,
                  showBackground: true,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Name & Tagline
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _entrance,
                curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    AppInfo.appName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.t(S.tagline),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 4),

            // Bottom version
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'v${AppInfo.version} · ${s.t(S.unofficial)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
