import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'habit_stats_page.dart';

class HabitCompletionPage extends StatefulWidget {
  final Habit habit;
  const HabitCompletionPage({super.key, required this.habit});

  @override
  State<HabitCompletionPage> createState() => _HabitCompletionPageState();
}

class _HabitCompletionPageState extends State<HabitCompletionPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _slideValue = 0.0;
  bool _isCompleted = false;
  int _streak = 0;
  double _completionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _isCompleted = context.read<HabitProvider>().isHabitCompletedToday(widget.habit.id);
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    final prov = context.read<HabitProvider>();
    final history = await prov.getCompletionHistory(widget.habit.id);
    final streak = prov.calculateStreak(widget.habit.id, history);
    
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentComps = history.where((c) {
      final date = DateTime.parse(c.date);
      return date.isAfter(thirtyDaysAgo) && c.completed;
    }).length;
    final rate = (recentComps / 30.0) * 100;

    if (mounted) {
      setState(() {
        _streak = streak;
        _completionRate = rate;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSlideUpdate(DragUpdateDetails details) {
    if (_isCompleted) return;
    setState(() {
      _slideValue += details.primaryDelta! / (MediaQuery.of(context).size.width - 160); 
      if (_slideValue < 0) _slideValue = 0;
      if (_slideValue > 1) _slideValue = 1;
      
      if ((_slideValue * 10).floor() > ((_slideValue - details.primaryDelta! / 200) * 10).floor()) {
        HapticFeedback.selectionClick();
      }
    });
  }

  Future<void> _onSlideEnd(DragEndDetails details) async {
    if (_isCompleted) return;
    if (_slideValue > 0.9) {
      if (widget.habit.targetType == 'amount') {
        _showAmountDialog();
      } else {
        _completeHabit();
      }
    } else {
      setState(() => _slideValue = 0.0);
    }
  }

  void _completeHabit({double? amount}) async {
    setState(() {
      _slideValue = 1.0;
      _isCompleted = true;
    });
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      await context.read<HabitProvider>().toggleHabit(widget.habit.id, amount: amount);
      _loadRealData();
    }
  }

  void _showAmountDialog() {
    final ctrl = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('LOG_PROGRESS'.toUpperCase(), style: AppTypography.mono.copyWith(fontSize: 14)),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Text('ENTER_${widget.habit.targetUnit ?? 'AMOUNT'}'.toUpperCase(), style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.secondaryLabel)),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: AppTypography.mono.copyWith(color: Colors.white),
                placeholder: '0.0',
                placeholderStyle: AppTypography.mono.copyWith(color: AppColors.tertiaryLabel),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('CANCEL', style: TextStyle(color: AppColors.secondaryLabel)),
            onPressed: () {
              setState(() => _slideValue = 0.0);
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('COMMIT', style: TextStyle(color: AppColors.primaryOrange)),
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              Navigator.pop(context);
              _completeHabit(amount: val);
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'bolt': return CupertinoIcons.bolt_fill;
      case 'flame': return CupertinoIcons.flame_fill;
      case 'drop': return CupertinoIcons.drop_fill;
      case 'heart': return CupertinoIcons.heart_fill;
      case 'star': return CupertinoIcons.star_fill;
      case 'timer': return CupertinoIcons.timer;
      case 'briefcase': return CupertinoIcons.briefcase_fill;
      case 'book': return CupertinoIcons.book_fill;
      case 'leaf': return CupertinoIcons.refresh;
      case 'moon': return CupertinoIcons.moon_fill;
      case 'sun': return CupertinoIcons.sun_max_fill;
      case 'water': return CupertinoIcons.drop_fill;
      default: return CupertinoIcons.bolt_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.primaryOrange;
    
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColor.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Icon(CupertinoIcons.xmark, color: AppColors.secondaryLabel),
                        onPressed: () => Navigator.pop(context),
                      ),
                      NeoMonoText('PROTOCOL_LOG', fontSize: 12, color: themeColor),
                      const SizedBox(width: 44), 
                    ],
                  ),
                ),

                const Spacer(),

                TweenAnimationBuilder(
                  duration: const Duration(seconds: 1),
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value + (_isCompleted ? 0.2 : 0.0),
                      child: Icon(_getIconData(widget.habit.icon), size: 120, color: themeColor),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                NeoMonoText(widget.habit.title.toUpperCase(), fontSize: 24, fontWeight: FontWeight.bold),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.habit.quote ?? 'PUSH_TOWARDS_EXCELLENCE',
                    textAlign: TextAlign.center,
                    style: AppTypography.mono.copyWith(fontSize: 12, color: AppColors.secondaryLabel, fontStyle: FontStyle.italic),
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatMiniItem('STREAK', '${_streak}_DAYS', themeColor),
                        _StatMiniItem('CONSISTENCY', '${_completionRate.toInt()}%', themeColor),
                        _StatMiniItem('STATUS', _streak > 5 ? 'A+' : 'B', themeColor),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: themeColor.withOpacity(0.3)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Opacity(
                            opacity: (1.0 - _slideValue).clamp(0.0, 1.0),
                            child: NeoMonoText(
                              _isCompleted ? 'PROTOCOL_LOCKED' : 'SLIDE_TO_COMMIT',
                              fontSize: 12,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                        ),
                        if (!_isCompleted)
                          Positioned(
                            left: _slideValue * (MediaQuery.of(context).size.width - 80 - 80),
                            child: GestureDetector(
                              onHorizontalDragUpdate: _onSlideUpdate,
                              onHorizontalDragEnd: _onSlideEnd,
                              child: Container(
                                width: 72,
                                height: 72,
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: themeColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
                                  ],
                                ),
                                child: const Icon(CupertinoIcons.chevron_right_2, color: Colors.white),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            right: 4,
                            top: 4,
                            bottom: 4,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                              child: const Icon(CupertinoIcons.checkmark, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                CupertinoButton(
                  child: Text('SEE_MORE_ANALYTICS', style: AppTypography.mono.copyWith(fontSize: 10, color: themeColor, decoration: TextDecoration.underline)),
                  onPressed: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (_) => HabitStatsPage(habit: widget.habit)));
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _StatMiniItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.mono.copyWith(fontSize: 8, color: AppColors.tertiaryLabel)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.mono.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}