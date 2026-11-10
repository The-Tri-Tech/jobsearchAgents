import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbridge_frontend/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('Renders DashboardScreen with header and overview items', (WidgetTester tester) async {
    // Provide a large desktop canvas for testing
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pumpAndSettle();

    // Verify Title & Overview exist
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Weekly Progress'), findsOneWidget);
    expect(find.text("Today's Tasks"), findsOneWidget);
  });
}
