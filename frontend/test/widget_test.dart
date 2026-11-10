import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbridge_frontend/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('Smoke test renders DashboardScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('Overview'), findsWidgets);
  });
}
