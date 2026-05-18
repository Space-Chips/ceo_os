class SupabaseConfig {
  static const String _debugUrl = 'https://fyjojdynapdaoinpooyd.supabase.co';
  static const String _debugAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5am9qZHluYXBkYW9pbnBvb3lkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5OTk3MTgsImV4cCI6MjA4NjU3NTcxOH0.GcHhxLQF6UA149KQUkph4XYsVnc3K_TlcKWOup3ki_4';

  static String get url {
    const env = String.fromEnvironment('SUPABASE_URL');
    if (env.isNotEmpty) return env;
    return _debugUrl;
  }

  static String get anonKey {
    const env = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (env.isNotEmpty) return env;
    return _debugAnonKey;
  }

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

  static bool get hasRequiredConfiguration => missingRequiredKeys.isEmpty;

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
