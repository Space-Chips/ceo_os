class SupabaseConfig {
  static const String _defaultUrl = 'https://fyjojdynapdaoinpooyd.supabase.co';
  static const String _defaultAnonKey =
      'sb_publishable_wlDCa_sX4q5GVucuWbxMFw_4HPhUjzP';

  static String get url =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: _defaultUrl);
  static String get anonKey => const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultAnonKey,
  );
  static String get googleWebClientId =>
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static String get googleIosClientId =>
      const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static String get googleAndroidClientId =>
      const String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');

  static bool get hasGoogleIosMobileClientConfig =>
      googleWebClientId.isNotEmpty && googleIosClientId.isNotEmpty;

  static bool get hasGoogleAndroidMobileClientConfig =>
      googleWebClientId.isNotEmpty;

  static bool get hasGoogleMobileClientConfig =>
      hasGoogleIosMobileClientConfig || hasGoogleAndroidMobileClientConfig;

  static bool get hasRequiredConfiguration =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;

  static List<String> get missingRequiredKeys => [
        if (url.trim().isEmpty) 'SUPABASE_URL',
        if (anonKey.trim().isEmpty) 'SUPABASE_ANON_KEY',
      ];

  static List<String> get missingRequiredKeys {
    final missing = <String>[];
    if (url.trim().isEmpty) {
      missing.add('SUPABASE_URL');
    }
    if (anonKey.trim().isEmpty) {
      missing.add('SUPABASE_ANON_KEY');
    }
    return missing;
  }

  static bool get hasRequiredConfiguration =>
      missingRequiredKeys.isEmpty;

  static String get missingConfigurationMessage {
    final missing = missingRequiredKeys;
    if (missing.isEmpty) {
      return '';
    }
    if (missing.length == 1) {
      return 'Supabase configuration is missing. Provide ${missing.first}.';
    }
    return 'Supabase configuration is missing. Provide ${missing.join(' and ')}.';
  }

  static void validateConfiguration() {
    if (!hasRequiredConfiguration) {
      throw StateError(missingConfigurationMessage);
    }
  }
}
