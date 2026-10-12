// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant_app/main.dart';

void main() {
  testWidgets('App login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with isLoggedIn = false.
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Verify that we are on the Login screen by checking branding text.
    expect(find.text('MERCHANT APP'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);

    // Verify presence of input fields
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
