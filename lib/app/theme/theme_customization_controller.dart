import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage_service.dart';
import 'theme_customization.dart';

final themeCustomizationControllerProvider =
    StateNotifierProvider<ThemeCustomizationController, ThemeCustomization>((
      Ref ref,
    ) {
      return ThemeCustomizationController(
        ref.watch(secureStorageServiceProvider),
      );
    });

class ThemeCustomizationController extends StateNotifier<ThemeCustomization> {
  ThemeCustomizationController(this._storage)
    : super(ThemeCustomization.defaults()) {
    _load();
  }

  final SecureStorageService _storage;

  Future<void> _load() async {
    final ThemeCustomization? saved = await _storage.getThemeCustomization();
    if (saved == null) {
      return;
    }
    state = saved;
  }

  Future<void> selectColor(ThemeColorSection section, String hex) async {
    final String normalized = normalizeHex(hex);
    if (!isValidHex(normalized)) {
      return;
    }
    final Map<String, List<String>> nextPalettes = _copyPalettes();
    nextPalettes[section.key] = <String>{
      ...(nextPalettes[section.key] ?? const <String>[]),
      normalized,
    }.toList(growable: false);
    state = _applySelected(section, normalized, nextPalettes);
    await _storage.saveThemeCustomization(state);
  }

  Future<void> addCustomColor(ThemeColorSection section, String hex) async {
    await selectColor(section, hex);
  }

  Future<void> removeCustomColor(ThemeColorSection section, String hex) async {
    final String normalized = normalizeHex(hex);
    final List<String> defaultColors = state.defaultColorsFor(section);
    if (defaultColors.contains(normalized)) {
      return;
    }

    final Map<String, List<String>> nextPalettes = _copyPalettes();
    nextPalettes[section.key] = <String>[
      ...(nextPalettes[section.key] ?? const <String>[]),
    ]..removeWhere((String value) => normalizeHex(value) == normalized);

    final String currentSelected = normalizeHex(state.selectedHexFor(section));
    final String fallback = defaultColors.isNotEmpty
        ? defaultColors.first
        : ThemeCustomization.defaults().selectedHexFor(section);

    state = _applySelected(
      section,
      currentSelected == normalized ? fallback : currentSelected,
      nextPalettes,
    );
    await _storage.saveThemeCustomization(state);
  }

  Future<void> reset() async {
    state = ThemeCustomization.defaults();
    await _storage.saveThemeCustomization(state);
  }

  Map<String, List<String>> _copyPalettes() {
    return <String, List<String>>{
      for (final MapEntry<String, List<String>> entry in state.palettes.entries)
        entry.key: List<String>.from(entry.value),
    };
  }

  ThemeCustomization _applySelected(
    ThemeColorSection section,
    String hex,
    Map<String, List<String>> palettes,
  ) {
    switch (section) {
      case ThemeColorSection.primary:
        return state.copyWith(primaryHex: hex, palettes: palettes);
      case ThemeColorSection.background:
        return state.copyWith(backgroundHex: hex, palettes: palettes);
      case ThemeColorSection.navigation:
        return state.copyWith(navigationHex: hex, palettes: palettes);
      case ThemeColorSection.button:
        return state.copyWith(buttonHex: hex, palettes: palettes);
    }
  }
}
