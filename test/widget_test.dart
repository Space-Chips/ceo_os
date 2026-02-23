import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';

void main() {
  testWidgets('Widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CupertinoPageScaffold(child: Center(child: Text('CEO OS'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CEO OS'), findsOneWidget);
  });
}
