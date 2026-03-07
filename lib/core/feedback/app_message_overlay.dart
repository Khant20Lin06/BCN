import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_message.dart';
import 'app_message_controller.dart';

class AppMessageOverlay extends ConsumerWidget {
  const AppMessageOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppMessage? message = ref.watch(appMessageControllerProvider);
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: IgnorePointer(
        ignoring: message == null,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final Animation<Offset> offset = Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: message == null
                  ? const SizedBox.shrink(key: ValueKey<String>('empty'))
                  : _MessageCard(
                      key: ValueKey<String>(message.id),
                      message: message,
                      theme: theme,
                      onClose: () => ref
                          .read(appMessageControllerProvider.notifier)
                          .dismiss(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    super.key,
    required this.message,
    required this.theme,
    required this.onClose,
  });

  final AppMessage message;
  final ThemeData theme;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final _MessageVisuals visuals = _visualsFor(message.type, theme);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Material(
        color: visuals.background,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: visuals.border),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 32,
                child: Icon(visuals.icon, color: visuals.foreground, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: visuals.foreground,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 32,
                child: IconButton(
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: visuals.foreground,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _MessageVisuals _visualsFor(AppMessageType type, ThemeData theme) {
    final ColorScheme scheme = theme.colorScheme;
    switch (type) {
      case AppMessageType.success:
        return _MessageVisuals(
          background: Color.alphaBlend(
            const Color(0x1F2EAD61),
            scheme.surface,
          ),
          border: const Color(0x662EAD61),
          foreground: const Color(0xFF15653A),
          icon: Icons.check_circle_rounded,
        );
      case AppMessageType.error:
        return _MessageVisuals(
          background: scheme.errorContainer,
          border: scheme.error.withValues(alpha: 0.35),
          foreground: scheme.onErrorContainer,
          icon: Icons.error_rounded,
        );
      case AppMessageType.info:
        return _MessageVisuals(
          background: scheme.secondaryContainer,
          border: scheme.primary.withValues(alpha: 0.22),
          foreground: scheme.onSecondaryContainer,
          icon: Icons.info_rounded,
        );
    }
  }
}

class _MessageVisuals {
  const _MessageVisuals({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
