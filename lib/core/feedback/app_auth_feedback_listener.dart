import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import 'app_feedback_extensions.dart';

class AppAuthFeedbackListener extends ConsumerWidget {
  const AppAuthFeedbackListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authControllerProvider, (
      AuthState? previous,
      AuthState next,
    ) {
      if (!context.mounted) {
        return;
      }

      final String? nextError = next.errorMessage?.trim();
      final String? previousError = previous?.errorMessage?.trim();
      if ((next.status == AuthStatus.error ||
              next.status == AuthStatus.unauthenticated) &&
          nextError != null &&
          nextError.isNotEmpty &&
          nextError != previousError) {
        context.showAppError(nextError);
        return;
      }

      final bool completedLogin =
          previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.authenticated;
      if (completedLogin) {
        context.showAppSuccess('Login successful.');
        return;
      }

      final bool completedLogout =
          previous?.session != null &&
          previous?.status != AuthStatus.initial &&
          next.status == AuthStatus.unauthenticated;
      if (completedLogout) {
        context.showAppInfo('Logged out successfully.');
      }
    });

    return child;
  }
}
