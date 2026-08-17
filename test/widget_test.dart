import 'package:citymu/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CityMu App smoke test', (WidgetTester tester) async {
    // Build CityMuApp and trigger a frame.
    await tester.pumpWidget(const CityMuApp());

    // Verify that the title and branding are rendered
    expect(find.text('CityMu'), findsOneWidget);
    expect(find.text('台灣城市空間聲景 · 即時生成式 Lo-Fi'), findsOneWidget);
  });
}
