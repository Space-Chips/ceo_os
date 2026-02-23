import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../components/components.dart';
import '../../core/models/task_models.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class EventTypesScreen extends StatefulWidget {
  const EventTypesScreen({super.key});

  @override
  State<EventTypesScreen> createState() => _EventTypesScreenState();
}

class _EventTypesScreenState extends State<EventTypesScreen> {
  final FeatureRepository _repo = FeatureRepository();
  List<EventType> _types = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final types = await _repo.getEventTypes();
    if (!mounted) return;
    setState(() {
      _types = types;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final color = TextEditingController(text: '#3B82F6');
    final icon = TextEditingController(text: 'calendar');

    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('New Event Type'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(controller: name, placeholder: 'Name'),
            const SizedBox(height: 8),
            CupertinoTextField(controller: color, placeholder: 'Color hex'),
            const SizedBox(height: 8),
            CupertinoTextField(controller: icon, placeholder: 'Icon name'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await _repo.createEventType(
                name.text.trim(),
                color.text.trim(),
                icon.text.trim(),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.primaryOrange,
          ),
        ),
        middle: const NeoMonoText(
          'EVENT_TYPES',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _create,
          child: const Icon(CupertinoIcons.add, color: AppColors.primaryOrange),
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _loading
          ? const Center(
              child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
            )
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _types.length,
                itemBuilder: (context, index) {
                  final t = _types[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      borderRadius: 14,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (t.name ?? 'UNTITLED').toUpperCase(),
                              style: AppTypography.mono.copyWith(fontSize: 11),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              await _repo.deleteEventType(t.id);
                              await _load();
                            },
                            child: const Icon(
                              CupertinoIcons.delete,
                              size: 16,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
