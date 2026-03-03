import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  final String sentryDsn = const String.fromEnvironment('SENTRY_DSN');

  if (sentryDsn.isEmpty) {
    runApp(const ProviderScope(child: FrappeMobileApp()));
    return;
  }

  await SentryFlutter.init((options) {
    options.dsn = sentryDsn;
    options.enableNativeCrashHandling = true;
    options.environment = kReleaseMode ? 'prod' : 'dev';
    options.tracesSampleRate = 0.1;
  }, appRunner: () => runApp(const ProviderScope(child: FrappeMobileApp())));
}
