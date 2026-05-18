import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/settings_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/services/classic_blocking_coordinator.dart';
import '../../core/services/classic_blocking_local_store.dart';
import '../../core/services/focus_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/android_protection_disclosure.dart';
import '../../core/utils/domain_utils.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';
import '../focus/app_selection_sheet.dart';

class ScreenTimeScreen extends StatefulWidget {
  final String? initialSection;

  const ScreenTimeScreen({super.key, this.initialSection});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  static const List<String> _websiteSuggestions = [
    'youtube.com',
    'tiktok.com',
    'instagram.com',
    'facebook.com',
    'x.com',
    'twitter.com',
    'reddit.com',
    'twitch.tv',
    'netflix.com',
    'primevideo.com',
    'discord.com',
    'snapchat.com',
    'pinterest.com',
    'linkedin.com',
    'news.ycombinator.com',
    'google.com',
    'bing.com',
    'duckduckgo.com',
  ];
  static const List<_IosAppSuggestion> _iosAppSuggestions = [
    _IosAppSuggestion(
      label: 'Safari',
      bundleIdentifier: 'com.apple.mobilesafari',
      keywords: ['browser', 'web'],
    ),
    _IosAppSuggestion(
      label: 'YouTube',
      bundleIdentifier: 'com.google.ios.youtube',
      keywords: ['video', 'google'],
    ),
    _IosAppSuggestion(
      label: 'Instagram',
      bundleIdentifier: 'com.burbn.instagram',
      keywords: ['social', 'meta'],
    ),
    _IosAppSuggestion(
      label: 'TikTok',
      bundleIdentifier: 'com.zhiliaoapp.musically',
      keywords: ['social', 'video'],
    ),
    _IosAppSuggestion(
      label: 'X',
      bundleIdentifier: 'com.atebits.Tweetie2',
      keywords: ['twitter', 'social'],
    ),
    _IosAppSuggestion(
      label: 'Reddit',
      bundleIdentifier: 'com.reddit.Reddit',
      keywords: ['social', 'forum'],
    ),
    _IosAppSuggestion(
      label: 'Discord',
      bundleIdentifier: 'com.hammerandchisel.discord',
      keywords: ['chat', 'social'],
    ),
    _IosAppSuggestion(
      label: 'Facebook',
      bundleIdentifier: 'com.facebook.Facebook',
      keywords: ['social', 'meta'],
    ),
    _IosAppSuggestion(
      label: 'Messenger',
      bundleIdentifier: 'com.facebook.Messenger',
      keywords: ['chat', 'meta'],
    ),
    _IosAppSuggestion(
      label: 'Snapchat',
      bundleIdentifier: 'com.toyopagroup.picaboo',
      keywords: ['social', 'chat'],
    ),
    _IosAppSuggestion(
      label: 'WhatsApp',
      bundleIdentifier: 'net.whatsapp.WhatsApp',
      keywords: ['chat', 'meta'],
    ),
    _IosAppSuggestion(
      label: 'Telegram',
      bundleIdentifier: 'ph.telegra.Telegraph',
      keywords: ['chat', 'messages'],
    ),
    _IosAppSuggestion(
      label: 'Spotify',
      bundleIdentifier: 'com.spotify.client',
      keywords: ['music', 'audio'],
    ),
    _IosAppSuggestion(
      label: 'Netflix',
      bundleIdentifier: 'com.netflix.Netflix',
      keywords: ['video', 'streaming'],
    ),
    _IosAppSuggestion(
      label: 'Prime Video',
      bundleIdentifier: 'com.amazon.aiv.AIVApp',
      keywords: ['video', 'streaming'],
    ),
    _IosAppSuggestion(
      label: 'Twitch',
      bundleIdentifier: 'tv.twitch',
      keywords: ['video', 'streaming'],
    ),
    _IosAppSuggestion(
      label: 'Pinterest',
      bundleIdentifier: 'pinterest',
      keywords: ['social', 'images'],
    ),
    _IosAppSuggestion(
      label: 'LinkedIn',
      bundleIdentifier: 'com.linkedin.LinkedIn',
      keywords: ['social', 'work'],
    ),
    _IosAppSuggestion(
      label: 'Google',
      bundleIdentifier: 'com.google.GoogleMobile',
      keywords: ['search', 'web'],
    ),
    _IosAppSuggestion(
      label: 'Google Chrome',
      bundleIdentifier: 'com.google.chrome.ios',
      keywords: ['browser', 'google'],
    ),
    _IosAppSuggestion(
      label: 'Google Drive',
      bundleIdentifier: 'com.google.Drive',
      keywords: ['goo', 'google', 'storage'],
    ),
    _IosAppSuggestion(
      label: 'Google Photos',
      bundleIdentifier: 'com.google.Photos',
      keywords: ['goo', 'google', 'images'],
    ),
    _IosAppSuggestion(
      label: 'Gmail',
      bundleIdentifier: 'com.google.Gmail',
      keywords: ['mail', 'google'],
    ),
    _IosAppSuggestion(
      label: 'Google Maps',
      bundleIdentifier: 'com.google.Maps',
      keywords: ['maps', 'google'],
    ),
    _IosAppSuggestion(
      label: 'Google Docs',
      bundleIdentifier: 'com.google.Docs',
      keywords: ['google', 'docs'],
    ),
    _IosAppSuggestion(
      label: 'Google Sheets',
      bundleIdentifier: 'com.google.Sheets',
      keywords: ['google', 'sheets'],
    ),
    _IosAppSuggestion(
      label: 'Google Meet',
      bundleIdentifier: 'com.google.Tachyon',
      keywords: ['google', 'meet', 'video'],
    ),
    _IosAppSuggestion(
      label: 'Messages',
      bundleIdentifier: 'com.apple.MobileSMS',
      keywords: ['sms', 'chat', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Mail',
      bundleIdentifier: 'com.apple.mobilemail',
      keywords: ['email', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Phone',
      bundleIdentifier: 'com.apple.mobilephone',
      keywords: ['call', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'FaceTime',
      bundleIdentifier: 'com.apple.facetime',
      keywords: ['call', 'video', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Photos',
      bundleIdentifier: 'com.apple.mobileslideshow',
      keywords: ['images', 'gallery', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Camera',
      bundleIdentifier: 'com.apple.camera',
      keywords: ['photo', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Clock',
      bundleIdentifier: 'com.apple.mobiletimer',
      keywords: ['alarm', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Calendar',
      bundleIdentifier: 'com.apple.mobilecal',
      keywords: ['agenda', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Files',
      bundleIdentifier: 'com.apple.DocumentsApp',
      keywords: ['documents', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Notes',
      bundleIdentifier: 'com.apple.mobilenotes',
      keywords: ['notes', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Maps',
      bundleIdentifier: 'com.apple.Maps',
      keywords: ['maps', 'apple'],
    ),
    _IosAppSuggestion(
      label: 'Settings',
      bundleIdentifier: 'com.apple.Preferences',
      keywords: ['config', 'apple'],
    ),
  ];
  final FeatureRepository _repo = FeatureRepository();
  final FocusService _focusService = FocusService();
  final ClassicBlockingLocalStore _classicLocalStore =
      ClassicBlockingLocalStore();
  final ClassicBlockingCoordinator _classicCoordinator =
      ClassicBlockingCoordinator();
  final TextEditingController _siteCtrl = TextEditingController();
  final TextEditingController _appCtrl = TextEditingController();
  final GlobalKey _accessSectionKey = GlobalKey();
  final GlobalKey _appsSectionKey = GlobalKey();
  final GlobalKey _sitesSectionKey = GlobalKey();
  final GlobalKey _pausesSectionKey = GlobalKey();

  List<BlockedApp> _blockedApps = [];
  List<BlockedWebsite> _blockedWebsites = [];
  List<RestPeriod> _restPeriods = [];
  List<Map<String, dynamic>> _logs = [];
  Map<String, ClassicBlockBinding> _appBindings = const {};
  Map<String, ClassicBlockBinding> _websiteBindings = const {};
  bool _adultContentShieldEnabled = false;
  FocusProtectionStatus _protectionStatus = FocusProtectionStatus.unknown;
  FocusPermissionState _accessibilityState = FocusPermissionState.unknown;
  FocusPermissionState _usageAccessState = FocusPermissionState.unknown;

  bool _loading = true;
  bool _saving = false;
  bool _showAddApp = false;
  bool _showAddWebsite = false;
  bool _didJumpToInitialSection = false;

  bool get _isAndroid => Platform.isAndroid;
  String get totalHours {
    final seconds = _logs.fold<int>(
      0,
      (sum, log) => sum + ((log['duration_seconds'] as num?)?.toInt() ?? 0),
    );
    return (seconds / 3600).toStringAsFixed(1);
  }

  String _t(String key) => context.read<LanguageProvider>().t(key);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _addBlockedIosWebsitesFromPicker() async {
    if (_saving || !Platform.isIOS) return;

    final authorized = await _focusService.isAuthorized();
    if (!authorized) {
      final granted = await _focusService.requestPermissions();
      if (!granted) {
        await _showNotice(
          title: _t('screen_time_permissions_required'),
          message: _t('screen_time_permissions_required_websites_message'),
        );
        return;
      }
    }

    final selections = await _focusService
        .openFamilyActivityWebsitePickerWithMetadata();
    final picked = (selections ?? [])
        .where((item) => item.payload.trim().isNotEmpty)
        .toList(growable: false);
    if (picked.isEmpty) {
      await _showNotice(
        title: _t('screen_time_no_website_selected'),
        message: _t('screen_time_no_website_selected_message'),
      );
      return;
    }

    final websiteBindings = await _classicLocalStore.loadWebsiteBindings();

    await _runMutation(() async {
      final existingPayloads = _blockedWebsites
          .map((site) => websiteBindings[site.id]?.nativePayload?.trim())
          .whereType<String>()
          .where((payload) => payload.isNotEmpty)
          .toSet();
      final existingDomains = <String>{
        for (final site in _blockedWebsites)
          if ((site.urlDomain ?? '').trim().isNotEmpty)
            (site.urlDomain ?? '').trim().toLowerCase(),
        for (final binding in websiteBindings.values)
          if ((binding.nativeIdentifier ?? '').trim().isNotEmpty)
            (binding.nativeIdentifier ?? '').trim().toLowerCase(),
      };
      for (final selected in picked) {
        final payload = selected.payload.trim();
        if (payload.isEmpty || existingPayloads.contains(payload)) continue;
        var resolved = selected.domain?.trim();
        if (resolved == null || resolved.isEmpty) {
          resolved = (await _focusService.describeWebsiteSelectionPayload(
            payload,
          ))?.domain?.trim();
        }
        final domain = (resolved != null && resolved.isNotEmpty)
            ? normalizeDomainInput(resolved) ?? resolved.toLowerCase()
            : null;
        final normalizedDomain = domain?.trim().toLowerCase();
        if (normalizedDomain != null &&
            normalizedDomain.isNotEmpty &&
            existingDomains.contains(normalizedDomain)) {
          continue;
        }
        final label =
            domain ??
            'selected-website-${DateTime.now().microsecondsSinceEpoch}';
        final record = await _repo.createBlockedWebsiteRecord(label);
        if (record == null) continue;
        await _classicLocalStore.saveWebsiteBinding(
          rowId: record.id,
          nativeIdentifier: domain,
          nativePayload: payload,
        );
        existingPayloads.add(payload);
        if (normalizedDomain != null && normalizedDomain.isNotEmpty) {
          existingDomains.add(normalizedDomain);
        }
      }
    });
  }

  void _jumpToInitialSectionIfNeeded() {
    if (_didJumpToInitialSection) return;
    final key = _sectionKeyFor(widget.initialSection);
    if (key == null) return;
    final context = key.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpToInitialSectionIfNeeded();
      });
      return;
    }

    _didJumpToInitialSection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  GlobalKey? _sectionKeyFor(String? section) {
    switch ((section ?? '').trim().toLowerCase()) {
      case 'access':
        return _accessSectionKey;
      case 'apps':
        return _appsSectionKey;
      case 'websites':
        return _sitesSectionKey;
      case 'pauses':
        return _pausesSectionKey;
      default:
        return null;
    }
  }

  Future<void> _handleAccessAction() async {
    if (_saving) return;
    if (_protectionStatus.isAuthorized) {
      await _showNotice(
        title: _t('screen_time_access_approved'),
        message: _isAndroid
            ? _t('screen_time_android_access_approved_message')
            : _t('screen_time_ios_access_approved_message'),
      );
      return;
    }
    if (_isAndroid) {
      final confirmed = await showAndroidProtectionDisclosure(
        context: context,
        nextStep: _focusService.getNextAndroidProtectionStep,
      );
      if (!confirmed) return;
    }
    if (_protectionStatus.shouldOpenSettings) {
      await _focusService.openSystemSettings();
    } else {
      await _focusService.requestPermissions();
    }
    await _load();
  }

  String _permissionStatusLabel(FocusPermissionState state) {
    switch (state) {
      case FocusPermissionState.approved:
        return _t('screen_time_enabled');
      case FocusPermissionState.denied:
      case FocusPermissionState.notDetermined:
      case FocusPermissionState.unknown:
        return _t('screen_time_allow');
      case FocusPermissionState.unsupported:
        return _t('screen_time_unavailable');
    }
  }

  String _permissionStatusSubtitle(FocusPermissionState state) {
    switch (state) {
      case FocusPermissionState.approved:
        return _t('screen_time_enabled_on_device');
      case FocusPermissionState.denied:
      case FocusPermissionState.notDetermined:
      case FocusPermissionState.unknown:
        return _t('screen_time_permission_required');
      case FocusPermissionState.unsupported:
        return _t('screen_time_unsupported_on_device');
    }
  }

  Future<void> _handleAccessibilityAccess() async {
    if (_saving) return;
    if (_accessibilityState == FocusPermissionState.approved) {
      await _showNotice(
        title: _t('screen_time_accessibility_enabled'),
        message: _t('screen_time_accessibility_enabled_message'),
      );
      return;
    }
    final confirmed = await showAndroidProtectionDisclosure(
      context: context,
      nextStep: () async => AndroidProtectionStep.accessibility,
    );
    if (!confirmed) return;
    await _focusService.openAccessibilitySettings();
    await _load();
  }

  Future<void> _handleUsageAccess() async {
    if (_saving) return;
    if (_usageAccessState == FocusPermissionState.approved) {
      await _showNotice(
        title: _t('screen_time_usage_access_enabled'),
        message: _t('screen_time_usage_access_enabled_message'),
      );
      return;
    }
    final confirmed = await showAndroidProtectionDisclosure(
      context: context,
      nextStep: () async => AndroidProtectionStep.usageAccess,
    );
    if (!confirmed) return;
    await _focusService.openUsageAccessSettings();
    await _load();
  }

  @override
  void dispose() {
    _siteCtrl.dispose();
    _appCtrl.dispose();
    super.dispose();
  }

  List<String> _filteredWebsiteSuggestions(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return _websiteSuggestions
        .where((domain) => domain.contains(needle))
        .toList(growable: false);
  }

  List<_IosAppSuggestion> _filteredAppSuggestions(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return _iosAppSuggestions.take(12).toList(growable: false);
    }
    final ranked = _iosAppSuggestions
        .where((item) {
          final label = item.label.toLowerCase();
          final bundle = item.bundleIdentifier.toLowerCase();
          if (label.contains(needle) || bundle.contains(needle)) return true;
          return item.keywords.any(
            (keyword) => keyword.toLowerCase().contains(needle),
          );
        })
        .toList(growable: false);
    ranked.sort((a, b) {
      final aStarts = a.label.toLowerCase().startsWith(needle) ? 0 : 1;
      final bStarts = b.label.toLowerCase().startsWith(needle) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.label.compareTo(b.label);
    });
    return ranked.take(20).toList(growable: false);
  }

  bool _canSubmitWebsiteInput() {
    final normalized = normalizeDomainInput(
      _siteCtrl.text,
      allowedSpecialValues: {FeatureRepository.adultContentShieldMarker},
    );
    if (normalized == null) return false;
    return true;
  }

  Widget _websiteSuggestionTile(String domain) {
    return GestureDetector(
      onTap: _saving
          ? null
          : () async {
              _siteCtrl.text = domain;
              await _addBlockedWebsite(overrideDomain: domain);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.pillBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.pillBorder, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.globe,
              size: 14,
              color: AppColors.secondaryLabel,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                domain,
                style: AppTypography.callout.copyWith(
                  fontSize: 14,
                  color: AppColors.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.add,
              size: 14,
              color: AppColors.secondaryLabel.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  String _colorToArgbHex(Color color) {
    int channel(double normalized) =>
        (normalized * 255.0).round().clamp(0, 255);
    String hex2(int value) => value.toRadixString(16).padLeft(2, '0');
    return '${hex2(channel(color.a))}${hex2(channel(color.r))}${hex2(channel(color.g))}${hex2(channel(color.b))}'
        .toUpperCase();
  }

  bool _isGenericAppName(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'unknown app' ||
        normalized == 'blocked app' ||
        normalized == 'selected app' ||
        normalized.startsWith('selected app ');
  }

  String _prettyBundleLabel(String bundleIdentifier) {
    final trimmed = bundleIdentifier.trim();
    if (trimmed.isEmpty) return '';
    final tail = trimmed.split('.').last.trim();
    if (tail.isEmpty) return trimmed;
    final withSpaces = tail.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return withSpaces.isEmpty ? trimmed : withSpaces;
  }

  String _displayNameForBlockedApp(BlockedApp app) {
    final explicit = app.appName?.trim();
    if (explicit != null &&
        explicit.isNotEmpty &&
        !_isGenericAppName(explicit)) {
      return explicit;
    }
    final bundle = _appBindings[app.id]?.nativeIdentifier?.trim();
    if (bundle != null && bundle.isNotEmpty) {
      return _prettyBundleLabel(bundle);
    }
    return explicit?.isNotEmpty == true
        ? explicit!
        : _t('screen_time_unknown_app');
  }

  String _resolvedAppLabel(IosFamilyActivitySelection selection) {
    final preferred = selection.preferredLabel?.trim();
    if (preferred != null &&
        preferred.isNotEmpty &&
        !_isGenericAppName(preferred)) {
      return preferred;
    }
    final bundle = selection.bundleIdentifier?.trim();
    if (bundle != null && bundle.isNotEmpty) {
      final pretty = _prettyBundleLabel(bundle);
      if (pretty.isNotEmpty) return pretty;
    }
    return _t('screen_time_blocked_app');
  }

  Future<ClassicBlockingSyncResult> _syncClassicNative({
    required List<BlockedApp> apps,
    required List<BlockedWebsite> websites,
    required List<RestPeriod> rests,
  }) {
    return _classicCoordinator.syncNativeState(
      apps: apps,
      websites: websites,
      restPeriods: rests,
    );
  }

  Future<void> _openAndroidBlockedAppsEditor() async {
    if (_saving || !_isAndroid) return;

    final currentByPackage = <String, BlockedApp>{};
    for (final app in _blockedApps) {
      final packageName = _appBindings[app.id]?.nativeIdentifier?.trim();
      if (packageName == null || packageName.isEmpty) continue;
      currentByPackage.putIfAbsent(packageName, () => app);
    }

    final result = await showCupertinoModalPopup<Map<String, dynamic>>(
      context: context,
      builder: (_) => AppSelectionSheet(
        allowCategories: false,
        returnSelectedApps: true,
        initialQuery: '',
        initialSelectedPackages: currentByPackage.keys.toList(growable: false),
      ),
    );
    final selectedApps =
        (result?['selected_apps'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];

    if (result == null) return;

    final desiredByPackage = <String, Map<String, dynamic>>{};
    for (final app in selectedApps) {
      final packageName = (app['packageName'] as String?)?.trim();
      if (packageName == null || packageName.isEmpty) continue;
      desiredByPackage[packageName] = app;
    }

    final currentPackages = currentByPackage.keys.toSet();
    final desiredPackages = desiredByPackage.keys.toSet();
    final toAdd = desiredPackages.difference(currentPackages).toList()..sort();
    final toRemove = currentPackages.difference(desiredPackages).toList()
      ..sort();

    if (toAdd.isEmpty && toRemove.isEmpty) return;

    var added = 0;
    var removed = 0;

    await _runMutation(() async {
      for (final packageName in toRemove) {
        final app = currentByPackage[packageName];
        if (app == null) continue;
        await _repo.deleteBlockedApp(app.id);
        await _classicLocalStore.removeAppBinding(app.id);
        removed++;
      }

      for (final packageName in toAdd) {
        final selected = desiredByPackage[packageName];
        if (selected == null) continue;
        final displayName =
            (selected['name'] as String?)?.trim().isNotEmpty == true
            ? (selected['name'] as String).trim()
            : packageName;
        final record = await _repo.createBlockedAppRecord(displayName);
        if (record == null) continue;
        await _classicLocalStore.saveAppBinding(
          rowId: record.id,
          nativeIdentifier: packageName,
        );
        added++;
      }
    });

    if (!mounted || (added == 0 && removed == 0)) return;

    final parts = <String>[
      if (added > 0)
        added == 1
            ? _t('screen_time_one_app_added')
            : "$added ${_t('screen_time_apps_added')}",
      if (removed > 0)
        removed == 1
            ? _t('screen_time_one_app_removed')
            : "$removed ${_t('screen_time_apps_removed')}",
    ];
    await _showNotice(
      title: _t('screen_time_blocked_apps_updated'),
      message: '${parts.join(' · ')}.',
    );
  }

  Future<void> _addBlockedApp() async {
    if (_saving) return;

    if (Platform.isAndroid) {
      await _openAndroidBlockedAppsEditor();
      return;
    }

    if (Platform.isIOS) {
      final authorized = await _focusService.isAuthorized();
      if (!authorized) {
        final granted = await _focusService.requestPermissions();
        if (!granted) {
          await _showNotice(
            title: _t('screen_time_permissions_required'),
            message: _t('screen_time_permissions_required_apps_message'),
          );
          return;
        }
      }
      final selection = await _focusService.openFamilyActivityPicker();
      final payload = _firstNonEmpty(selection);
      if (payload == null) {
        await _showNotice(
          title: 'Selection canceled',
          message:
              'Select at least one app in the Apple picker, then tap Done to save your block.',
        );
        return;
      }

      final described = await _focusService.describeAppSelectionPayload(
        payload,
      );
      final label = described == null
          ? _nextAppSelectionLabel()
          : _resolvedAppLabel(described);
      await _runMutation(() async {
        final record = await _repo.createBlockedAppRecord(label);
        if (record == null) return;
        await _classicLocalStore.saveAppBinding(
          rowId: record.id,
          nativeIdentifier: described?.bundleIdentifier,
          nativePayload: payload,
        );
      });
      return;
    }

    return;
  }

  Future<void> _addBlockedWebsite({String? overrideDomain}) async {
    if (_saving) return;
    final value = (overrideDomain ?? _siteCtrl.text).trim();
    if (value.isEmpty) return;

    if (Platform.isIOS) {
      final authorized = await _focusService.isAuthorized();
      if (!authorized) {
        final granted = await _focusService.requestPermissions();
        if (!granted) {
          await _showNotice(
            title: 'Permissions required',
            message:
                'Allow Screen Time / Family Controls first so selected websites can be blocked during your focus sessions on this device.',
          );
          return;
        }
      }
      final selection = await _focusService.openFamilyActivityPicker();
      final payload = _firstNonEmpty(selection);
      if (payload == null) {
        await _showNotice(
          title: 'Selection canceled',
          message:
              'Select at least one app or website, then tap Done to save your block.',
        );
        return;
      }

      await _runMutation(() async {
        final record = await _repo.createBlockedWebsiteRecord(value);
        if (record == null) return;
        await _classicLocalStore.saveWebsiteBinding(
          rowId: record.id,
          nativePayload: payload,
        );
      });
    } else {
      await _runMutation(() => _repo.createBlockedWebsite(value));
    }

    _siteCtrl.clear();
    if (mounted) {
      setState(() => _showAddWebsite = false);
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final appsFuture = _repo.getBlockedApps();
      final websitesFuture = _repo.getBlockedWebsites();
      final restFuture = _repo.getRestPeriods();
      final protectionFuture = _focusService.getProtectionStatus();
      final accessibilityFuture = _isAndroid
          ? _focusService.getAccessibilityPermissionState()
          : Future.value(FocusPermissionState.unknown);
      final usageAccessFuture = _isAndroid
          ? _focusService.getUsageAccessPermissionState()
          : Future.value(FocusPermissionState.unknown);
      final appBindingsFuture = _classicLocalStore.loadAppBindings();
      final websiteBindingsFuture = _classicLocalStore.loadWebsiteBindings();
      final logsFuture = _repo.getScreenTimeLogs(days: 14);

      final apps = await appsFuture;
      final websites = await websitesFuture;
      final rests = await restFuture;
      final protectionStatus = await protectionFuture;
      final accessibilityState = await accessibilityFuture;
      final usageAccessState = await usageAccessFuture;
      final appBindings = await appBindingsFuture;
      final websiteBindings = await websiteBindingsFuture;
      final logs = await logsFuture;
      final upgradedApps = await _upgradeIosBlockedAppNames(
        apps: apps,
        appBindings: appBindings,
      );
      final upgradedWebsites = await _upgradeIosBlockedWebsiteDomains(
        websites: websites,
        websiteBindings: websiteBindings,
      );
      var effectiveApps = upgradedApps ?? apps;
      var effectiveWebsites = upgradedWebsites ?? websites;
      final filteredWebsites = effectiveWebsites
          .where(
            (site) =>
                (site.urlDomain ?? '').trim() !=
                FeatureRepository.adultContentShieldMarker,
          )
          .toList(growable: false);
      final syncResult = await _syncClassicNative(
        apps: effectiveApps,
        websites: filteredWebsites,
        rests: rests,
      );
      if (!syncResult.syncApplied) {
        throw StateError(
          syncResult.failureReason ??
              'Classic native sync failed while loading Screen Time.',
        );
      }
      final refreshedAppBindings = await _classicLocalStore.loadAppBindings();
      final refreshedWebsiteBindings = await _classicLocalStore
          .loadWebsiteBindings();
      final postSyncUpgradedApps = await _upgradeIosBlockedAppNames(
        apps: effectiveApps,
        appBindings: refreshedAppBindings,
      );
      if (postSyncUpgradedApps != null) {
        effectiveApps = postSyncUpgradedApps;
      }
      final postSyncUpgradedWebsites = await _upgradeIosBlockedWebsiteDomains(
        websites: filteredWebsites,
        websiteBindings: refreshedWebsiteBindings,
      );
      if (postSyncUpgradedWebsites != null) {
        effectiveWebsites = postSyncUpgradedWebsites;
      }
      final effectiveFilteredWebsites = effectiveWebsites
          .where(
            (site) =>
                (site.urlDomain ?? '').trim() !=
                FeatureRepository.adultContentShieldMarker,
          )
          .toList(growable: false);
      final effectiveAdultEnabled = effectiveWebsites.any(
        (site) =>
            (site.urlDomain ?? '').trim() ==
            FeatureRepository.adultContentShieldMarker,
      );
      final validAppIds = effectiveApps.map((item) => item.id).toSet();

      if (!mounted) return;
      setState(() {
        _blockedApps = effectiveApps;
        _blockedWebsites = effectiveFilteredWebsites;
        _restPeriods = rests;
        _logs = logs;
        _appBindings = Map<String, ClassicBlockBinding>.fromEntries(
          refreshedAppBindings.entries.where(
            (entry) => validAppIds.contains(entry.key),
          ),
        );
        _websiteBindings = Map<String, ClassicBlockBinding>.fromEntries(
          refreshedWebsiteBindings.entries.where(
            (entry) =>
                effectiveFilteredWebsites.any((site) => site.id == entry.key),
          ),
        );
        _adultContentShieldEnabled = effectiveAdultEnabled;
        _protectionStatus = protectionStatus;
        _accessibilityState = accessibilityState;
        _usageAccessState = usageAccessState;
        _loading = false;
      });
      _jumpToInitialSectionIfNeeded();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _showNotice(
        title: _t('screen_time_sync_failed'),
        message: _isAndroid
            ? _t('screen_time_sync_failed_android_message')
            : _t('screen_time_sync_failed_ios_message'),
      );
    }
  }

  Future<List<BlockedApp>?> _upgradeIosBlockedAppNames({
    required List<BlockedApp> apps,
    required Map<String, ClassicBlockBinding> appBindings,
  }) async {
    if (!Platform.isIOS || apps.isEmpty) return null;

    var changed = false;
    for (final app in apps) {
      if (!_isGenericAppName(app.appName)) continue;
      final binding = appBindings[app.id];
      final payload = binding?.nativePayload?.trim();
      if (payload == null || payload.isEmpty) continue;

      final described = await _focusService.describeAppSelectionPayload(
        payload,
      );
      final resolvedName = described?.preferredLabel?.trim();
      final bindingBundle = binding?.nativeIdentifier?.trim();
      final bundleFallback = (bindingBundle != null && bindingBundle.isNotEmpty)
          ? _prettyBundleLabel(bindingBundle)
          : null;
      final effectiveName = (resolvedName != null && resolvedName.isNotEmpty)
          ? resolvedName
          : bundleFallback;
      if (effectiveName == null || effectiveName.isEmpty) continue;
      if (effectiveName == app.appName?.trim()) continue;

      await _repo.updateBlockedAppName(app.id, effectiveName);
      changed = true;
    }

    if (!changed) return null;
    return _repo.getBlockedApps();
  }

  Future<List<BlockedWebsite>?> _upgradeIosBlockedWebsiteDomains({
    required List<BlockedWebsite> websites,
    required Map<String, ClassicBlockBinding> websiteBindings,
  }) async {
    if (!Platform.isIOS || websites.isEmpty) return null;

    var changed = false;
    for (final website in websites) {
      final currentDomain = website.urlDomain?.trim();
      if (currentDomain != null && currentDomain.isNotEmpty) continue;
      final payload = websiteBindings[website.id]?.nativePayload?.trim();
      if (payload == null || payload.isEmpty) continue;
      final described = await _focusService.describeWebsiteSelectionPayload(
        payload,
      );
      final resolved = described?.domain?.trim();
      if (resolved == null || resolved.isEmpty) continue;
      final normalized = normalizeDomainInput(resolved) ?? resolved;
      if (normalized.trim().isEmpty) continue;
      await _repo.updateBlockedWebsiteDomain(website.id, normalized);
      changed = true;
    }

    if (!changed) return null;
    return _repo.getBlockedWebsites();
  }

  Future<Map<String, String>> _refreshIosAppCatalog() async {
    if (!Platform.isIOS) return const {};
    final map = <String, String>{};
    for (final suggestion in _iosAppSuggestions) {
      final encoded = await _focusService.encodeApplicationBundleSelection(
        suggestion.bundleIdentifier,
      );
      final payload = encoded?.trim();
      if (payload == null || payload.isEmpty) continue;
      map[suggestion.bundleIdentifier] = payload;
    }
    return map;
  }

  Future<Map<String, String>> _refreshIosWebsiteCatalog() async {
    if (!Platform.isIOS) return const {};
    final map = <String, String>{};
    for (final domain in _websiteSuggestions) {
      final encoded = await _focusService.encodeWebsiteDomainSelection(domain);
      final payload = encoded?.trim();
      if (payload == null || payload.isEmpty) continue;
      map[domain] = payload;
    }
    return map;
  }

  Future<void> _showLocalLimitInfo({
    required String title,
    required int limitMinutes,
  }) {
    return _showNotice(
      title: title,
      message: _isAndroid
          ? 'Daily limit: ${limitMinutes}m\nUsage data for Android daily limits stays on this device and is not used for ads or unrelated analytics.'
          : 'Daily limit: ${limitMinutes}m\nUsage for Screen Time protections stays on this device and is not synced, exported, or shared.',
    );
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      await _load();
    } catch (_) {
      if (!mounted) return;
      _showNotice(
        title: _t('screen_time_action_failed'),
        message: _t('please_try_again'),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showNotice({required String title, required String message}) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('ok')),
          ),
        ],
      ),
    );
  }

  String? _firstNonEmpty(List<String>? values) {
    if (values == null) return null;
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String _nextAppSelectionLabel() {
    return '${_t('screen_time_blocked_app')} ${_blockedApps.length + 1}';
  }

  String _durationLabel(int minutes) {
    if (minutes <= 0) return _t('screen_time_always_blocked');
    if (minutes < 60) return '${minutes}m/day';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h/day' : '${hours}h ${rest}m/day';
  }

  Future<void> _startRestPeriod(int minutes) {
    final now = DateTime.now();
    return _runMutation(
      () => _repo.createRestPeriod(
        startTime: now,
        endTime: now.add(Duration(minutes: minutes)),
        active: true,
      ),
    );
  }

  Future<void> _activateScheduledRest(RestPeriod period) {
    final end = period.endTime;
    return _runMutation(
      () => _repo.updateRestPeriod(
        id: period.id,
        startTime: DateTime.now(),
        endTime: end,
        active: true,
      ),
    );
  }

  Widget _pressScale({
    required Widget child,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: onPressed == null ? 0.45 : 1,
        child: child,
      ),
    );
  }

  Widget _glowSurface({
    required Widget child,
    required Color glowColor,
    required double borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: AppColors.tertiaryLabel,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.title3.copyWith(
              fontSize: 22,
              color: AppColors.label,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _moduleDecoration({
    double radius = 18,
    Color? borderColor,
    Color? overlay,
  }) {
    return BoxDecoration(
      color: overlay ?? AppColors.cardBase,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppColors.glassBorder),
    );
  }

  Widget _secondaryAction({
    required String label,
    required VoidCallback? onTap,
  }) {
    return _pressScale(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.cardRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.44)),
        ),
        child: Text(
          label,
          style: AppTypography.footnote.copyWith(
            fontSize: 12,
            color: AppColors.label,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _deleteChip({required VoidCallback? onTap}) {
    return _pressScale(
      onPressed: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
        ),
        alignment: Alignment.center,
        child: Icon(CupertinoIcons.delete, size: 16, color: AppColors.error),
      ),
    );
  }

  RestPeriod? _activeRestPeriod() {
    final now = DateTime.now();
    for (final period in _restPeriods) {
      if (_isRestActive(period, now)) {
        return period;
      }
    }
    return null;
  }

  List<RestPeriod> _scheduledRestPeriods() {
    final now = DateTime.now();
    return _restPeriods
        .where((period) => _isScheduledRest(period, now))
        .toList();
  }

  bool _isRestActive(RestPeriod period, DateTime now) {
    final start = period.startTime;
    final end = period.endTime;
    if (end != null && !end.isAfter(now)) return false;
    if (start != null) {
      return !start.isAfter(now);
    }
    return period.active;
  }

  bool _isScheduledRest(RestPeriod period, DateTime now) {
    final start = period.startTime;
    final end = period.endTime;
    if (start == null || end == null) return false;
    if (!end.isAfter(start)) return false;
    return start.isAfter(now);
  }

  bool _isCompletedRest(RestPeriod period, DateTime now) {
    final end = period.endTime;
    if (end == null) return false;
    return !end.isAfter(now);
  }

  String _restLabel(RestPeriod period) {
    final start = period.startTime;
    final end = period.endTime;
    if (start == null || end == null) return _t('screen_time_unknown_period');
    return "${DateFormat('MMM d, HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}";
  }

  String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  int _usedMinutesForEntity({
    required String entityName,
    required bool isWebsite,
  }) {
    final normalized = entityName.trim().toLowerCase();
    if (normalized.isEmpty) return 0;
    final today = _todayKey();
    var seconds = 0;
    for (final log in _logs) {
      final date = (log['date'] ?? '').toString().split('T').first;
      if (date != today) continue;

      final type = (log['entity_type'] ?? '').toString().toLowerCase().trim();
      final name = (log['entity_name'] ?? '').toString().toLowerCase().trim();
      final matchesType = isWebsite
          ? (type.contains('web') || type.contains('site') || type.isEmpty)
          : (type.contains('app') ||
                type.contains('application') ||
                type.isEmpty);
      if (!matchesType) continue;

      final matchesName = isWebsite
          ? name.contains(normalized)
          : (name == normalized || name.contains(normalized));
      if (!matchesName) continue;
      seconds += (log['duration_seconds'] as num?)?.toInt() ?? 0;
    }
    return seconds ~/ 60;
  }

  int _remainingMinutes({required int limitMinutes, required int usedMinutes}) {
    final remaining = limitMinutes - usedMinutes;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> _showRemainingDialog({
    required String title,
    required int limitMinutes,
    required int usedMinutes,
  }) {
    final remaining = _remainingMinutes(
      limitMinutes: limitMinutes,
      usedMinutes: usedMinutes,
    );
    return _showNotice(
      title: title,
      message:
          'Daily limit: ${limitMinutes}m\nUsed today: ${usedMinutes}m\nRemaining today: ${remaining}m',
    );
  }

  Future<void> _editDailyLimit({
    required String title,
    required int currentMinutes,
    required Future<void> Function(int minutes) onSave,
  }) async {
    final ctrl = TextEditingController(
      text: currentMinutes > 0 ? '$currentMinutes' : '',
    );

    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text("${_t('screen_time_daily_limit_prefix')} - $title"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            placeholder: _t('screen_time_minutes_per_day_placeholder'),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('cancel')),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, 'clear'),
            child: Text(_t('screen_time_clear_limit')),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: Text(_t('save')),
          ),
        ],
      ),
    );

    if (!mounted || result == null) {
      ctrl.dispose();
      return;
    }

    if (result == 'clear') {
      await _runMutation(() => onSave(0));
      ctrl.dispose();
      return;
    }

    final parsed = int.tryParse(ctrl.text.trim());
    ctrl.dispose();
    if (parsed == null || parsed < 0) {
      await _showNotice(
        title: _t('screen_time_invalid_value'),
        message: _t('screen_time_invalid_minutes_message'),
      );
      return;
    }
    await _runMutation(() => onSave(parsed));
  }

  Future<void> _scheduleRestPeriod({
    required int startsInMinutes,
    required int durationMinutes,
  }) {
    if (startsInMinutes < 120) {
      return _showNotice(
        title: _t('screen_time_planning_required'),
        message: _t('screen_time_planning_required_message'),
      );
    }
    final now = DateTime.now();
    final start = now.add(Duration(minutes: startsInMinutes));
    final end = start.add(Duration(minutes: durationMinutes));
    return _runMutation(() {
      return _repo.createRestPeriod(
        startTime: start,
        endTime: end,
        active: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>().languageCode;
    final activeRest = _activeRestPeriod();
    final scheduledRests = _scheduledRestPeriods();
    final now = DateTime.now();
    final completedRests = _restPeriods
        .where((period) => _isCompletedRest(period, now))
        .toList();

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/screen-time-manager'),
          child: Icon(CupertinoIcons.back, color: AppColors.primaryOrange),
        ),
        middle: Text(
          _isAndroid ? _t('focus_protection') : _t('screen_time_control_title'),
          style: AppTypography.title3.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.label,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _load,
          child: Icon(
            CupertinoIcons.refresh,
            color: _saving ? AppColors.tertiaryLabel : AppColors.primaryOrange,
            size: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: AmbientBackdrop(
        child: _loading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: AppColors.primaryOrange,
                ),
              )
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  children: [
                    _glowSurface(
                      glowColor: AppColors.primaryOrange.withValues(
                        alpha: 0.14,
                      ),
                      borderRadius: 16,
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 16,
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.22,
                          ),
                          width: 0.7,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.hand_raised_fill,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Block apps, websites, and control temporary rest periods.',
                                style: AppTypography.mono.copyWith(
                                  fontSize: 10,
                                  color: AppColors.secondaryLabel,
                                ),
                              ),
                            ),
                            if (_saving)
                              CupertinoActivityIndicator(
                                radius: 8,
                                color: AppColors.primaryOrange,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      borderRadius: 16,
                      child: Row(
                        children: [
                          _metric('LOGS', '${_logs.length}'),
                          _metric('HOURS', totalHours),
                          _metric(
                            'BLOCKED',
                            '${_blockedApps.length + _blockedWebsites.length}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sectionHeader(
                      title: 'BLOCKED_APPS',
                      subtitle: '${_blockedApps.length} configured',
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 24),
                        onPressed: () {
                          setState(() => _showAddApp = !_showAddApp);
                        },
                        child: Icon(
                          _showAddApp
                              ? CupertinoIcons.minus_circle
                              : CupertinoIcons.add_circled,
                          size: 18,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                    if (_showAddApp) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 14,
                        child: Column(
                          children: [
                            CupertinoTextField(
                              controller: _appCtrl,
                              placeholder: 'App name (Instagram, TikTok, ...)',
                              style: AppTypography.mono.copyWith(fontSize: 11),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.glassBorder,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: LiquidButton(
                                label: 'ADD_APP',
                                onPressed: _saving
                                    ? null
                                    : () {
                                        _addBlockedApp();
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_blockedApps.isNotEmpty)
                      ..._blockedApps.map(
                        (app) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _blockedItemCard(
                            title: (app.appName ?? 'Unknown app').toUpperCase(),
                            subtitle: _durationLabel(app.timeLimitMinutes ?? 0),
                            onAdd15: _saving
                                ? null
                                : () => _runMutation(
                                    () => _repo.addBlockedAppTime(app.id, 15),
                                  ),
                            onAdd30: _saving
                                ? null
                                : () => _runMutation(
                                    () => _repo.addBlockedAppTime(app.id, 30),
                                  ),
                            onDelete: _saving
                                ? null
                                : () => _runMutation(() async {
                                    await _repo.deleteBlockedApp(app.id);
                                    await _classicLocalStore.removeAppBinding(
                                      app.id,
                                    );
                                  }),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _sectionHeader(
                      title: 'BLOCKED_WEBSITES',
                      subtitle: '${_blockedWebsites.length} configured',
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 24),
                        onPressed: () {
                          setState(() => _showAddWebsite = !_showAddWebsite);
                        },
                        child: Icon(
                          _showAddWebsite
                              ? CupertinoIcons.minus_circle
                              : CupertinoIcons.add_circled,
                          size: 18,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                    if (_showAddWebsite) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 14,
                        child: Column(
                          children: [
                            CupertinoTextField(
                              controller: _siteCtrl,
                              placeholder: 'Domain (x.com, youtube.com, ...)',
                              style: AppTypography.mono.copyWith(fontSize: 11),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.glassBorder,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: LiquidButton(
                                label: 'ADD_WEBSITE',
                                onPressed: _saving
                                    ? null
                                    : () {
                                        final domain = _siteCtrl.text.trim();
                                        if (domain.isEmpty) return;
                                        _runMutation(() {
                                          return _repo.createBlockedWebsite(
                                            domain,
                                          );
                                        });
                                        _siteCtrl.clear();
                                        setState(() => _showAddWebsite = false);
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_blockedWebsites.isNotEmpty)
                      ..._blockedWebsites.map(
                        (site) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _blockedItemCard(
                            title: (site.urlDomain ?? 'Unknown website')
                                .toUpperCase(),
                            subtitle: _durationLabel(
                              site.timeLimitMinutes ?? 0,
                            ),
                            onAdd15: _saving
                                ? null
                                : () => _runMutation(
                                    () => _repo.addBlockedWebsiteTime(
                                      site.id,
                                      15,
                                    ),
                                  ),
                            onAdd30: _saving
                                ? null
                                : () => _runMutation(
                                    () => _repo.addBlockedWebsiteTime(
                                      site.id,
                                      30,
                                    ),
                                  ),
                            onDelete: _saving
                                ? null
                                : () => _runMutation(() async {
                                    await _repo.deleteBlockedWebsite(site.id);
                                    await _classicLocalStore
                                        .removeWebsiteBinding(site.id);
                                  }),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _sectionHeader(
                      title: 'REST_PERIODS',
                      subtitle: activeRest == null
                          ? 'No active rest period'
                          : "Active until ${DateFormat('HH:mm').format(activeRest.endTime ?? DateTime.now())}",
                      trailing: null,
                    ),
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 14,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _quickPill(
                                  label: '15m',
                                  onTap: _saving
                                      ? null
                                      : () => _startRestPeriod(15),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _quickPill(
                                  label: '30m',
                                  onTap: _saving
                                      ? null
                                      : () => _startRestPeriod(30),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _quickPill(
                                  label: '60m',
                                  onTap: _saving
                                      ? null
                                      : () => _startRestPeriod(60),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _quickPill(
                                  label: 'IN 30m',
                                  onTap: _saving
                                      ? null
                                      : () => _scheduleRestPeriod(
                                          startsInMinutes: 30,
                                          durationMinutes: 30,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _quickPill(
                                  label: 'IN 60m',
                                  onTap: _saving
                                      ? null
                                      : () => _scheduleRestPeriod(
                                          startsInMinutes: 60,
                                          durationMinutes: 30,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _quickPill(
                                  label: 'IN 120m',
                                  onTap: _saving
                                      ? null
                                      : () => _scheduleRestPeriod(
                                          startsInMinutes: 120,
                                          durationMinutes: 30,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          if (activeRest != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                color: AppColors.error.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                onPressed: _saving
                                    ? null
                                    : () => _runMutation(
                                        () => _repo.updateRestPeriod(
                                          id: activeRest.id,
                                          endTime: DateTime.now(),
                                          active: false,
                                        ),
                                      ),
                                child: Text(
                                  'END_ACTIVE_REST',
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 10,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (scheduledRests.isNotEmpty) ...[
                      ...scheduledRests
                          .take(4)
                          .map(
                            (period) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                borderRadius: 12,
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.24,
                                  ),
                                  width: 0.5,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'SCHEDULED ${_restLabel(period)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.mono.copyWith(
                                          fontSize: 10,
                                          color: AppColors.secondaryLabel,
                                        ),
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(24, 24),
                                      onPressed: _saving
                                          ? null
                                          : () =>
                                                _activateScheduledRest(period),
                                      child: Text(
                                        'START',
                                        style: AppTypography.mono.copyWith(
                                          fontSize: 9,
                                          color: AppColors.primaryOrange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(24, 24),
                                      onPressed: _saving
                                          ? null
                                          : () => _runMutation(
                                              () =>
                                                  _repo.updateRestPeriodActive(
                                                    period.id,
                                                    false,
                                                  ),
                                            ),
                                      child: Icon(
                                        CupertinoIcons.clear_circled,
                                        size: 15,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                    if (_restPeriods.isEmpty)
                      _emptyCard('No rest periods yet.')
                    else
                      ..._restPeriods
                          .take(10)
                          .map(
                            (period) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                borderRadius: 12,
                                border: Border.all(
                                  color: period.active
                                      ? AppColors.success.withValues(
                                          alpha: 0.24,
                                        )
                                      : AppColors.glassBorder,
                                  width: 0.5,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _restLabel(period),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.mono.copyWith(
                                          fontSize: 10,
                                          color: AppColors.secondaryLabel,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      period.active ? 'ACTIVE' : 'ENDED',
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 9,
                                        color: period.active
                                            ? AppColors.success
                                            : AppColors.tertiaryLabel,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 14),
                    _sectionHeader(
                      title: 'USAGE_LOGS',
                      subtitle: 'Last 14 days raw usage',
                      trailing: null,
                    ),
                    if (_logs.isEmpty)
                      _emptyCard('No screen-time logs yet.')
                    else
                      ..._logs
                          .take(30)
                          .map(
                            (log) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                borderRadius: 12,
                                border: Border.all(
                                  color: AppColors.glassBorder,
                                  width: 0.5,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (log['entity_name']?.toString() ??
                                                'Unknown')
                                            .toUpperCase(),
                                        style: AppTypography.mono.copyWith(
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      "${((log['duration_seconds'] as num?)?.toInt() ?? 0) ~/ 60}m",
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 11,
                                        color: AppColors.primaryOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionHeader({
    Key? key,
    required String title,
    required String subtitle,
    required Widget? trailing,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.title3.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.label,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.footnote.copyWith(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.secondaryLabel.withValues(alpha: 0.76),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _blockedItemCard({
    required String title,
    required String subtitle,
    required VoidCallback? onAdd15,
    required VoidCallback? onAdd30,
    required VoidCallback? onDelete,
    VoidCallback? onSetLimit,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 14,
      border: Border.all(color: AppColors.glassBorder, width: 0.5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.label,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption1.copyWith(
                    fontSize: 12,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onSetLimit != null) ...[
            _tinyAction(label: 'LIMIT', onTap: onSetLimit),
            const SizedBox(width: 6),
          ],
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(26, 26),
            onPressed: onDelete,
            child: Icon(
              CupertinoIcons.delete,
              size: 16,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionAccessCard({
    required IconData icon,
    required String title,
    required FocusPermissionState state,
    required String description,
    required VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _moduleDecoration(radius: 18),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.overline.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _permissionStatusSubtitle(state),
                  style: AppTypography.callout.copyWith(
                    fontSize: 14,
                    color: AppColors.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.footnote.copyWith(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _tinyAction(label: _permissionStatusLabel(state), onTap: onTap),
        ],
      ),
    );
  }

  Widget _tinyAction({required String label, required VoidCallback? onTap}) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: const Size(26, 26),
      color: AppColors.backgroundLight.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(8),
      onPressed: onTap,
      child: Text(
        label,
        style: AppTypography.mono.copyWith(
          fontSize: 9,
          color: AppColors.primaryOrange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _quickPill({required String label, required VoidCallback? onTap}) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.backgroundLight.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(10),
      onPressed: onTap,
      child: Text(
        label,
        style: AppTypography.mono.copyWith(
          fontSize: 10,
          color: AppColors.primaryOrange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 12,
      child: Text(
        text,
        style: AppTypography.mono.copyWith(
          fontSize: 10,
          color: AppColors.tertiaryLabel,
        ),
      ),
    );
  }
}

// Recovered class _IosAppSuggestion @ 2026-04-15T15:08:58.030Z
class _IosAppSuggestion {
  final String label;
  final String bundleIdentifier;
  final List<String> keywords;

  const _IosAppSuggestion({
    required this.label,
    required this.bundleIdentifier,
    this.keywords = const [],
  });
}
