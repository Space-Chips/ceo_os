String? normalizeDomainInput(
  String? raw, {
  Set<String> allowedSpecialValues = const {},
}) {
  final value = raw?.trim().toLowerCase();
  if (value == null || value.isEmpty) return null;
  if (allowedSpecialValues.contains(value)) return value;

  var normalized = value
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'^www\d*\.'), '');

  if (normalized.contains('@')) {
    normalized = normalized.split('@').last;
  }

  normalized = normalized.split(RegExp(r'[/?#]')).first;
  normalized = normalized.split(':').first;
  normalized = normalized.replaceAll(RegExp(r'^\.+|\.+$'), '');

  if (normalized.isEmpty ||
      normalized.contains(' ') ||
      !normalized.contains('.')) {
    return null;
  }

  return normalized;
}
