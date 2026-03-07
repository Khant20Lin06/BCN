import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/theme_customization.dart';
import '../../../../app/theme/theme_customization_controller.dart';
import '../../../../core/feedback/app_feedback.dart';

class ThemeCustomizationPage extends ConsumerStatefulWidget {
  const ThemeCustomizationPage({super.key});

  @override
  ConsumerState<ThemeCustomizationPage> createState() =>
      _ThemeCustomizationPageState();
}

class _ThemeCustomizationPageState
    extends ConsumerState<ThemeCustomizationPage> {
  late final Map<ThemeColorSection, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = <ThemeColorSection, TextEditingController>{
      for (final ThemeColorSection section in ThemeColorSection.values)
        section: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addColor(ThemeColorSection section) async {
    final TextEditingController controller = _controllers[section]!;
    final String hex = normalizeHex(controller.text);
    if (!isValidHex(hex)) {
      context.showAppError('Enter a valid color code like #173A63.');
      return;
    }

    await ref
        .read(themeCustomizationControllerProvider.notifier)
        .addCustomColor(section, hex);
    controller.clear();
    if (!mounted) {
      return;
    }
    context.showAppSuccess('${section.label} color updated.');
  }

  Future<void> _resetTheme() async {
    await ref.read(themeCustomizationControllerProvider.notifier).reset();
    if (!mounted) {
      return;
    }
    context.showAppInfo('Theme reset to default colors.');
  }

  Future<void> _removeColor(ThemeColorSection section, String hex) async {
    await ref
        .read(themeCustomizationControllerProvider.notifier)
        .removeCustomColor(section, hex);
    if (!mounted) {
      return;
    }
    context.showAppInfo('${section.label} color removed.');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeCustomization settings = ref.watch(
      themeCustomizationControllerProvider,
    );
    final ThemeData theme = Theme.of(context);
    final BcnThemePalette palette = theme.bcnPalette;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Theme Studio',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetTheme,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: <Widget>[
                  _ThemePreviewCard(
                    backgroundColor: colorFromHex(settings.backgroundHex),
                    navigationColor: colorFromHex(settings.navigationHex),
                    buttonColor: colorFromHex(settings.buttonHex),
                    primaryColor: colorFromHex(settings.primaryHex),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose one of the preset colors or add your own hex code.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final ThemeColorSection section in ThemeColorSection.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ThemeSectionCard(
                        section: section,
                        settings: settings,
                        controller: _controllers[section]!,
                        onSelect: (String hex) async {
                          await ref
                              .read(
                                themeCustomizationControllerProvider.notifier,
                              )
                              .selectColor(section, hex);
                          if (!context.mounted) {
                            return;
                          }
                          context.showAppInfo('${section.label} updated.');
                        },
                        onAdd: () => _addColor(section),
                        onRemove: (String hex) => _removeColor(section, hex),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.authCardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.authCardBorder),
                    ),
                    child: Text(
                      'Accepted formats: #RRGGBB or #AARRGGBB. Changes are saved on this device immediately.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.authTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.backgroundColor,
    required this.navigationColor,
    required this.buttonColor,
    required this.primaryColor,
  });

  final Color backgroundColor;
  final Color navigationColor;
  final Color buttonColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color onNavigation = ThemeData.estimateBrightnessForColor(
              navigationColor,
            ) ==
            Brightness.dark
        ? Colors.white
        : const Color(0xFF10233B);
    final Color onButton = ThemeData.estimateBrightnessForColor(buttonColor) ==
            Brightness.dark
        ? Colors.white
        : const Color(0xFF10233B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Live Preview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: navigationColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.menu_rounded, color: onNavigation),
                      const SizedBox(width: 10),
                      Text(
                        'Header Navbar',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: onNavigation,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Background & content area',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: buttonColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Button',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: onButton,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: navigationColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(17),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Icon(Icons.home_rounded, color: onNavigation),
                      Icon(Icons.inventory_2_rounded, color: onNavigation),
                      Icon(Icons.analytics_rounded, color: onNavigation),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSectionCard extends StatelessWidget {
  const _ThemeSectionCard({
    required this.section,
    required this.settings,
    required this.controller,
    required this.onSelect,
    required this.onAdd,
    required this.onRemove,
  });

  final ThemeColorSection section;
  final ThemeCustomization settings;
  final TextEditingController controller;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String selectedHex = settings.selectedHexFor(section);
    final List<String> defaultColors = settings.defaultColorsFor(section);
    final bool canDeleteSelected = !defaultColors.contains(
      normalizeHex(selectedHex),
    );
    final BcnThemePalette palette = context.bcnPalette;
    final String previewHex = normalizeHex(controller.text);
    final bool hasValidPreview = isValidHex(previewHex);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  section.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                selectedHex,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.authTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final String hex in settings.colorsFor(section))
                _ColorSwatchButton(
                  hex: hex,
                  selected: normalizeHex(hex) == normalizeHex(selectedHex),
                  removable: !defaultColors.contains(normalizeHex(hex)),
                  onTap: () => onSelect(hex),
                  onRemove: () => onRemove(hex),
                ),
            ],
          ),
          if (canDeleteSelected) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => onRemove(selectedHex),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete Selected Color'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: '#173A63',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: hasValidPreview
                              ? colorFromHex(previewHex)
                              : palette.authMutedAction,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: palette.authCardBorder),
                        ),
                        child: const SizedBox(width: 24, height: 24),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 52,
                      minHeight: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(88, 54),
                  backgroundColor: palette.button,
                  foregroundColor: palette.onButton,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
    required this.hex,
    required this.selected,
    required this.removable,
    required this.onTap,
    required this.onRemove,
  });

  final String hex;
  final bool selected;
  final bool removable;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = colorFromHex(hex);
    final Color borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: selected ? 2.4 : 1.2,
                  ),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.16,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: ThemeData.estimateBrightnessForColor(color) ==
                                Brightness.dark
                            ? Colors.white
                            : const Color(0xFF10233B),
                      )
                    : null,
              ),
            ),
          ),
          if (removable)
            Positioned(
              top: -6,
              right: -6,
              child: Material(
                color: theme.colorScheme.error,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: theme.colorScheme.onError,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
