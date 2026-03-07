import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frappe_mobile_item_app/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Login page renders current required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    expect(find.text('Login to BCN'), findsOneWidget);
    expect(find.text('Username, email or phone'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('Change Server URL'), findsOneWidget);
  });
}
