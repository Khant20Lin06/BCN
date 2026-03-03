import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frappe_mobile_item_app/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Login page renders required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    expect(find.text('ERPNext Mobile'), findsOneWidget);
    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
