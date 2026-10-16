import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Builds the [ThemeData] for a given brightness.
///
/// Material 3 with an 8-12px corner radius, hairline borders and no gradients
/// or glass effects, per the design spec.
ThemeData buildAppTheme(Brightness brightness, [String? languageCode]) {
  final bool dark = brightness == Brightness.dark;
  final bool isBangla = languageCode == 'bn';
  final ColorScheme scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? AppDarkColors.primary : AppColors.primary,
    onPrimary: dark ? AppDarkColors.onPrimary : AppColors.onPrimary,
    primaryContainer:
        dark ? AppDarkColors.primaryContainer : AppColors.primaryContainer,
    onPrimaryContainer:
        dark ? AppDarkColors.onPrimaryContainer : AppColors.onPrimaryContainer,
    secondary: dark ? AppDarkColors.primary : AppColors.primary,
    onSecondary: dark ? AppDarkColors.onPrimary : AppColors.onPrimary,
    tertiary: dark ? AppDarkColors.success : AppColors.success,
    onTertiary: dark ? AppDarkColors.surface : AppColors.surface,
    error: dark ? AppDarkColors.danger : AppColors.danger,
    onError: dark ? AppDarkColors.surface : AppColors.surface,
    surface: dark ? AppDarkColors.surface : AppColors.surface,
    onSurface: dark ? AppDarkColors.textPrimary : AppColors.textPrimary,
    onSurfaceVariant:
        dark ? AppDarkColors.textSecondary : AppColors.textSecondary,
    surfaceContainerHighest:
        dark ? AppDarkColors.surfaceVariant : AppColors.surfaceVariant,
    surfaceContainerLow:
        dark ? AppDarkColors.surface : AppColors.surface,
    outline: dark ? AppDarkColors.borderStrong : AppColors.borderStrong,
    outlineVariant: dark ? AppDarkColors.border : AppColors.border,
    shadow: Colors.black.withValues(alpha: 0.15),
    scrim: Colors.black.withValues(alpha: 0.45),
  );

  final TextTheme base = Typography.material2021(platform: TargetPlatform.android)
      .englishLike
      .apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
        fontFamilyFallback: const <String>['Noto Sans Bengali', 'sans-serif'],
      );

  const BorderRadius radius = BorderRadius.all(Radius.circular(10));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        dark ? AppDarkColors.background : AppColors.background,
    fontFamily: 'sans-serif',
    textTheme: isBangla
        ? base.copyWith(
            headlineSmall: base.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.0,
            ),
            titleLarge: base.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.0,
            ),
            titleMedium: base.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.0,
            ),
            titleSmall: base.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.0,
            ),
            bodyLarge: base.bodyLarge?.copyWith(height: 1.45, letterSpacing: 0.0),
            bodyMedium: base.bodyMedium?.copyWith(height: 1.45, letterSpacing: 0.0),
            bodySmall: base.bodySmall?.copyWith(height: 1.4, letterSpacing: 0.0),
            labelLarge: base.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.0,
            ),
            labelMedium: base.labelMedium?.copyWith(letterSpacing: 0.0),
            labelSmall: base.labelSmall?.copyWith(letterSpacing: 0.0),
          )
        : base.copyWith(
            headlineSmall: base.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            titleLarge: base.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
            bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
            bodySmall: base.bodySmall?.copyWith(height: 1.4),
            labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppDarkColors.background : AppColors.background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.titleLarge?.copyWith(color: scheme.onSurface),
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: base.labelLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: base.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        minimumSize: const Size(0, 48),
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        minimumSize: const Size(0, 48),
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: base.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      hintStyle: base.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: const RoundedRectangleBorder(borderRadius: radius),
      iconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
        (Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        },
      ),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
        (Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        },
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: base.titleMedium?.copyWith(color: scheme.onSurface),
      contentTextStyle: base.bodyMedium?.copyWith(color: scheme.onSurface),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.onSurface,
      contentTextStyle: base.bodyMedium?.copyWith(color: scheme.surface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest,
      ),
    ),
  );
}
