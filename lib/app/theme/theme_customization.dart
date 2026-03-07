import 'package:flutter/material.dart';

enum ThemeColorSection { primary, background, navigation, button }

extension ThemeColorSectionX on ThemeColorSection {
  String get key {
    switch (this) {
      case ThemeColorSection.primary:
        return 'primary';
      case ThemeColorSection.background:
        return 'background';
      case ThemeColorSection.navigation:
        return 'navigation';
      case ThemeColorSection.button:
        return 'button';
    }
  }

  String get label {
    switch (this) {
      case ThemeColorSection.primary:
        return 'Color';
      case ThemeColorSection.background:
        return 'Background';
      case ThemeColorSection.navigation:
        return 'Footer & Header Navbar';
      case ThemeColorSection.button:
        return 'Button';
    }
  }
}

class ThemeCustomization {
  const ThemeCustomization({
    required this.primaryHex,
    required this.backgroundHex,
    required this.navigationHex,
    required this.buttonHex,
    required this.palettes,
  });

  factory ThemeCustomization.defaults() {
    return ThemeCustomization(
      primaryHex: '#173A63',
      backgroundHex: '#F3F6FB',
      navigationHex: '#173A63',
      buttonHex: '#173A63',
      palettes: <String, List<String>>{
        ThemeColorSection.primary.key: const <String>[
          '#173A63',
          '#214E88',
          '#2C5A8F',
          '#335C81',
          '#0F2D4D',
        ],
        ThemeColorSection.background.key: const <String>[
          '#F3F6FB',
          '#EEF3F9',
          '#E8EEF6',
          '#F7F9FC',
          '#FFFFFF',
        ],
        ThemeColorSection.navigation.key: const <String>[
          '#173A63',
          '#102A47',
          '#1F4878',
          '#2A4D77',
          '#0C2139',
        ],
        ThemeColorSection.button.key: const <String>[
          '#173A63',
          '#214E88',
          '#2C5A8F',
          '#335C81',
          '#0F2D4D',
        ],
      },
    );
  }

  final String primaryHex;
  final String backgroundHex;
  final String navigationHex;
  final String buttonHex;
  final Map<String, List<String>> palettes;

  List<String> defaultColorsFor(ThemeColorSection section) {
    return List<String>.from(
      ThemeCustomization.defaults().palettes[section.key] ?? const <String>[],
      growable: false,
    ).map(normalizeHex).toList(growable: false);
  }

  List<String> colorsFor(ThemeColorSection section) {
    final List<String> existing = palettes[section.key] ?? const <String>[];
    final String selectedHex = selectedHexFor(section);
    final List<String> merged = <String>{
      for (final String value in existing) normalizeHex(value),
      normalizeHex(selectedHex),
    }.toList(growable: false);
    return merged;
  }

  String selectedHexFor(ThemeColorSection section) {
    switch (section) {
      case ThemeColorSection.primary:
        return primaryHex;
      case ThemeColorSection.background:
        return backgroundHex;
      case ThemeColorSection.navigation:
        return navigationHex;
      case ThemeColorSection.button:
        return buttonHex;
    }
  }

  ThemeCustomization copyWith({
    String? primaryHex,
    String? backgroundHex,
    String? navigationHex,
    String? buttonHex,
    Map<String, List<String>>? palettes,
  }) {
    return ThemeCustomization(
      primaryHex: normalizeHex(primaryHex ?? this.primaryHex),
      backgroundHex: normalizeHex(backgroundHex ?? this.backgroundHex),
      navigationHex: normalizeHex(navigationHex ?? this.navigationHex),
      buttonHex: normalizeHex(buttonHex ?? this.buttonHex),
      palettes: palettes ?? this.palettes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'primaryHex': normalizeHex(primaryHex),
      'backgroundHex': normalizeHex(backgroundHex),
      'navigationHex': normalizeHex(navigationHex),
      'buttonHex': normalizeHex(buttonHex),
      'palettes': palettes.map(
        (String key, List<String> value) => MapEntry<String, dynamic>(
          key,
          value.map(normalizeHex).toList(growable: false),
        ),
      ),
    };
  }

  factory ThemeCustomization.fromJson(Map<String, dynamic> json) {
    final ThemeCustomization defaults = ThemeCustomization.defaults();
    final Map<String, dynamic> rawPalettes =
        (json['palettes'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final Map<String, List<String>> palettes = <String, List<String>>{
      for (final ThemeColorSection section in ThemeColorSection.values)
        section.key: <String>{
          ...defaults.colorsFor(section),
          ...((rawPalettes[section.key] as List<dynamic>?) ?? const <dynamic>[])
              .map((dynamic value) => normalizeHex(value.toString()))
              .where((String value) => isValidHex(value)),
        }.toList(growable: false),
    };

    return ThemeCustomization(
      primaryHex: _readColor(json['primaryHex'], defaults.primaryHex),
      backgroundHex: _readColor(json['backgroundHex'], defaults.backgroundHex),
      navigationHex: _readColor(json['navigationHex'], defaults.navigationHex),
      buttonHex: _readColor(json['buttonHex'], defaults.buttonHex),
      palettes: palettes,
    );
  }

  static String _readColor(dynamic raw, String fallback) {
    final String candidate = normalizeHex((raw ?? '').toString());
    return isValidHex(candidate) ? candidate : fallback;
  }
}

String normalizeHex(String raw) {
  String value = raw.trim().toUpperCase();
  if (!value.startsWith('#')) {
    value = '#$value';
  }
  if (value.length == 7 || value.length == 9) {
    return value;
  }
  return value;
}

bool isValidHex(String raw) {
  final String value = normalizeHex(raw);
  return RegExp(r'^#([0-9A-F]{6}|[0-9A-F]{8})$').hasMatch(value);
}

Color colorFromHex(String raw) {
  final String normalized = normalizeHex(raw);
  final String hex = normalized.substring(1);
  final int value = int.parse(hex, radix: 16);
  if (hex.length == 6) {
    return Color(0xFF000000 | value);
  }
  return Color(value);
}
