import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../components/components.dart';
import '../../core/models/task_models.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final FeatureRepository _repo = FeatureRepository();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();

  List<Note> _notes = [];
  Note? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final notes = await _repo.getNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _selected ??= notes.isNotEmpty ? notes.first : null;
      _title.text = _selected?.title ?? '';
      _body.text = _selected?.content ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) return;
    if (_selected == null) {
      await _repo.createNote(_title.text.trim(), _body.text.trim());
    } else {
      await _repo.updateNote(
        _selected!.id,
        _title.text.trim(),
        _body.text.trim(),
      );
    }
    await _load();
  }

  Future<void> _new() async {
    setState(() {
      _selected = null;
      _title.clear();
      _body.clear();
    });
  }

  Future<void> _delete() async {
    if (_selected == null) return;
    await _repo.deleteNote(_selected!.id);
    setState(() {
      _selected = null;
      _title.clear();
      _body.clear();
    });
    await _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
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
          'NOTES',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _new,
              child: const Icon(
                CupertinoIcons.add,
                size: 20,
                color: AppColors.primaryOrange,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _save,
              child: const Icon(
                CupertinoIcons.check_mark_circled,
                size: 20,
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _loading
          ? const Center(
              child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
            )
          : SafeArea(
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        final selected = _selected?.id == note.id;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selected = note;
                            _title.text = note.title ?? '';
                            _body.text = note.content ?? '';
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryOrange.withValues(
                                      alpha: 0.15,
                                    )
                                  : AppColors.backgroundLight.withValues(
                                      alpha: 0.7,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              (note.title ?? 'Untitled').toUpperCase(),
                              style: AppTypography.mono.copyWith(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: _notes.length,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 14,
                        child: Column(
                          children: [
                            CupertinoTextField(
                              controller: _title,
                              placeholder: 'Title',
                              style: AppTypography.mono.copyWith(
                                fontSize: 14,
                                color: AppColors.label,
                              ),
                              placeholderStyle: AppTypography.mono.copyWith(
                                fontSize: 14,
                                color: AppColors.tertiaryLabel,
                              ),
                              decoration: null,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: CupertinoTextField(
                                controller: _body,
                                expands: true,
                                maxLines: null,
                                placeholder: 'Write note...',
                                style: AppTypography.mono.copyWith(
                                  fontSize: 12,
                                  color: AppColors.label,
                                ),
                                placeholderStyle: AppTypography.mono.copyWith(
                                  fontSize: 12,
                                  color: AppColors.tertiaryLabel,
                                ),
                                decoration: null,
                              ),
                            ),
                            if (_selected != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  onPressed: _delete,
                                  child: Text(
                                    'DELETE',
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 11,
                                      color: AppColors.error,
                                    ),
                                  ),
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
    );
  }
}
