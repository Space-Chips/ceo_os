import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../components/components.dart';
import '../../core/models/premium_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/premium_repository.dart';
import '../../core/models/task_models.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/glass_input_field.dart';

enum _NotesFilterKind { all, tag, untagged }

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final FeatureRepository _repo = FeatureRepository();
  final PremiumRepository _premiumRepository = PremiumRepository();
  final TextEditingController _editor = TextEditingController();
  final TextEditingController _tagEditor = TextEditingController();
  final TextEditingController _search = TextEditingController();
  final FocusNode _editorFocus = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  static final RegExp _tagRegex = RegExp(r'(^|\s)#([^\s#]+)');
  static const String _photoTokenPrefix = '[[photo:';
  static const String _photoTokenSuffix = ']]';

  List<Note> _notes = const [];
  Note? _selected;
  String? _notePhotoPath;

  bool _loading = true;
  bool _saving = false;
  bool _searchOpen = false;
  bool _recentExpanded = true;
  bool _writingEditorProgrammatically = false;

  _NotesFilterKind _filterKind = _NotesFilterKind.all;
  String? _selectedTagPath;
  final Set<String> _expandedTagPaths = {};

  Timer? _autosaveDebounce;
  String _lastSavedText = '';
  String _lastSavedTitle = '';
  bool _showingPremiumDialog = false;

  Color get _noteAccent => AppColors.accentSecondary;
  Color get _selectionBg => _noteAccent.withValues(alpha: 0.24);
  Color get _selectionBorder => _noteAccent.withValues(alpha: 0.74);
  Color get _selectionText => _noteAccent.withValues(alpha: 0.96);
  Color get _notesGreen => AppColors.accent;
  Color get _notesGreenLight => AppColors.accentLight;

  String _t(String key) => context.watch<LanguageProvider>().t(key);

  String _formatCompactDate(DateTime date) {
    final locale = context.watch<LanguageProvider>().languageCode;
    return DateFormat.MMMd(locale).format(date);
  }

  @override
  void initState() {
    super.initState();
    _editor.addListener(_onEditorChanged);
    _tagEditor.addListener(_onEditorChanged);
    _search.addListener(() => setState(() {}));
    _load();
  }

  _SplitNoteContent _splitNoteContent(String text) {
    final normalized = text.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    if (lines.isEmpty) return const _SplitNoteContent(tagLine: '', body: '');

    final firstNonEmptyIndex = lines.indexWhere(
      (line) => line.trim().isNotEmpty,
    );
    if (firstNonEmptyIndex == -1) {
      return const _SplitNoteContent(tagLine: '', body: '');
    }

    final firstLine = lines[firstNonEmptyIndex].trim();
    if (!firstLine.startsWith('#')) {
      return _SplitNoteContent(tagLine: '', body: normalized);
    }

    final remaining = [...lines]..removeAt(firstNonEmptyIndex);
    while (remaining.isNotEmpty && remaining.first.trim().isEmpty) {
      remaining.removeAt(0);
    }

    return _SplitNoteContent(tagLine: firstLine, body: remaining.join('\n'));
  }

  String _normalizeTagLine(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return '';
    return cleaned.startsWith('#') ? cleaned : '#$cleaned';
  }

  String _composeNoteContent() {
    final tagLine = _normalizeTagLine(_tagEditor.text);
    final body = _editor.text.trimRight();
    final photoPath = _notePhotoPath;
    final photoLine = (photoPath != null && photoPath.trim().isNotEmpty)
        ? '$_photoTokenPrefix${photoPath.trim()}$_photoTokenSuffix'
        : '';

    final segments = <String>[];
    if (tagLine.isNotEmpty) segments.add(tagLine);
    if (photoLine.isNotEmpty) segments.add(photoLine);
    if (body.isNotEmpty) segments.add(body);
    return segments.join('\n\n');
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    _editor.removeListener(_onEditorChanged);
    _tagEditor.removeListener(_onEditorChanged);
    _editor.dispose();
    _tagEditor.dispose();
    _search.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  Future<void> _load({String? preferredSelectedId}) async {
    if (mounted) setState(() => _loading = true);

    final notes = await _repo.getNotes();
    notes.sort(
      (a, b) => _effectiveUpdateDate(b).compareTo(_effectiveUpdateDate(a)),
    );

    if (!mounted) return;

    Note? nextSelected;
    if (preferredSelectedId != null && preferredSelectedId.isNotEmpty) {
      for (final note in notes) {
        if (note.id == preferredSelectedId) {
          nextSelected = note;
          break;
        }
      }
    } else if (_selected != null) {
      for (final note in notes) {
        if (note.id == _selected!.id) {
          nextSelected = note;
          break;
        }
      }
    }

    final filtered = _filteredNotesFrom(notes);
    nextSelected ??= filtered.isNotEmpty ? filtered.first : null;

    setState(() {
      _notes = notes;
      _selected = nextSelected;
      _loading = false;
    });

    _setEditorFromSelected();
  }

  void _onEditorChanged() {
    if (_writingEditorProgrammatically || _loading) return;
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(
      const Duration(milliseconds: 700),
      _persistCurrentNote,
    );
  }

  Future<void> _persistCurrentNote() async {
    _autosaveDebounce?.cancel();
    _autosaveDebounce = null;

    if (_loading || _saving) return;
    final text = _composeNoteContent();
    final trimmed = text.trim();
    final title = _deriveTitleFrom(text);

    if (_selected == null) {
      if (trimmed.isEmpty) return;
      final premiumCheck = await _premiumRepository.canCreateNote();
      if (!premiumCheck.allowed) {
        await _showPremiumBlocked(premiumCheck);
        return;
      }
      setState(() => _saving = true);
      try {
        final createdId = await _repo.createNote(title, text);
        await _load(preferredSelectedId: createdId);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    if (text == _lastSavedText && title == _lastSavedTitle) return;

    final current = _selected!;
    setState(() => _saving = true);
    try {
      await _repo.updateNote(current.id, title, text);
      final updated = Note(
        id: current.id,
        createdBy: current.createdBy,
        content: text,
        title: title,
        updatedDate: DateTime.now(),
        createdAt: current.createdAt,
      );

      final updatedList = [..._notes.where((n) => n.id != updated.id), updated]
        ..sort(
          (a, b) => _effectiveUpdateDate(b).compareTo(_effectiveUpdateDate(a)),
        );

      if (!mounted) return;
      setState(() {
        _notes = updatedList;
        _selected = updated;
        _lastSavedText = text;
        _lastSavedTitle = title;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showPremiumBlocked(PremiumCheckResult result) async {
    if (_showingPremiumDialog || !mounted) return;
    _showingPremiumDialog = true;
    try {
      await showPremiumGateDialog(context, result);
    } finally {
      _showingPremiumDialog = false;
    }
  }

  Future<void> _flushAutosaveIfPending() async {
    if (_autosaveDebounce == null) return;
    await _persistCurrentNote();
  }

  void _setEditorText(String value) {
    _writingEditorProgrammatically = true;
    _editor.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _writingEditorProgrammatically = false;
  }

  void _setTagText(String value) {
    _writingEditorProgrammatically = true;
    _tagEditor.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _writingEditorProgrammatically = false;
  }

  void _setEditorFromSelected() {
    if (_selected == null) {
      _setTagText('');
      _setEditorText('');
      _lastSavedText = '';
      _lastSavedTitle = '';
      return;
    }

    final rawText = _selected!.content ?? '';
    final parts = _splitNoteContent(rawText);
    _setTagText(parts.tagLine);
    _setEditorText(parts.body);
    _lastSavedText = _composeNoteContent();
    _lastSavedTitle = _selected!.title ?? _deriveTitleFrom(_lastSavedText);
  }

  Future<void> _newNoteDraft() async {
    await _flushAutosaveIfPending();
    if (!mounted || _saving) return;
    final premiumCheck = await _premiumRepository.canCreateNote();
    if (!premiumCheck.allowed) {
      await _showPremiumBlocked(premiumCheck);
      return;
    }
    setState(() => _saving = true);
    try {
      final createdId = await _repo.createNote('Untitled', '');
      if (!mounted) return;
      setState(() {
        _filterKind = _NotesFilterKind.all;
        _selectedTagPath = null;
        _searchOpen = false;
      });
      _search.clear();
      await _load(preferredSelectedId: createdId);
      if (!mounted) return;
      _editorFocus.requestFocus();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteSelected() async {
    await _flushAutosaveIfPending();
    final note = _selected;
    if (note == null) return;

    await _repo.deleteNote(note.id);
    if (!mounted) return;

    final remaining = _notes.where((n) => n.id != note.id).toList()
      ..sort(
        (a, b) => _effectiveUpdateDate(b).compareTo(_effectiveUpdateDate(a)),
      );

    setState(() {
      _notes = remaining;
      _selected = null;
    });
    _ensureSelectedNoteInFilter();
  }

  Future<void> _selectNote(Note note) async {
    await _flushAutosaveIfPending();
    if (!mounted) return;
    setState(() {
      _selected = note;
    });
    _setEditorFromSelected();
  }

  Future<void> _selectAllNotes() async {
    await _flushAutosaveIfPending();
    if (!mounted) return;
    setState(() {
      _filterKind = _NotesFilterKind.all;
      _selectedTagPath = null;
    });
    _ensureSelectedNoteInFilter();
  }

  Future<void> _selectTag(String tagPath) async {
    await _flushAutosaveIfPending();
    if (!mounted) return;
    setState(() {
      _filterKind = _NotesFilterKind.tag;
      _selectedTagPath = tagPath;
      final hasChildren = _tagTree().childrenByParent.containsKey(tagPath);
      if (hasChildren) {
        if (_expandedTagPaths.contains(tagPath)) {
          _expandedTagPaths.remove(tagPath);
        } else {
          _expandedTagPaths.add(tagPath);
        }
      }
    });
    _ensureSelectedNoteInFilter();
  }

  Future<void> _selectUntagged() async {
    await _flushAutosaveIfPending();
    if (!mounted) return;
    setState(() {
      _filterKind = _NotesFilterKind.untagged;
      _selectedTagPath = null;
    });
    _ensureSelectedNoteInFilter();
  }

  void _ensureSelectedNoteInFilter() {
    final filtered = _filteredNotes;
    if (filtered.isEmpty) {
      setState(() {
        _selected = null;
      });
      _setTagText('');
      _setEditorText('');
      return;
    }

    final current = _selected;
    if (current != null && filtered.any((n) => n.id == current.id)) {
      return;
    }

    setState(() => _selected = filtered.first);
    _setEditorFromSelected();
  }

  DateTime _effectiveUpdateDate(Note note) =>
      note.updatedDate ?? note.createdAt;

  String _deriveTitleFrom(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return 'Untitled';

    for (final line in lines) {
      if (line.startsWith(_photoTokenPrefix) &&
          line.endsWith(_photoTokenSuffix)) {
        continue;
      }
      if (!line.startsWith('#')) {
        return line.length > 80 ? line.substring(0, 80) : line;
      }
    }

    final fallback = lines.first.startsWith('#')
        ? lines.first.substring(1)
        : lines.first;
    return fallback.length > 80 ? fallback.substring(0, 80) : fallback;
  }

  _ParsedNoteContent _parseNoteContent(String text) {
    final base = _splitNoteContent(text);
    final normalizedBody = base.body.replaceAll('\r\n', '\n');
    final lines = normalizedBody.split('\n');

    int firstNonEmpty = lines.indexWhere((l) => l.trim().isNotEmpty);
    if (firstNonEmpty == -1) {
      return _ParsedNoteContent(
        tagLine: base.tagLine,
        body: '',
        photoPath: null,
      );
    }

    String? photoPath;
    final firstLine = lines[firstNonEmpty].trim();
    if (firstLine.startsWith(_photoTokenPrefix) &&
        firstLine.endsWith(_photoTokenSuffix)) {
      final raw = firstLine.substring(
        _photoTokenPrefix.length,
        firstLine.length - _photoTokenSuffix.length,
      );
      final candidate = raw.trim();
      if (candidate.isNotEmpty) {
        photoPath = candidate;
      }

      final remaining = [...lines]..removeAt(firstNonEmpty);
      while (remaining.isNotEmpty && remaining.first.trim().isEmpty) {
        remaining.removeAt(0);
      }

      return _ParsedNoteContent(
        tagLine: base.tagLine,
        body: remaining.join('\n'),
        photoPath: photoPath,
      );
    }

    return _ParsedNoteContent(
      tagLine: base.tagLine,
      body: normalizedBody,
      photoPath: null,
    );
  }

  Future<void> _pickPhotoForNote() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'note_photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final ext = p.extension(picked.path).isNotEmpty
        ? p.extension(picked.path)
        : '.jpg';
    final filename = '${const Uuid().v4()}$ext';
    final destPath = p.join(dir.path, filename);
    await File(picked.path).copy(destPath);

    if (!mounted) return;
    setState(() => _notePhotoPath = destPath);
    await _persistCurrentNote();
  }

  void _openNotePhotoFullScreen(String path) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _NotePhotoViewer(path: path),
      ),
    );
  }

  Set<String> _extractTagsFrom(Note note) {
    final source = '${note.title ?? ''}\n${note.content ?? ''}';
    return _extractTagsFromRaw(source);
  }

  Set<String> _extractTagsFromRaw(String text) {
    final tags = <String>{};
    for (final match in _tagRegex.allMatches(text)) {
      var token = (match.group(2) ?? '').trim();
      token = token.replaceAll(RegExp(r'[),.;:!?]+$'), '');
      if (token.isEmpty) continue;

      final parts = token
          .split('/')
          .map((segment) => segment.trim().toLowerCase())
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (parts.isEmpty) continue;
      tags.add(parts.join('/'));
    }
    return tags;
  }

  bool _noteHasTagOrSubtag(Note note, String filterTagPath) {
    final tags = _extractTagsFrom(note);
    for (final tag in tags) {
      if (tag == filterTagPath || tag.startsWith('$filterTagPath/')) {
        return true;
      }
    }
    return false;
  }

  bool _matchesSearch(Note note) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final title = (note.title ?? '').toLowerCase();
    final body = (note.content ?? '').toLowerCase();
    return title.contains(q) || body.contains(q);
  }

  List<Note> _filteredNotesFrom(List<Note> source) {
    Iterable<Note> list = source;
    switch (_filterKind) {
      case _NotesFilterKind.all:
        break;
      case _NotesFilterKind.tag:
        final tag = _selectedTagPath;
        if (tag == null || tag.isEmpty) {
          list = const [];
        } else {
          list = source.where((note) => _noteHasTagOrSubtag(note, tag));
        }
        break;
      case _NotesFilterKind.untagged:
        list = source.where((note) => _extractTagsFrom(note).isEmpty);
        break;
    }

    return list.where(_matchesSearch).toList()..sort(
      (a, b) => _effectiveUpdateDate(b).compareTo(_effectiveUpdateDate(a)),
    );
  }

  List<Note> get _filteredNotes => _filteredNotesFrom(_notes);

  List<Note> get _recentNotes {
    final notes = [..._notes];
    notes.sort(
      (a, b) => _effectiveUpdateDate(b).compareTo(_effectiveUpdateDate(a)),
    );
    return notes.take(5).toList();
  }

  _TagTreeData _tagTree() {
    final pathToNoteIds = <String, Set<String>>{};
    final childrenByParent = <String, Set<String>>{};

    for (final note in _notes) {
      final tags = _extractTagsFrom(note);
      for (final tag in tags) {
        final parts = tag.split('/');
        for (int i = 0; i < parts.length; i++) {
          final path = parts.sublist(0, i + 1).join('/');
          pathToNoteIds.putIfAbsent(path, () => <String>{}).add(note.id);

          final parent = i == 0 ? '' : parts.sublist(0, i).join('/');
          childrenByParent.putIfAbsent(parent, () => <String>{}).add(path);
        }
      }
    }

    int untaggedCount = 0;
    for (final note in _notes) {
      if (_extractTagsFrom(note).isEmpty) untaggedCount++;
    }

    return _TagTreeData(
      pathToNoteIds: pathToNoteIds,
      childrenByParent: {
        for (final e in childrenByParent.entries) e.key: e.value.toList(),
      },
      untaggedCount: untaggedCount,
    );
  }

  String _compactTitle(Note note) {
    final title = (note.title ?? '').trim();
    if (title.isNotEmpty) {
      if (title == 'Untitled') return _t('notes_untitled');
      return title;
    }

    final text = (note.content ?? '').trim();
    if (text.isEmpty) return _t('notes_untitled');
    final firstLine = text.split('\n').first.trim();
    if (firstLine.isEmpty) return _t('notes_untitled');
    return firstLine.startsWith('#') ? firstLine.substring(1) : firstLine;
  }

  @override
  Widget build(BuildContext context) {
    final tagTree = _tagTree();
    final selected = _selected;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidebarWidth = (screenWidth * 0.18).clamp(104.0, 132.0);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: _loading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: AppColors.primaryOrange,
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    _topBar(),
                    if (_searchOpen) _searchBar(),
                    Expanded(
                      child: Row(
                        children: [
                          _leftSidebar(tagTree, width: sidebarWidth),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                10,
                                10,
                                10,
                                10,
                              ),
                              child: Stack(
                                children: [
                                  GlassCard(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      12,
                                      14,
                                      12,
                                    ),
                                    borderRadius: 14,
                                    border: Border.all(
                                      color: AppColors.glassBorder.withValues(
                                        alpha: 0.85,
                                      ),
                                      width: 0.6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              selected == null
                                                  ? 'NEW NOTE'
                                                  : "LAST EDIT: ${DateFormat('MMM d').format(_effectiveUpdateDate(selected))}",
                                              style: AppTypography.mono
                                                  .copyWith(
                                                    fontSize: 10,
                                                    color:
                                                        AppColors.tertiaryLabel,
                                                    letterSpacing: 1.2,
                                                  ),
                                            ),
                                            const Spacer(),
                                            if (_saving)
                                              Text(
                                                'Saving...',
                                                style: AppTypography.mono
                                                    .copyWith(
                                                      fontSize: 10,
                                                      color: AppColors
                                                          .primaryOrange,
                                                    ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: CupertinoTextField(
                                            controller: _editor,
                                            focusNode: _editorFocus,
                                            expands: true,
                                            maxLines: null,
                                            textAlignVertical:
                                                TextAlignVertical.top,
                                            placeholder:
                                                '#work/meeting\n\nWrite your note...',
                                            style: AppTypography.mono.copyWith(
                                              fontSize: 20,
                                              color: AppColors.label,
                                              height: 1.35,
                                            ),
                                            placeholderStyle: AppTypography.mono
                                                .copyWith(
                                                  fontSize: 20,
                                                  color: AppColors.tertiaryLabel
                                                      .withValues(alpha: 0.65),
                                                  height: 1.35,
                                                ),
                                            decoration: null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: selected == null
                                          ? null
                                          : _deleteSelected,
                                      child: Opacity(
                                        opacity: selected == null ? 0.35 : 1,
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            color: AppColors.backgroundLight
                                                .withValues(alpha: 0.72),
                                            border: Border.all(
                                              color: AppColors.glassBorder
                                                  .withValues(alpha: 0.82),
                                              width: 0.6,
                                            ),
                                          ),
                                          child: Icon(
                                            CupertinoIcons.delete,
                                            color: AppColors.tertiaryLabel,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Row(
        children: [
          _iconButton(
            icon: CupertinoIcons.back,
            onTap: () async {
              await _flushAutosaveIfPending();
              if (!mounted) return;
              context.go('/home');
            },
          ),
          const Spacer(),
          Text(
            _t('notes'),
            style: AppTypography.title2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.accent,
            ),
          ),
          const Spacer(),
          _iconButton(
            icon: CupertinoIcons.search,
            onTap: () {
              setState(() => _searchOpen = !_searchOpen);
              if (!_searchOpen) {
                _search.clear();
              }
            },
          ),
          const SizedBox(width: 10),
          _plusButton(),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassInputField(
        controller: _search,
        placeholder: _t('notes_search_placeholder'),
      ),
    );
  }

  Widget _leftSidebar(_TagTreeData tagTree, {required double width}) {
    final selectedAll = _filterKind == _NotesFilterKind.all;
    final selectedUntagged = _filterKind == _NotesFilterKind.untagged;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.sectionBackground.withValues(alpha: 0.5),
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
        children: [
          _sectionHeader(
            label: _t('notes_recent'),
            expanded: _recentExpanded,
            onTap: () => setState(() => _recentExpanded = !_recentExpanded),
          ),
          if (_recentExpanded) ...[
            const SizedBox(height: 8),
            ..._recentNotes.map((note) {
              final active = _selected?.id == note.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PressableSurface(
                  onTap: () => _selectNote(note),
                  pressedScale: 0.98,
                  borderRadius: 12,
                  child: Container(
                    height: 62,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: active ? _selectionBg : AppColors.pillBackground,
                      border: Border.all(
                        color: active ? _selectionBorder : AppColors.pillBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _compactTitle(note),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.mono.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? _selectionText
                                : AppColors.secondaryLabel.withValues(
                                    alpha: 0.86,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM d',
                          ).format(_effectiveUpdateDate(note)),
                          style: AppTypography.mono.copyWith(
                            fontSize: 10,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
          ],
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          _folderRow(
            label: _t('notes_all_notes'),
            selected: selectedAll,
            onTap: _selectAllNotes,
          ),
          const SizedBox(height: 4),
          ..._topLevelTagPaths(
            tagTree,
          ).map((tagPath) => _tagTreeItem(tagTree, tagPath, depth: 0)),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          _folderRow(
            label: _t('notes_no_tag'),
            selected: selectedUntagged,
            onTap: _selectUntagged,
          ),
        ],
      ),
    );
  }

  List<String> _topLevelTagPaths(_TagTreeData data) {
    final roots = data.childrenByParent[''] ?? const [];
    final deduped = roots.toSet().toList();
    deduped.sort((a, b) => _tagLabel(a).compareTo(_tagLabel(b)));
    return deduped;
  }

  Widget _tagTreeItem(_TagTreeData data, String tagPath, {required int depth}) {
    final selected =
        _filterKind == _NotesFilterKind.tag && _selectedTagPath == tagPath;
    final children = List<String>.from(
      data.childrenByParent[tagPath] ?? const <String>[],
    )..sort((a, b) => _tagLabel(a).compareTo(_tagLabel(b)));
    final hasChildren = children.isNotEmpty;
    final expanded = _expandedTagPaths.contains(tagPath);
    final count = data.pathToNoteIds[tagPath]?.length ?? 0;
    return Padding(
      padding: EdgeInsets.only(left: 2.0 * depth, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PressableSurface(
            onTap: () => _selectTag(tagPath),
            pressedScale: 0.98,
            borderRadius: 10,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: selected
                    ? _notesGreen.withValues(alpha: 0.12)
                    : AppColors.background.withValues(alpha: 0),
                border: Border.all(
                  color: selected
                      ? _notesGreen.withValues(alpha: 0.35)
                      : AppColors.background.withValues(alpha: 0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (hasChildren)
                    Icon(
                      expanded
                          ? CupertinoIcons.chevron_down
                          : CupertinoIcons.chevron_right,
                      size: 12,
                      color: selected
                          ? _selectionText
                          : AppColors.tertiaryLabel,
                    )
                  else
                    const SizedBox(width: 8),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _tagLabel(tagPath),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono.copyWith(
                        fontSize: 14,
                        color: selected
                            ? AppColors.white
                            : AppColors.secondaryLabel,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                  if (count > 0)
                    Text(
                      '$count',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.tertiaryLabel,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (expanded)
            ...children.map(
              (child) => _tagTreeItem(data, child, depth: depth + 1),
            ),
        ],
      ),
    );
  }

  String _tagLabel(String path) {
    final idx = path.lastIndexOf('/');
    if (idx < 0) return path;
    return path.substring(idx + 1);
  }

  Widget _sectionHeader({
    required String label,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return _PressableSurface(
      onTap: onTap,
      pressedScale: 0.98,
      borderRadius: 10,
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.overline.copyWith(
              fontSize: 10,
              color: AppColors.secondaryLabel.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Icon(
            expanded
                ? CupertinoIcons.chevron_down
                : CupertinoIcons.chevron_right,
            size: 12,
            color: AppColors.tertiaryLabel,
          ),
        ],
      ),
    );
  }

  Widget _folderRow({
    required String label,
    required bool selected,
    required Future<void> Function() onTap,
    int count = 0,
  }) {
    return _PressableSurface(
      onTap: onTap,
      pressedScale: 0.98,
      borderRadius: 10,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? _notesGreen.withValues(alpha: 0.12)
              : AppColors.background.withValues(alpha: 0),
          border: Border.all(
            color: selected
                ? _notesGreen.withValues(alpha: 0.35)
                : AppColors.background.withValues(alpha: 0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.subhead.copyWith(
                  fontSize: 12,
                  color: selected
                      ? _notesGreenLight
                      : AppColors.secondaryLabel.withValues(alpha: 0.6),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return _PressableSurface(
      onTap: onTap,
      pressedScale: 0.96,
      borderRadius: 14,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.topBarControlBackground,
          border: Border.all(color: AppColors.topBarControlBorder, width: 1),
        ),
        child: Icon(icon, color: AppColors.secondaryLabel, size: 20),
      ),
    );
  }

  Widget _plusButton() {
    return _PressableSurface(
      onTap: _newNoteDraft,
      pressedScale: 0.96,
      borderRadius: 14,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_notesGreenLight, _notesGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.themeGlow.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: Offset(0, 6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Icon(CupertinoIcons.add, color: AppColors.onAccent),
      ),
    );
  }
}

class _PressableSurface extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double borderRadius;

  const _PressableSurface({
    required this.child,
    required this.onTap,
    required this.pressedScale,
    required this.borderRadius,
  });

  @override
  State<_PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<_PressableSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _TagTreeData {
  final Map<String, Set<String>> pathToNoteIds;
  final Map<String, List<String>> childrenByParent;
  final int untaggedCount;

  const _TagTreeData({
    required this.pathToNoteIds,
    required this.childrenByParent,
    required this.untaggedCount,
  });
}

class _SplitNoteContent {
  final String tagLine;
  final String body;

  const _SplitNoteContent({required this.tagLine, required this.body});
}

class _ParsedNoteContent {
  final String tagLine;
  final String body;
  final String? photoPath;

  const _ParsedNoteContent({
    required this.tagLine,
    required this.body,
    required this.photoPath,
  });
}

class _NotePhotoViewer extends StatelessWidget {
  final String path;

  const _NotePhotoViewer({required this.path});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.75),
        middle: Text(
          'Photo',
          style: AppTypography.headline.copyWith(color: CupertinoColors.white),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => const Icon(
                CupertinoIcons.photo,
                color: CupertinoColors.white,
                size: 44,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
