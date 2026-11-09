import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbridge_frontend/features/auth/presentation/screens/auth_screen.dart';

void main() {
  testWidgets('Smoke test renders AuthScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    expect(find.text('AI Job Assistant'), findsOneWidget);
  });
}
