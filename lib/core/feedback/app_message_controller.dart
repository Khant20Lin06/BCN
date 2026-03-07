import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failure.dart';
import 'app_message.dart';

final appMessageControllerProvider =
    StateNotifierProvider<AppMessageController, AppMessage?>(
      (Ref ref) => AppMessageController(),
    );

class AppMessageController extends StateNotifier<AppMessage?> {
  AppMessageController() : super(null);

  static const Duration _defaultAutoDismiss = Duration(seconds: 3);

  Timer? _dismissTimer;

  void showSuccess(String message, {Duration duration = _defaultAutoDismiss}) {
    _show(
      message: message,
      type: AppMessageType.success,
      sticky: false,
      duration: duration,
    );
  }

  void showError(String message, {bool sticky = true}) {
    _show(
      message: message,
      type: AppMessageType.error,
      sticky: sticky,
      duration: _defaultAutoDismiss,
    );
  }

  void showFailure(Failure failure, {bool sticky = true}) {
    showError(failure.message, sticky: sticky);
  }

  void showInfo(String message, {Duration duration = _defaultAutoDismiss}) {
    _show(
      message: message,
      type: AppMessageType.info,
      sticky: false,
      duration: duration,
    );
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    state = null;
  }

  void _show({
    required String message,
    required AppMessageType type,
    required bool sticky,
    required Duration duration,
  }) {
    final String normalized = message.trim();
    if (normalized.isEmpty) {
      return;
    }

    _dismissTimer?.cancel();
    final AppMessage next = AppMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      message: normalized,
      type: type,
      sticky: sticky,
      duration: duration,
    );
    state = next;

    if (!sticky) {
      _dismissTimer = Timer(duration, () {
        if (state?.id == next.id) {
          state = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
