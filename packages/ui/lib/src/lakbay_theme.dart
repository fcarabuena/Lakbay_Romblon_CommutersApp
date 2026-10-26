import 'package:flutter/material.dart';

/// The Tide palette: calm white surfaces, marine blue for information and
/// sea travel, island green only for the main action and success.
///
/// Contrast (checked): primary on white 7.4:1, green on white 5.3:1, slate on
/// white 6.1:1, slate on mist 5.6:1. Never use grey text lighter than [slate].
abstract final class TideColors {
  static const marine = Color(0xFF0B5C7A);
  static const shallows = Color(0xFFE1EFF3);
  static const onShallows = Color(0xFF0B3F54);
  static const island = Color(0xFF1F7A4D);
  static const islandTint = Color(0xFFE3F1E8);
  static const onIslandTint = Color(0xFF14532F);
  static const white = Color(0xFFFFFFFF);
  static const mist = Color(0xFFF2F7F8);
  static const ink = Color(0xFF10232B);
  static const slate = Color(0xFF4F6670);
  static const sidebarText = Color(0xFF2C434C);
  static const outline = Color(0xFF7C9098);
  static const hairline = Color(0xFFD5E1E4);
  static const error = Color(0xFFB42318);
}

/// Spacing scale and corner radii.
abstract final class TideSpace {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  static const radius = 12.0;
  static const pill = 999.0;
  static const controlHeight = 48.0;
}

/// Colours for one advisory level: tinted background, text and icon, border.
@immutable
class AdvisoryTone {
  const AdvisoryTone({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;

  AdvisoryTone lerp(AdvisoryTone other, double t) => AdvisoryTone(
    background: Color.lerp(background, other.background, t)!,
    foreground: Color.lerp(foreground, other.foreground, t)!,
    border: Color.lerp(border, other.border, t)!,
  );
}

/// Advisory colours: red = suspended, amber = caution, blue = notice.
///
/// Colour is never the only signal: banners also show an icon and a bold
/// word ("Suspended: …").
@immutable
class AdvisoryColors extends ThemeExtension<AdvisoryColors> {
  const AdvisoryColors({
    required this.suspended,
    required this.caution,
    required this.notice,
  });

  static const tide = AdvisoryColors(
    suspended: AdvisoryTone(
      background: Color(0xFFFEF3F2),
      foreground: Color(0xFF9A1C12),
      border: Color(0xFFF4B4AD),
    ),
    caution: AdvisoryTone(
      background: Color(0xFFFFF6DB),
      foreground: Color(0xFF6B4600),
      border: Color(0xFFF0C552),
    ),
    notice: AdvisoryTone(
      background: TideColors.shallows,
      foreground: TideColors.onShallows,
      border: Color(0xFFB9D7E2),
    ),
  );

  final AdvisoryTone suspended;
  final AdvisoryTone caution;
  final AdvisoryTone notice;

  static AdvisoryColors of(BuildContext context) =>
      Theme.of(context).extension<AdvisoryColors>() ?? tide;

  @override
  AdvisoryColors copyWith({
    AdvisoryTone? suspended,
    AdvisoryTone? caution,
    AdvisoryTone? notice,
  }) => AdvisoryColors(
    suspended: suspended ?? this.suspended,
    caution: caution ?? this.caution,
    notice: notice ?? this.notice,
  );

  @override
  AdvisoryColors lerp(ThemeExtension<AdvisoryColors>? other, double t) {
    if (other is! AdvisoryColors) return this;
    return AdvisoryColors(
      suspended: suspended.lerp(other.suspended, t),
      caution: caution.lerp(other.caution, t),
      notice: notice.lerp(other.notice, t),
    );
  }
}

/// Status tints used by notices and badges, from the Tide palette.
extension StatusColors on ColorScheme {
  Color get warningContainer => AdvisoryColors.tide.caution.background;
  Color get onWarningContainer => AdvisoryColors.tide.caution.foreground;
  Color get successContainer => secondaryContainer;
  Color get onSuccessContainer => onSecondaryContainer;
}

/// Digits of equal width, so prices and times line up in columns.
const tabularFigures = [FontFeature.tabularFigures()];

abstract final class LakbayTheme {
  static const fontFamily = 'Figtree';
  static const fontPackage = 'lakbay_ui';

  /// Built by hand (not from a seed) so the Tide colours stay exact.
  static const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: TideColors.marine,
    onPrimary: TideColors.white,
    primaryContainer: TideColors.shallows,
    onPrimaryContainer: TideColors.onShallows,
    secondary: TideColors.island,
    onSecondary: TideColors.white,
    secondaryContainer: TideColors.islandTint,
    onSecondaryContainer: TideColors.onIslandTint,
    tertiary: TideColors.marine,
    onTertiary: TideColors.white,
    tertiaryContainer: TideColors.shallows,
    onTertiaryContainer: TideColors.onShallows,
    error: TideColors.error,
    onError: TideColors.white,
    errorContainer: Color(0xFFFEF3F2),
    onErrorContainer: Color(0xFF9A1C12),
    surface: TideColors.white,
    onSurface: TideColors.ink,
    onSurfaceVariant: TideColors.slate,
    surfaceContainerLowest: TideColors.white,
    surfaceContainerLow: TideColors.white,
    surfaceContainer: TideColors.mist,
    surfaceContainerHigh: TideColors.mist,
    surfaceContainerHighest: TideColors.hairline,
    outline: TideColors.outline,
    outlineVariant: TideColors.hairline,
    inverseSurface: TideColors.ink,
    onInverseSurface: TideColors.white,
    inversePrimary: TideColors.shallows,
    shadow: Color(0x33000000),
    scrim: Color(0x66000000),
    surfaceTint: Colors.transparent,
  );

  static TextTheme _text(TextTheme base) {
    TextStyle? style(
      TextStyle? s,
      double size,
      FontWeight weight, {
      double? height,
    }) => s?.copyWith(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: TideColors.ink,
    );
    return base.copyWith(
      headlineSmall: style(base.headlineSmall, 22, FontWeight.w700),
      titleLarge: style(base.titleLarge, 20, FontWeight.w700),
      titleMedium: style(base.titleMedium, 16, FontWeight.w700),
      titleSmall: style(base.titleSmall, 15, FontWeight.w600),
      bodyLarge: style(base.bodyLarge, 16, FontWeight.w400, height: 1.45),
      bodyMedium: style(base.bodyMedium, 15, FontWeight.w400, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: TideColors.slate,
      ),
      labelLarge: style(base.labelLarge, 15, FontWeight.w700),
      labelMedium: style(base.labelMedium, 13, FontWeight.w600),
      labelSmall: style(base.labelSmall, 11, FontWeight.w600),
    );
  }

  static ThemeData light() {
    const scheme = colorScheme;
    const radius = BorderRadius.all(Radius.circular(TideSpace.radius));
    const shape = RoundedRectangleBorder(borderRadius: radius);
    const pillShape = StadiumBorder();
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      package: fontPackage,
    );
    final text = _text(base.textTheme);
    const control = Size(64, TideSpace.controlHeight);

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );

    return base.copyWith(
      scaffoldBackgroundColor: TideColors.mist,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: const [AdvisoryColors.tide],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: TideColors.hairline)),
        titleTextStyle: text.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: const CardThemeData(
        color: TideColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: TideColors.hairline),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TideColors.hairline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          minimumSize: control,
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: control,
          shape: shape,
          side: BorderSide(color: scheme.primary, width: 1.5),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, TideSpace.controlHeight),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: control,
          shape: shape,
          elevation: 0,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: border(scheme.outline, 1.5),
        enabledBorder: border(scheme.outline, 1.5),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error, 1.5),
        focusedErrorBorder: border(scheme.error, 2),
        disabledBorder: border(TideColors.hairline, 1.5),
        constraints: const BoxConstraints(minHeight: TideSpace.controlHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
        floatingLabelStyle: text.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        helperStyle: text.bodySmall,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: TideColors.shallows,
        indicatorShape: pillShape,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TideColors.shallows,
        selectedColor: TideColors.shallows,
        labelStyle: text.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: pillShape,
        checkmarkColor: scheme.primary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        selectedColor: scheme.primary,
        selectedTileColor: TideColors.shallows,
        minVerticalPadding: TideSpace.s,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: shape,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TideColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: TideColors.white),
        actionTextColor: TideColors.shallows,
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.onSecondary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.secondary
              : TideColors.hairline,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: TideColors.shallows,
          selectedForegroundColor: scheme.primary,
          minimumSize: control,
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()},
      ),
    );
  }
}
