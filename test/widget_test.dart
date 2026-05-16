import 'package:ceo_os/features/auth/auth_support.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Auth trust footer shows legal and support entry points', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: SafeArea(
            child: AuthTrustFooter(),
          ),
        ),
      ),
    );

    expect(
      find.text('By continuing, you agree to the Terms of Use and Privacy Policy.'),
      findsOneWidget,
    );
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
  });
}
