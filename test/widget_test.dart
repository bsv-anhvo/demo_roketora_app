import 'package:demo_roketota_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Home screen shows camera demo buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DemoRoketoraApp(),
      ),
    );

    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Record Video'), findsOneWidget);
  });
}
