// This is a basic Flutter widget test for the Food Freshness Detector app.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_3/main.dart';

void main() {
  testWidgets('FreshGuard dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame in local simulation mode.
    await tester.pumpWidget(const MyApp(firebaseInitialized: false));

    // Verify that the app title 'FreshGuard (Web)' is displayed.
    expect(find.text('FreshGuard (Web)'), findsOneWidget);

    // Verify that the status card renders the initial status 'FRESH'.
    expect(find.text('FRESH'), findsOneWidget);

    // Verify that we have a custom MQ Gas Sensor card.
    expect(find.text('MQ GAS LEVEL'), findsOneWidget);
  });
}
