import 'package:flutter_test/flutter_test.dart';
import 'package:ceo_os/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CeoOsApp());
    await tester.pumpAndSettle();
    // Should show login screen by default
    expect(find.text('CEO OS'), findsOneWidget);
  });
}
