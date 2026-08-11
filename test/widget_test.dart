import 'package:ceo_os/core/providers/language_provider.dart';
import 'package:ceo_os/features/auth/auth_support.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AuthTrustFooter now reads LanguageProvider via context.watch(), and
  // LanguageProvider's constructor touches Supabase.instance. Initialize a
  // throwaway Supabase client and mock SharedPreferences so the provider can
  // be constructed inside the test harness. No network is performed here.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('Auth trust footer shows legal and support entry points', (
    WidgetTester tester,
  ) async {
    final language = LanguageProvider();
    addTearDown(language.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageProvider>.value(
        value: language,
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: SafeArea(
              child: AuthTrustFooter(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The footer renders one trust line plus three inline links (terms,
    // privacy, support). We assert the structure rather than localized copy so
    // the test stays stable across translation changes.
    expect(find.byType(AuthTrustFooter), findsOneWidget);
    expect(find.byType(CupertinoButton), findsNWidgets(3));
    expect(find.byType(Text), findsNWidgets(4));
  });
}
