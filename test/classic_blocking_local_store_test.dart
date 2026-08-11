import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ceo_os/core/services/classic_blocking_local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClassicBlockingLocalStore', () {
    late ClassicBlockingLocalStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = ClassicBlockingLocalStore();
    });

    test('keeps app and website bindings separated', () async {
      await store.saveAppBinding(
        rowId: 'app-1',
        nativeIdentifier: 'com.example.app1',
        nativePayload: 'payload-app-1',
      );
      await store.saveWebsiteBinding(
        rowId: 'site-1',
        nativeIdentifier: 'example.com',
        nativePayload: 'payload-site-1',
      );

      final appBindings = await store.loadAppBindings();
      final websiteBindings = await store.loadWebsiteBindings();

      expect(appBindings.keys, contains('app-1'));
      expect(appBindings.keys, isNot(contains('site-1')));
      expect(websiteBindings.keys, contains('site-1'));
      expect(websiteBindings.keys, isNot(contains('app-1')));
    });

    test('persists independent app bindings for multi-selection', () async {
      await store.saveAppBinding(
        rowId: 'app-a',
        nativeIdentifier: 'com.example.a',
        nativePayload: 'payload-a',
      );
      await store.saveAppBinding(
        rowId: 'app-b',
        nativeIdentifier: 'com.example.b',
        nativePayload: 'payload-b',
      );

      final appBindings = await store.loadAppBindings();
      expect(appBindings.length, 2);
      expect(appBindings['app-a']?.nativePayload, 'payload-a');
      expect(appBindings['app-b']?.nativePayload, 'payload-b');
    });

    test('prune does not cross-mutate app and website bindings', () async {
      await store.saveAppBinding(
        rowId: 'app-keep',
        nativeIdentifier: 'com.example.keep',
      );
      await store.saveAppBinding(
        rowId: 'app-drop',
        nativeIdentifier: 'com.example.drop',
      );
      await store.saveWebsiteBinding(
        rowId: 'site-keep',
        nativeIdentifier: 'keep.com',
      );
      await store.saveWebsiteBinding(
        rowId: 'site-drop',
        nativeIdentifier: 'drop.com',
      );

      await store.prune(appIds: {'app-keep'}, websiteIds: {'site-keep'});

      final appBindings = await store.loadAppBindings();
      final websiteBindings = await store.loadWebsiteBindings();

      expect(appBindings.keys, equals({'app-keep'}));
      expect(websiteBindings.keys, equals({'site-keep'}));
    });
  });
}
