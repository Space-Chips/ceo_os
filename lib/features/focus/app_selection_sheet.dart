import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/components.dart';

class AppSelectionSheet extends StatefulWidget {
  final List<String> initialSelectedPackages;
  final List<String> initialSelectedCategories;
  
  const AppSelectionSheet({
    super.key,
    this.initialSelectedPackages = const [],
    this.initialSelectedCategories = const [],
  });

  @override
  State<AppSelectionSheet> createState() => _AppSelectionSheetState();
}

class _AppSelectionSheetState extends State<AppSelectionSheet> {
  final List<AppInfo> _allApps = [];
  final List<AppInfo> _filteredApps = [];
  final Set<String> _selectedPackages = {};
  final Set<String> _selectedCategories = {};
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  final Map<String, String> _categories = {
    'social': 'Social Media',
    'game': 'Games',
    'entertainment': 'Entertainment',
    'productivity': 'Productivity',
  };

  @override
  void initState() {
    super.initState();
    _selectedPackages.addAll(widget.initialSelectedPackages);
    _selectedCategories.addAll(widget.initialSelectedCategories);
    _loadApps();
  }

  Future<void> _loadApps() async {
    if (Platform.isAndroid) {
      try {
        List<AppInfo> apps = await InstalledApps.getInstalledApps(
          excludeSystemApps: true,
          withIcon: true,
        );
        _allApps.addAll(apps);
        _filteredApps.addAll(apps);
      } catch (e) {
        print("Error loading apps: $e");
      }
    }
    setState(() => _isLoading = false);
  }

  void _filterApps(String query) {
    setState(() {
      _filteredApps.clear();
      if (query.isEmpty) {
        _filteredApps.addAll(_allApps);
      } else {
        _filteredApps.addAll(_allApps.where((app) => 
          app.name!.toLowerCase().contains(query.toLowerCase()) || 
          app.packageName!.toLowerCase().contains(query.toLowerCase())
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const NeoMonoText('SELECT_DISTRACTIONS', fontSize: 18, fontWeight: FontWeight.bold),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CupertinoTextField(
              controller: _searchCtrl,
              onChanged: _filterApps,
              placeholder: 'SEARCH_APPS...',
              placeholderStyle: AppTypography.mono.copyWith(color: AppColors.tertiaryLabel),
              style: AppTypography.mono.copyWith(color: AppColors.label),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.search, color: AppColors.tertiaryLabel, size: 16),
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Categories & List
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('CATEGORIES', style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: _categories.entries.map((e) {
                        final isSelected = _selectedCategories.contains(e.key);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedCategories.remove(e.key);
                              } else {
                                _selectedCategories.add(e.key);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryOrange : AppColors.glassBase,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? AppColors.primaryOrange : AppColors.glassBorder),
                            ),
                            child: Text(
                              e.value.toUpperCase(),
                              style: AppTypography.mono.copyWith(
                                fontSize: 10, 
                                color: isSelected ? Colors.white : AppColors.secondaryLabel,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Apps List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('INSTALLED_APPLICATIONS', style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel)),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
                    ))
                  else if (_filteredApps.isEmpty)
                     Center(child: Padding(
                       padding: const EdgeInsets.all(20.0),
                       child: Text("NO_APPS_FOUND", style: AppTypography.mono.copyWith(color: AppColors.tertiaryLabel)),
                     ))
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        final isSelected = _selectedPackages.contains(app.packageName);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedPackages.remove(app.packageName);
                              } else {
                                _selectedPackages.add(app.packageName!);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.glassBase,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryOrange : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (app.icon != null)
                                  Image.memory(app.icon!, width: 32, height: 32)
                                else
                                  const Icon(Icons.android, color: AppColors.secondaryLabel),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    app.name ?? 'Unknown', 
                                    style: AppTypography.mono.copyWith(color: AppColors.label, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.primaryOrange, size: 20)
                                else
                                  const Icon(CupertinoIcons.circle, color: AppColors.tertiaryLabel, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                  const SizedBox(height: 100), // bottom padding
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: const Border(top: BorderSide(color: AppColors.glassBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL', style: AppTypography.mono.copyWith(color: AppColors.secondaryLabel)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LiquidButton(
                    label: 'SAVE_SELECTION',
                    onPressed: () {
                      Navigator.pop(context, {
                        'packages': _selectedPackages.toList(),
                        'categories': _selectedCategories.toList(),
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
