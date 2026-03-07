import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frappe_mobile_item_app/core/feedback/app_message_controller.dart';
import 'package:frappe_mobile_item_app/core/feedback/app_message_overlay.dart';

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const <Widget>[
                Positioned.fill(child: SizedBox.expand()),
                AppMessageOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('success message shows at top and auto dismisses', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpOverlay(tester, container);

    container.read(appMessageControllerProvider.notifier).showSuccess('Saved.');
    await tester.pump();

    expect(find.text('Saved.'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Saved.'), findsNothing);
  });

  testWidgets('error message stays until dismissed manually', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpOverlay(tester, container);

    container.read(appMessageControllerProvider.notifier).showError('Failed.');
    await tester.pump();

    expect(find.text('Failed.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Failed.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Failed.'), findsNothing);
  });

  testWidgets('new message replaces current message', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpOverlay(tester, container);

    container.read(appMessageControllerProvider.notifier).showInfo('Loading...');
    await tester.pump();
    expect(find.text('Loading...'), findsOneWidget);

    container.read(appMessageControllerProvider.notifier).showError('Could not load.');
    await tester.pumpAndSettle();

    expect(find.text('Loading...'), findsNothing);
    expect(find.text('Could not load.'), findsOneWidget);
  });
}
