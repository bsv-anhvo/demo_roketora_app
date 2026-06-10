import 'package:demo_roketota_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home screen shows camera demo buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const DemoRoketotaApp());

    expect(find.text('写真を撮る'), findsOneWidget);
    expect(find.text('動画撮影'), findsOneWidget);
  });
}
