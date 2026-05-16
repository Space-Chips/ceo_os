import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/services/focus_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../components/components.dart';

class _SelectableApp {
  final String name;
  final String packageName;
  final Uint8List? icon;

  const _SelectableApp({
    required this.name,
    required this.packageName,
    this.icon,
  });
}

class AppSelectionSheet extends StatefulWidget {
  final List<String> initialSelectedPackages;
  final List<String> initialSelectedCategories;
  final bool allowCategories;
  final bool returnSelectedApps;
  final String initialQuery;

  const AppSelectionSheet({
    super.key,
    this.initialSelectedPackages = const [],
    this.initialSelectedCategories = const [],
    this.allowCategories = true,
    this.returnSelectedApps = false,
    this.initialQuery = '',
  });

  @override
  State<AppSelectionSheet> createState() => _AppSelectionSheetState();
}

class _AppSelectionSheetState extends State<AppSelectionSheet> {
  final List<_SelectableApp> _allApps = [];
  final List<_SelectableApp> _filteredApps = [];
  final Set<String> _selectedPackages = {};
  final Set<String> _selectedCategories = {};
  final FocusService _focusService = FocusService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;

  final Map<String, String> _categories = const {
    'social': 'Social',
    'game': 'Games',
    'entertainment': 'Entertainment',
    'productivity': 'Productivity',
  };

  @override
  void initState() {
    super.initState();
    _selectedPackages.addAll(widget.initialSelectedPackages);
    _selectedCategories.addAll(widget.initialSelectedCategories);
    _searchCtrl.text = widget.initialQuery.trim();
    _loadApps();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    var loadedApps = const <_SelectableApp>[];
    if (Platform.isAndroid) {
      try {
        loadedApps = (await _focusService.listAndroidLaunchableApps())
            .map(
              (app) => _SelectableApp(
                name: app.name,
                packageName: app.packageName,
                icon: app.iconBytes,
              ),
            )
            .toList(growable: false);
      } catch (error) {
        AppLogger.error('Error loading apps.', error);
      }
    }

    if (!mounted) return;
    _allApps
      ..clear()
      ..addAll(loadedApps);
    _applyFilter(_searchCtrl.text, shouldRebuild: false);
    setState(() => _isLoading = false);
  }

  String _normalize(String value) => value.trim().toLowerCase();

  int _matchRank(_SelectableApp app, String query) {
    if (query.isEmpty) return 0;
    final name = _normalize(app.name);
    final packageName = _normalize(app.packageName);
    if (name == query) return 0;
    if (name.startsWith(query)) return 1;
    if (packageName == query) return 2;
    if (packageName.startsWith(query)) return 3;
    if (name.contains(' $query')) return 4;
    if (packageName.contains(query)) return 5;
    return 6;
  }

  bool _matches(_SelectableApp app, String query) {
    if (query.isEmpty) return true;
    final normalized = _normalize(query);
    return _normalize(app.name).contains(normalized) ||
        _normalize(app.packageName).contains(normalized);
  }

  void _applyFilter(String rawQuery, {bool shouldRebuild = true}) {
    final query = _normalize(rawQuery);
    final matches = _allApps.where((app) => _matches(app, query)).toList()
      ..sort((left, right) {
        final rank = _matchRank(left, query).compareTo(
          _matchRank(right, query),
        );
        if (rank != 0) return rank;
        return _normalize(left.name).compareTo(_normalize(right.name));
      });

    _filteredApps
      ..clear()
      ..addAll(matches);

    if (shouldRebuild && mounted) {
      setState(() {});
    }
  }

  void _togglePackage(String packageName) {
    setState(() {
      if (_selectedPackages.contains(packageName)) {
        _selectedPackages.remove(packageName);
      } else {
        _selectedPackages.add(packageName);
      }
    });
  }

  void _toggleCategory(String categoryKey) {
    setState(() {
      if (_selectedCategories.contains(categoryKey)) {
        _selectedCategories.remove(categoryKey);
      } else {
        _selectedCategories.add(categoryKey);
      }
    });
  }

  String _selectionSummary() {
    final appCount = _selectedPackages.length;
    final categoryCount = _selectedCategories.length;
    if (appCount == 0 && categoryCount == 0) return 'No selection';
    if (categoryCount == 0) {
      return appCount == 1 ? '1 app selected' : '$appCount apps selected';
    }
    if (appCount == 0) {
      return categoryCount == 1
          ? '1 category selected'
          : '$categoryCount categories selected';
    }
    return '$appCount apps · $categoryCount categories';
  }

  void _saveSelection() {
    final selectedApps = _allApps
        .where((app) => _selectedPackages.contains(app.packageName))
        .map(
          (app) => {
            'name': app.name,
            'packageName': app.packageName,
          },
        )
        .toList(growable: false);

    Navigator.pop(context, {
      'packages': _selectedPackages.toList(),
      'categories': _selectedCategories.toList(),
      if (widget.returnSelectedApps) 'selected_apps': selectedApps,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DefaultTextStyle.merge(
        style: TextStyle(
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: AppColors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow.withValues(alpha: 0.38),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.glassBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.allowCategories
                                      ? 'Choose distractions'
                                      : 'Choose apps to block',
                                  style: AppTypography.title3.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.label,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Search installed apps and update the blocked list in one place.',
                                  style: AppTypography.footnote.copyWith(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: AppColors.secondaryLabel.withValues(
                                      alpha: 0.82,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(
                              _selectionSummary(),
                              style: AppTypography.caption1.copyWith(
                                fontSize: 11,
                                color: AppColors.secondaryLabel,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      CupertinoSearchTextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: _applyFilter,
                        backgroundColor: AppColors.cardRaised.withValues(
                          alpha: 0.78,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        style: AppTypography.body.copyWith(
                          fontSize: 15,
                          color: AppColors.label,
                        ),
                        placeholder: 'Search apps',
                        placeholderStyle: AppTypography.body.copyWith(
                          fontSize: 15,
                          color: AppColors.tertiaryLabel,
                        ),
                        prefixInsets: const EdgeInsetsDirectional.only(
                          start: 14,
                        ),
                        suffixInsets: const EdgeInsetsDirectional.only(end: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.allowCategories) ...[
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      children: _categories.entries.map((entry) {
                        final isSelected = _selectedCategories.contains(
                          entry.key,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _toggleCategory(entry.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryOrange.withValues(
                                        alpha: 0.18,
                                      )
                                    : AppColors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryOrange.withValues(
                                          alpha: 0.65,
                                        )
                                      : AppColors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Text(
                                entry.value,
                                style: AppTypography.footnote.copyWith(
                                  fontSize: 12,
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : AppColors.secondaryLabel,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Expanded(
                  child: _buildContent(),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.96),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: AppColors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: AppTypography.callout.copyWith(
                              color: AppColors.secondaryLabel,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LiquidButton(
                          label: 'Save selection',
                          onPressed: _saveSelection,
                          fullWidth: true,
                          height: 52,
                          labelStyle: AppTypography.callout.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_filteredApps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  CupertinoIcons.search,
                  color: AppColors.secondaryLabel,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No apps found',
                style: AppTypography.title3.copyWith(
                  fontSize: 20,
                  color: AppColors.label,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different app name or search by package name.',
                textAlign: TextAlign.center,
                style: AppTypography.footnote.copyWith(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.secondaryLabel.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoScrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        itemCount: _filteredApps.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final app = _filteredApps[index];
          final isSelected = _selectedPackages.contains(app.packageName);
          return GestureDetector(
            onTap: () => _togglePackage(app.packageName),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryOrange.withValues(alpha: 0.1)
                    : AppColors.cardBase,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryOrange.withValues(alpha: 0.65)
                      : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.glassShadow.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  _AppIconBadge(iconBytes: app.icon, appName: app.name),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline.copyWith(
                            fontSize: 15,
                            color: AppColors.label,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.footnote.copyWith(
                            fontSize: 12,
                            color: AppColors.secondaryLabel.withValues(
                              alpha: 0.76,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryOrange
                          : AppColors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryOrange
                            : AppColors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      isSelected
                          ? CupertinoIcons.checkmark
                          : CupertinoIcons.add,
                      size: 15,
                      color: isSelected
                          ? AppColors.onAccent
                          : AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AppIconBadge extends StatelessWidget {
  final Uint8List? iconBytes;
  final String appName;

  const _AppIconBadge({required this.iconBytes, required this.appName});

  @override
  Widget build(BuildContext context) {
    final initial = appName.trim().isEmpty
        ? '?'
        : appName.trim().characters.first.toUpperCase();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: iconBytes != null
          ? Image.memory(iconBytes!, width: 48, height: 48, fit: BoxFit.cover)
          : Text(
              initial,
              style: AppTypography.headline.copyWith(
                color: AppColors.label,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
