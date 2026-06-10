import 'package:demo_roketota_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home screen shows camera demo buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const DemoRoketotaApp());

    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Video Record'), findsOneWidget);
  });
}
