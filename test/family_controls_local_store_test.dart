import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ceo_os/core/services/family_controls_local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FamilyControlsLocalStore website persistence', () {
    late FamilyControlsLocalStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = FamilyControlsLocalStore();
    });

    test('saves picker-selected website without plain domain label', () async {
      final created = await store.createBlockedWebsiteRecord(
        createdBy: 'user-1',
        urlDomain: null,
      );

      expect(created, isNotNull);
      expect(created!.urlDomain, isNull);

      final websites = await store.getBlockedWebsites();
      expect(websites.length, 1);
      expect(websites.first.id, created.id);
      expect(websites.first.urlDomain, isNull);
    });

    test('can later hydrate website domain label without changing id', () async {
      final created = await store.createBlockedWebsiteRecord(
        createdBy: 'user-1',
        urlDomain: null,
      );
      expect(created, isNotNull);

      await store.updateBlockedWebsiteDomain(created!.id, 'youtube.com');

      final websites = await store.getBlockedWebsites();
      expect(websites.length, 1);
      expect(websites.first.id, created.id);
      expect(websites.first.urlDomain, 'youtube.com');
    });
  });
}
