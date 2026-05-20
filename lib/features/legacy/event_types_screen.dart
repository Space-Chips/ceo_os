import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, FontWeight;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/premium_models.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/repositories/premium_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/glass_input_field.dart';

class _TypeColorOption {
  final String value;
  final Color color;

  const _TypeColorOption(this.value, this.color);
}

class EventTypesScreen extends StatefulWidget {
  const EventTypesScreen({super.key});

  @override
  State<EventTypesScreen> createState() => _EventTypesScreenState();
}

class _EventTypesScreenState extends State<EventTypesScreen> {
  final FeatureRepository _repo = FeatureRepository();
  final PremiumRepository _premiumRepository = PremiumRepository();
  final TextEditingController _nameController = TextEditingController();

  String _t(String key) => context.watch<LanguageProvider>().t(key);

  static const List<_TypeColorOption> _colorOptions = [
    _TypeColorOption('blue', Color(0xFF93C5FD)),
    _TypeColorOption('green', Color(0xFF86EFAC)),
    _TypeColorOption('purple', Color(0xFFC4B5FD)),
    _TypeColorOption('pink', Color(0xFFF9A8D4)),
    _TypeColorOption('orange', Color(0xFFFCD34D)),
    _TypeColorOption('red', Color(0xFFFCA5A5)),
    _TypeColorOption('yellow', Color(0xFFFDE68A)),
    _TypeColorOption('teal', Color(0xFF99F6E4)),
  ];

  List<EventType> _types = const [];
  bool _loading = true;
  bool _creating = false;
  bool _showForm = false;
  PremiumCheckResult? _premiumBlock;
  String _selectedColor = 'blue';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final premiumCheck = await _premiumRepository.canAccessAdvancedCalendar();
    if (!premiumCheck.allowed) {
      if (!mounted) return;
      setState(() {
        _premiumBlock = premiumCheck;
        _loading = false;
      });
      return;
    }

    final types = await _repo.getEventTypes();
    if (!mounted) return;
    setState(() {
      _premiumBlock = null;
      _types = types;
      _loading = false;
    });
  }

  Future<void> _createType() async {
    if (_nameController.text.trim().isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      await _repo.createEventType(
        _nameController.text.trim(),
        _selectedColor,
        'calendar',
      );
      _nameController.clear();
      if (!mounted) return;
      await _load();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _deleteType(EventType type) async {
    await _repo.deleteEventType(type.id);
    await _load();
  }

  Color _colorForType(EventType type) {
    final raw = (type.color ?? '').trim();
    for (final option in _colorOptions) {
      if (option.value == raw.toLowerCase()) return option.color;
    }

    var value = raw.replaceAll('#', '');
    if (value.length == 3) {
      value = value.split('').map((c) => '$c$c').join();
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return AppColors.primaryOrange;
    return Color(parsed);
  }

  void _openCreateTypeModal() {
    _nameController.clear();
    setState(() {
      _selectedColor = 'blue';
    });

    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _t('event_types_create_title'),
                      style: AppTypography.body.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _t('event_types_type_name'),
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppColors.secondaryLabel.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: CupertinoTextField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        placeholder: _t('event_types_name_placeholder'),
                        placeholderStyle: AppTypography.body.copyWith(
                          fontSize: 14,
                          color: AppColors.secondaryLabel.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        style: AppTypography.body.copyWith(
                          fontSize: 14,
                          color: AppColors.label,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _t('event_types_color'),
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppColors.secondaryLabel.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _colorOptions.map((option) {
                        final selected = _selectedColor == option.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedColor = option.value);
                            setModalState(() {});
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: option.color.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: AppColors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Text(
                              _t('cancel'),
                              style: AppTypography.body.copyWith(
                                fontSize: 14,
                                color: AppColors.label,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            onPressed: _creating ? null : _createType,
                            child: Text(
                              _creating ? _t('creating') : _t('create'),
                              style: AppTypography.body.copyWith(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: SafeArea(
          child: _loading
              ? Center(
                  child: CupertinoActivityIndicator(
                    color: AppColors.primaryOrange,
                  ),
                )
              : _premiumBlock != null
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [_buildPremiumLockedCard(_premiumBlock!)],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildTypesList(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 46,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              onPressed: () => context.go('/calendar'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.arrow_left,
                    color: AppColors.secondaryLabel,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _t('back'),
                    style: AppTypography.mono.copyWith(
                      fontSize: 15,
                      color: AppColors.secondaryLabel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Event Types',
              style: AppTypography.mono.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => setState(() => _showForm = !_showForm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.92),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.95),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.22),
              blurRadius: 24,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, size: 28, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              'Add Event Type',
              style: AppTypography.mono.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      border: Border.all(color: AppColors.glassBorder, width: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type Name',
            style: AppTypography.mono.copyWith(
              fontSize: 13,
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GlassInputField(
            placeholder: 'e.g., Work, Sport, Personal',
            controller: _nameController,
          ),
          const SizedBox(height: 14),
          Text(
            'Color',
            style: AppTypography.mono.copyWith(
              fontSize: 13,
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _colorOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final option = _colorOptions[index];
              final selected = _selectedColor == option.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = option.value),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.backgroundLight.withValues(alpha: 0.68),
                    border: Border.all(
                      color: selected
                          ? option.color.withValues(alpha: 0.95)
                          : AppColors.glassBorder.withValues(alpha: 0.45),
                      width: selected ? 1.4 : 0.7,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: option.color.withValues(
                          alpha: selected ? 0.95 : 0.62,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: AppColors.backgroundLight.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => setState(() => _showForm = false),
                  child: Text(
                    'Cancel',
                    style: AppTypography.mono.copyWith(
                      fontSize: 13,
                      color: AppColors.label,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _createType,
                  child: Text(
                    _creating ? 'Adding…' : 'Add',
                    style: AppTypography.mono.copyWith(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypesList() {
    if (_types.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: 16,
        child: Text(
          'No event types yet.',
          style: AppTypography.mono.copyWith(
            fontSize: 12,
            color: AppColors.tertiaryLabel,
          ),
        ),
      );
    }

    return Column(
      children: _types.map((type) {
        final color = _colorForType(type);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (type.name ?? _t('untitled')),
                    style: AppTypography.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.label,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _deleteType(type),
                  child: Icon(
                    CupertinoIcons.delete,
                    color: const Color(0xFFEF4444),
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPremiumLockedCard(PremiumCheckResult check) {
    final message = premiumMessageForReason(check.reason);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      border: Border.all(
        color: AppColors.primaryOrange.withValues(alpha: 0.28),
        width: 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.lock_shield_fill,
                size: 16,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.title,
                  style: AppTypography.mono.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.label,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.description,
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: AppColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}
