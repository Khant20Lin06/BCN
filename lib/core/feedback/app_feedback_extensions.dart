import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failure.dart';
import 'app_message_controller.dart';

extension AppFeedbackBuildContextX on BuildContext {
  AppMessageController get _appMessageController =>
      ProviderScope.containerOf(this, listen: false).read(
        appMessageControllerProvider.notifier,
      );

  void showAppSuccess(String message) {
    _appMessageController.showSuccess(message);
  }

  void showAppError(String message, {bool sticky = true}) {
    _appMessageController.showError(message, sticky: sticky);
  }

  void showAppFailure(Failure failure, {bool sticky = true}) {
    _appMessageController.showFailure(failure, sticky: sticky);
  }

  void showAppInfo(String message) {
    _appMessageController.showInfo(message);
  }

  void dismissAppMessage() {
    _appMessageController.dismiss();
  }
}
