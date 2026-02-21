import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class HabitStatsPage extends StatefulWidget {
  final Habit habit;
  const HabitStatsPage({super.key, required this.habit});

  @override
  State<HabitStatsPage> createState() => _HabitStatsPageState();
}

class _HabitStatsPageState extends State<HabitStatsPage> {
  List<HabitCompletion>? _history;
  List<HabitLog>? _logs;
  final _logCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _logCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prov = context.read<HabitProvider>();
    final history = await prov.getCompletionHistory(widget.habit.id);
    final logs = await prov.getHabitLogs(widget.habit.id);
    if (mounted) {
      setState(() {
        _history = history;
        _logs = logs;
      });
    }
  }

  Future<void> _saveLog() async {
    if (_logCtrl.text.trim().isEmpty) return;
    await context.read<HabitProvider>().addHabitLog(widget.habit.id, _logCtrl.text.trim());
    _logCtrl.clear();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.primaryOrange;
    
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: NeoMonoText(widget.habit.title.toUpperCase(), fontSize: 14),
        backgroundColor: AppColors.background.withOpacity(0.8),
        border: null,
      ),
      child: ListView(
        padding: const EdgeInsets.all(24).copyWith(bottom: 100),
        children: [
          // Heatmap Section - Clean (no text, no checkmarks)
          _sectionHeader('CONSISTENCY_MATRIX'),
          _history == null 
            ? const Center(child: CupertinoActivityIndicator())
            : _buildHeatmap(_history!, themeColor),
          
          const SizedBox(height: 32),

          // Habit Log (Diary) Section
          _sectionHeader('PROTOCOL_DIARY'),
          _buildLogInput(),
          const SizedBox(height: 16),
          _logs == null
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
                children: _logs!.map((log) => _buildDiaryEntry(log)).toList(),
              ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.primaryOrange, letterSpacing: 1.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeatmap(List<HabitCompletion> history, Color color) {
    final now = DateTime.now();
    final dates = List.generate(28, (i) => now.subtract(Duration(days: 27 - i)));
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: dates.map((date) {
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final isDone = history.any((h) => h.date == dateStr && h.completed);
          return Container(
            width: (MediaQuery.of(context).size.width - 48 - 32 - (7 * 6)) / 7,
            height: 32,
            decoration: BoxDecoration(
              color: isDone ? color : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogInput() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          CupertinoTextField(
            controller: _logCtrl,
            placeholder: 'NOTE_DOWN_INSIGHTS...',
            placeholderStyle: AppTypography.mono.copyWith(color: AppColors.tertiaryLabel, fontSize: 12),
            style: AppTypography.mono.copyWith(color: Colors.white, fontSize: 12),
            maxLines: 3,
            decoration: null,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primaryOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              onPressed: _saveLog,
              child: Text('LOG_ENTRY', style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryEntry(HabitLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(DateTime.parse(log.date)).toUpperCase(),
              style: AppTypography.mono.copyWith(fontSize: 9, color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              log.content,
              style: AppTypography.mono.copyWith(fontSize: 12, color: AppColors.label),
            ),
          ],
        ),
      ),
    );
  }
}