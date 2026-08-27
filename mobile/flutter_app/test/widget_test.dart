import 'package:flutter_test/flutter_test.dart';
import 'package:geobuzz/main.dart';

void main() {
  testWidgets('GeoBuzz app smoke test renders SplashScreen correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoBuzzApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 100));
  });
}
