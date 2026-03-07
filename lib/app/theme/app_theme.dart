import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_customization.dart';

@immutable
class BcnThemePalette extends ThemeExtension<BcnThemePalette> {
  const BcnThemePalette({
    required this.primary,
    required this.background,
    required this.navigation,
    required this.onNavigation,
    required this.button,
    required this.onButton,
    required this.authPageBackground,
    required this.authCardBackground,
    required this.authCardBorder,
    required this.authInputBorder,
    required this.authMutedAction,
    required this.authHeadingColor,
    required this.authTextMuted,
  });

  factory BcnThemePalette.light(ThemeCustomization? customization) {
    final Color primary = colorFromHex(
      customization?.primaryHex ?? AppTheme.defaultPrimaryHex,
    );
    final Color background = colorFromHex(
      customization?.backgroundHex ?? AppTheme.defaultBackgroundHex,
    );
    final Color navigation = colorFromHex(
      customization?.navigationHex ?? AppTheme.defaultNavigationHex,
    );
    final Color button = colorFromHex(
      customization?.buttonHex ?? AppTheme.defaultButtonHex,
    );
    final Color authCardBackground = _mix(background, Colors.white, 0.72);
    final Color authHeadingColor = _mix(primary, Colors.black, 0.18);
    final Color authTextMuted = _mix(authHeadingColor, background, 0.45);

    return BcnThemePalette(
      primary: primary,
      background: background,
      navigation: navigation,
      onNavigation: _foregroundFor(navigation),
      button: button,
      onButton: _foregroundFor(button),
      authPageBackground: background,
      authCardBackground: authCardBackground,
      authCardBorder: _mix(primary, authCardBackground, 0.82),
      authInputBorder: _mix(primary, authCardBackground, 0.67),
      authMutedAction: _mix(button, authCardBackground, 0.88),
      authHeadingColor: authHeadingColor,
      authTextMuted: authTextMuted,
    );
  }

  factory BcnThemePalette.dark(ThemeCustomization? customization) {
    final Color primary = _mix(
      colorFromHex(customization?.primaryHex ?? AppTheme.defaultPrimaryHex),
      Colors.white,
      0.2,
    );
    final Color background = _mix(
      colorFromHex(
        customization?.backgroundHex ?? AppTheme.defaultBackgroundHex,
      ),
      Colors.black,
      0.78,
    );
    final Color navigation = _mix(
      colorFromHex(
        customization?.navigationHex ?? AppTheme.defaultNavigationHex,
      ),
      Colors.black,
      0.38,
    );
    final Color button = _mix(
      colorFromHex(customization?.buttonHex ?? AppTheme.defaultButtonHex),
      Colors.black,
      0.1,
    );
    final Color authCardBackground = _mix(background, Colors.white, 0.08);
    final Color authHeadingColor = _mix(primary, Colors.white, 0.15);
    final Color authTextMuted = _mix(authHeadingColor, background, 0.42);

    return BcnThemePalette(
      primary: primary,
      background: background,
      navigation: navigation,
      onNavigation: _foregroundFor(navigation),
      button: button,
      onButton: _foregroundFor(button),
      authPageBackground: background,
      authCardBackground: authCardBackground,
      authCardBorder: _mix(primary, authCardBackground, 0.74),
      authInputBorder: _mix(primary, authCardBackground, 0.58),
      authMutedAction: _mix(button, authCardBackground, 0.72),
      authHeadingColor: authHeadingColor,
      authTextMuted: authTextMuted,
    );
  }

  final Color primary;
  final Color background;
  final Color navigation;
  final Color onNavigation;
  final Color button;
  final Color onButton;
  final Color authPageBackground;
  final Color authCardBackground;
  final Color authCardBorder;
  final Color authInputBorder;
  final Color authMutedAction;
  final Color authHeadingColor;
  final Color authTextMuted;

  @override
  ThemeExtension<BcnThemePalette> copyWith({
    Color? primary,
    Color? background,
    Color? navigation,
    Color? onNavigation,
    Color? button,
    Color? onButton,
    Color? authPageBackground,
    Color? authCardBackground,
    Color? authCardBorder,
    Color? authInputBorder,
    Color? authMutedAction,
    Color? authHeadingColor,
    Color? authTextMuted,
  }) {
    return BcnThemePalette(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      navigation: navigation ?? this.navigation,
      onNavigation: onNavigation ?? this.onNavigation,
      button: button ?? this.button,
      onButton: onButton ?? this.onButton,
      authPageBackground: authPageBackground ?? this.authPageBackground,
      authCardBackground: authCardBackground ?? this.authCardBackground,
      authCardBorder: authCardBorder ?? this.authCardBorder,
      authInputBorder: authInputBorder ?? this.authInputBorder,
      authMutedAction: authMutedAction ?? this.authMutedAction,
      authHeadingColor: authHeadingColor ?? this.authHeadingColor,
      authTextMuted: authTextMuted ?? this.authTextMuted,
    );
  }

  @override
  ThemeExtension<BcnThemePalette> lerp(
    covariant ThemeExtension<BcnThemePalette>? other,
    double t,
  ) {
    if (other is! BcnThemePalette) {
      return this;
    }
    return BcnThemePalette(
      primary: Color.lerp(primary, other.primary, t)!,
      background: Color.lerp(background, other.background, t)!,
      navigation: Color.lerp(navigation, other.navigation, t)!,
      onNavigation: Color.lerp(onNavigation, other.onNavigation, t)!,
      button: Color.lerp(button, other.button, t)!,
      onButton: Color.lerp(onButton, other.onButton, t)!,
      authPageBackground: Color.lerp(
        authPageBackground,
        other.authPageBackground,
        t,
      )!,
      authCardBackground: Color.lerp(
        authCardBackground,
        other.authCardBackground,
        t,
      )!,
      authCardBorder: Color.lerp(authCardBorder, other.authCardBorder, t)!,
      authInputBorder: Color.lerp(authInputBorder, other.authInputBorder, t)!,
      authMutedAction: Color.lerp(
        authMutedAction,
        other.authMutedAction,
        t,
      )!,
      authHeadingColor: Color.lerp(
        authHeadingColor,
        other.authHeadingColor,
        t,
      )!,
      authTextMuted: Color.lerp(authTextMuted, other.authTextMuted, t)!,
    );
  }
}

extension BcnThemePaletteBuildContextX on BuildContext {
  BcnThemePalette get bcnPalette =>
      Theme.of(this).extension<BcnThemePalette>() ??
      BcnThemePalette.light(null);
}

extension BcnThemePaletteThemeDataX on ThemeData {
  BcnThemePalette get bcnPalette =>
      extension<BcnThemePalette>() ?? BcnThemePalette.light(null);
}

class AppTheme {
  AppTheme._();

  static const String defaultPrimaryHex = '#173A63';
  static const String defaultBackgroundHex = '#F3F6FB';
  static const String defaultNavigationHex = '#173A63';
  static const String defaultButtonHex = '#173A63';

  static ThemeData light([ThemeCustomization? customization]) {
    return _buildTheme(Brightness.light, customization);
  }

  static ThemeData dark([ThemeCustomization? customization]) {
    return _buildTheme(Brightness.dark, customization);
  }

  static ThemeData _buildTheme(
    Brightness brightness,
    ThemeCustomization? customization,
  ) {
    final BcnThemePalette palette = brightness == Brightness.dark
        ? BcnThemePalette.dark(customization)
        : BcnThemePalette.light(customization);
    final Color primary = palette.primary;
    final Color background = palette.background;
    final Color surface = brightness == Brightness.dark
        ? _mix(background, Colors.white, 0.06)
        : _mix(background, Colors.white, 0.82);
    final Color surfaceHigh = brightness == Brightness.dark
        ? _mix(background, Colors.white, 0.12)
        : _mix(background, Colors.white, 0.6);
    final Color surfaceHighest = brightness == Brightness.dark
        ? _mix(primary, background, 0.78)
        : _mix(primary, background, 0.12);
    final Color onSurface = _foregroundFor(surface);
    final Color onSurfaceVariant = _mix(onSurface, surface, 0.45);
    final Color secondary = _mix(primary, palette.navigation, 0.45);
    final Color outline = _mix(primary, background, brightness == Brightness.dark ? 0.58 : 0.72);
    final Color outlineVariant = _mix(outline, surface, 0.38);
    final Color primaryContainer = brightness == Brightness.dark
        ? _mix(primary, Colors.black, 0.2)
        : _mix(primary, Colors.white, 0.76);
    final Color secondaryContainer = brightness == Brightness.dark
        ? _mix(secondary, Colors.black, 0.28)
        : _mix(secondary, background, 0.82);

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: _foregroundFor(primary),
      primaryContainer: primaryContainer,
      onPrimaryContainer: _foregroundFor(primaryContainer),
      secondary: secondary,
      onSecondary: _foregroundFor(secondary),
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: _foregroundFor(secondaryContainer),
      surface: surface,
      onSurface: onSurface,
      surfaceContainer: background,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: brightness == Brightness.dark
          ? const Color(0x33000000)
          : const Color(0x12000000),
    );

    final TextTheme textTheme = GoogleFonts.manropeTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.navigation,
        foregroundColor: palette.onNavigation,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: palette.onNavigation,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.3),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: surface,
        side: BorderSide(color: outlineVariant),
        selectedColor: primary,
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.button,
          foregroundColor: palette.onButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(0, 46),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.button,
          foregroundColor: palette.onButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(0, 46),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(0, 46),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.navigation,
        selectedItemColor: palette.onNavigation,
        unselectedItemColor: palette.onNavigation.withValues(alpha: 0.62),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return palette.onButton;
          }
          return surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return palette.button;
          }
          return surfaceHighest;
        }),
        trackOutlineColor: WidgetStatePropertyAll<Color>(outline),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return palette.button;
          }
          return surface;
        }),
        side: BorderSide(color: outline),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStatePropertyAll<Color>(palette.button),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.button,
      ),
      cardTheme: CardThemeData(
        color: surface,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      dividerColor: outlineVariant,
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }
}

Color _mix(Color first, Color second, double amount) {
  return Color.lerp(first, second, amount)!;
}

Color _foregroundFor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : const Color(0xFF10233B);
}
