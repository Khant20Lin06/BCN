import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feedback/app_feedback.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_customization_controller.dart';

class FrappeMobileApp extends ConsumerWidget {
  const FrappeMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeCustomization = ref.watch(themeCustomizationControllerProvider);

    return MaterialApp.router(
      title: 'ERP Item Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(themeCustomization),
      darkTheme: AppTheme.dark(themeCustomization),
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) {
        return AppAuthFeedbackListener(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              child ?? const SizedBox.shrink(),
              const AppMessageOverlay(),
            ],
          ),
        );
      },
    );
  }
}
