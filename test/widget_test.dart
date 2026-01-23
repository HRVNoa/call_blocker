import 'package:flutter_test/flutter_test.dart';

import 'package:call_blocker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CallBlockerApp());

    // Verify that the app title is present
    expect(find.text('Anti-Démarchage'), findsOneWidget);
  });
}
