import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final sentryServiceProvider = Provider<SentryService>((ref) {
  return SentryService();
});

class SentryService {
  Future<void> captureException(
    Object exception,
    StackTrace stackTrace, {
    String? hint,
  }) async {
    if (kDebugMode) {
      return;
    }
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: Hint.withMap(<String, Object?>{'hint': hint}),
    );
  }
}
