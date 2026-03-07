import 'package:flutter/material.dart';

import 'app_feedback_extensions.dart';

class AppLoadErrorReporter extends StatefulWidget {
  const AppLoadErrorReporter({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  State<AppLoadErrorReporter> createState() => _AppLoadErrorReporterState();
}

class _AppLoadErrorReporterState extends State<AppLoadErrorReporter> {
  String? _reportedMessage;

  @override
  void initState() {
    super.initState();
    _report();
  }

  @override
  void didUpdateWidget(covariant AppLoadErrorReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _report();
    }
  }

  void _report() {
    final String normalized = widget.message.trim();
    if (normalized.isEmpty || normalized == _reportedMessage) {
      return;
    }

    _reportedMessage = normalized;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.showAppError(normalized);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
