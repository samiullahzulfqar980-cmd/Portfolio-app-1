import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_env.dart';
import '../../core/errors/app_failure.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/content_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/storage_urls.dart';
import '../../core/utils/validators.dart';
import '../../data/models/project.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'admin_scaffold.dart';

class ProjectEditorScreen extends ConsumerStatefulWidget {
  const ProjectEditorScreen({super.key, this.project, this.projectId});

  /// Passed via `extra` when navigating from the list (fast path).
  final Project? project;
  final String? projectId;

  @override
  ConsumerState<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends ConsumerState<ProjectEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _slug = TextEditingController();
  final TextEditingController _summary = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _demoUrl = TextEditingController();
  final TextEditingController _repoUrl = TextEditingController();
  final TextEditingController _year = TextEditingController();
  final TextEditingController _techInput = TextEditingController();

  final List<String> _technologies = <String>[];
  static const List<String> _categories = <String>[
    'Mobile',
    'Web',
    'Full-stack',
    'Design',
    'Open source',
  ];
  static const List<String> _accents = <String>['violet', 'cyan', 'amber', 'mint', 'rose'];

  Project? _initial;
  bool _initialised = false;
  bool _notFound = false;
  bool _slugTouched = false;
  bool _saving = false;
  bool _uploading = false;
  String _category = _categories.first;
  String _accent = _accents.first;
  ProjectStatus _status = ProjectStatus.draft;
  bool _featured = false;
  int _sortOrder = 1;
  String? _imagePath;
  Uint8List? _localImageBytes;
  String? _error;

  bool get _isNew => _initial == null;

  @override
  void initState() {
    super.initState();
    _title.addListener(_maybeAutofillSlug);

    // Hydration happens here (or in a provider listener) so text controllers
    // are never mutated while the widget tree is building.
    final Project? incoming = widget.project;
    if (incoming != null) {
      _hydrate(incoming);
      _initialised = true;
    } else if (widget.projectId != null) {
      _resolveExistingProject();
    } else {
      _initialised = true;
    }
  }

  /// Deep-link path: the row is not in `extra`, so wait for the admin list.
  void _resolveExistingProject() {
    final List<Project>? cached = ref.read(adminProjectsProvider).value;
    if (cached != null) {
      _applyIncoming(cached);
      return;
    }
    ref.listenManual(
      adminProjectsProvider,
      (AsyncValue<List<Project>>? previous, AsyncValue<List<Project>> next) {
        final List<Project>? loaded = next.value;
        if (loaded != null && mounted && !_initialised) {
          setState(() => _applyIncoming(loaded));
        }
      },
    );
  }

  void _applyIncoming(List<Project> projects) {
    for (final Project candidate in projects) {
      if (candidate.id == widget.projectId) {
        _hydrate(candidate);
        break;
      }
    }
    _notFound = _initial == null;
    _initialised = true;
  }

  @override
  void dispose() {
    _title.removeListener(_maybeAutofillSlug);
    for (final TextEditingController controller in <TextEditingController>[
      _title,
      _slug,
      _summary,
      _description,
      _demoUrl,
      _repoUrl,
      _year,
      _techInput,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _maybeAutofillSlug() {
    if (_slugTouched) return;
    final String generated = Validators.slugify(_title.text);
    if (_slug.text != generated) {
      _slug.text = generated;
      _slug.selection = TextSelection.collapsed(offset: _slug.text.length);
    }
  }

  void _hydrate(Project project) {
    _initial = project;
    _title.text = project.title;
    _slug.text = project.slug;
    _summary.text = project.summary;
    _description.text = project.description;
    _demoUrl.text = project.demoUrl ?? '';
    _repoUrl.text = project.repoUrl ?? '';
    _year.text = project.year ?? '';
    _technologies
      ..clear()
      ..addAll(project.technologies);
    _category = _categories.contains(project.category) ? project.category : _categories.first;
    _accent = _accents.contains(project.accentKey) ? project.accentKey! : _accents.first;
    _status = project.status;
    _featured = project.isFeatured;
    _sortOrder = project.sortOrder;
    _imagePath = project.imagePath;
    _slugTouched = true;
  }

  void _addTechnology([String? value]) {
    final String raw = (value ?? _techInput.text).trim();
    if (raw.isEmpty) return;
    final List<String> parts = raw.split(',').map((String p) => p.trim()).where((String p) => p.isNotEmpty).toList();
    setState(() {
      for (final String part in parts) {
        if (part.length > 24) continue;
        if (!_technologies.any((String t) => t.toLowerCase() == part.toLowerCase())) {
          _technologies.add(part);
        }
      }
      _techInput.clear();
    });
  }

  Future<void> _pickImage() async {
    if (!AppEnv.isConfigured) {
      Toast.error(context, 'Connect Supabase to upload images.');
      return;
    }
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        imageQuality: 82,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 6 * 1024 * 1024) {
        if (mounted) Toast.error(context, 'Please choose an image under 6 MB.');
        return;
      }
      setState(() {
        _uploading = true;
        _localImageBytes = bytes;
      });
      final String path = await ref.read(adminRepositoryProvider).uploadImage(
            bucket: StorageUrl.projectBucket,
            folder: 'projects',
            fileName: file.name,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() {
        _imagePath = path;
        _uploading = false;
      });
      Toast.success(context, 'Image uploaded');
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploading = false);
      Toast.error(context, ErrorMapper.map(error, fallback: 'Upload failed.').message);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      Haptics.error();
      return;
    }
    if (_technologies.isEmpty) {
      setState(() => _error = 'Add at least one technology so visitors can filter by stack.');
      return;
    }
    if (!AppEnv.isConfigured) {
      setState(() => _error = 'Admin changes need a Supabase project. Add your keys to .env first.');
      return;
    }

    final Project project = Project(
      id: _initial?.id ?? '',
      title: _title.text.trim(),
      slug: _slug.text.trim(),
      summary: _summary.text.trim(),
      description: _description.text.trim(),
      category: _category,
      technologies: List<String>.of(_technologies),
      status: _status,
      sortOrder: _sortOrder,
      imagePath: _imagePath,
      demoUrl: Sanitizer.cleanOptional(_demoUrl.text, maxLength: 500),
      repoUrl: Sanitizer.cleanOptional(_repoUrl.text, maxLength: 500),
      isFeatured: _featured,
      year: Sanitizer.cleanOptional(_year.text, maxLength: 12),
      accentKey: _accent,
      createdAt: _initial?.createdAt,
    );

    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).saveProject(project);
      if (!mounted) return;
      Haptics.success();
      invalidateAdminCaches(ref);
      ref.invalidate(portfolioProvider);
      Toast.success(context, _isNew ? 'Project created' : 'Project updated');
      context.pop();
    } catch (error) {
      if (!mounted) return;
      Haptics.error();
      setState(() {
        _saving = false;
        _error = ErrorMapper.map(error).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notFound) {
      return AdminScaffold(
        title: 'Project',
        child: EmptyStateView(
          title: 'Project not found',
          message: 'It may have been deleted from another device.',
          icon: Icons.folder_off_outlined,
          actionLabel: 'Back to projects',
          onAction: () => context.go(AppRoutes.adminProjects),
        ),
      );
    }
    if (!_initialised) {
      final AsyncValue<List<Project>> projects = ref.watch(adminProjectsProvider);
      if (projects.hasError) {
        return AdminScaffold(
          title: 'Project',
          child: ErrorStateView(
            error: projects.error!,
            onRetry: () => ref.invalidate(adminProjectsProvider),
          ),
        );
      }
      return const AdminScaffold(
        title: 'Project',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final double gutter = AppSpacing.gutter(context);

    return AdminScaffold(
      title: _isNew ? 'New project' : 'Edit project',
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ),
      ],
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 140),
          children: <Widget>[
            if (!AppEnv.isConfigured) const AdminOfflineNotice(),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Label('Cover image'),
                  const SizedBox(height: 10),
                  Stack(
                    children: <Widget>[
                      CoverImage(
                        imagePath: _localImageBytes == null ? _imagePath : null,
                        height: 168,
                        accent: AccentKey.resolve(_accent),
                      ),
                      if (_localImageBytes != null)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(_localImageBytes!, fit: BoxFit.cover),
                          ),
                        ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: PillButton(
                          label: _uploading ? 'Uploading…' : 'Change image',
                          icon: Icons.image_outlined,
                          tone: PillTone.accent,
                          onPressed: _uploading ? null : _pickImage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _imagePath == null || _imagePath!.isEmpty
                        ? 'No image yet — projects without an image get a gradient placeholder.'
                        : 'Stored in the project-images bucket.',
                    style: AppType.labelSmall(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Label('Basics'),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _title,
                    label: 'Title',
                    hint: 'Acme Mobile — Companion app',
                    maxLength: 90,
                    textCapitalization: TextCapitalization.words,
                    validator: (String? value) =>
                        Validators.requiredText(value, label: 'Title', max: 90),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _slug,
                    label: 'Slug (URL)',
                    hint: 'finpulse-fintech-wallet',
                    helper: 'Lowercase letters, numbers and dashes. Used in /projects/<slug>.',
                    onChanged: (_) => _slugTouched = true,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
                    ],
                    validator: Validators.slug,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _summary,
                    label: 'Summary',
                    hint: 'One or two lines shown on cards.',
                    maxLines: 2,
                    minLines: 2,
                    maxLength: 180,
                    showCounter: true,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (String? value) => Validators.message(value, min: 20, max: 180),
                  ),
                  const SizedBox(height: 12),
                  AppDropdown<String>(
                    label: 'Category',
                    value: _category,
                    items: _categories
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (String? value) => setState(() => _category = value ?? _category),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _year,
                    label: 'Year (optional)',
                    hint: '2026',
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    validator: (String? value) =>
                        (value ?? '').length > 12 ? 'Keep the year short.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Label('Description'),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _description,
                    label: 'Case study',
                    hint: 'Explain the problem, your approach and the outcome. Separate paragraphs with a blank line.',
                    maxLines: 10,
                    minLines: 6,
                    maxLength: 4000,
                    showCounter: true,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (String? value) => Validators.message(value, min: 40, max: 4000),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Label('Technology tags'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final String tech in _technologies)
                        InputChip(
                          label: Text(tech),
                          onDeleted: () => setState(() => _technologies.remove(tech)),
                          backgroundColor: AppColors.surfaceAlt,
                          side: const BorderSide(color: AppColors.border),
                          labelStyle: AppType.labelSmall(color: AppColors.textSecondary),
                          deleteIconColor: AppColors.textMuted,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _techInput,
                          style: AppType.bodyMedium(color: AppColors.textPrimary),
                          textInputAction: TextInputAction.done,
                          onSubmitted: _addTechnology,
                          decoration: const InputDecoration(
                            hintText: 'Add a technology',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Add technology',
                        onPressed: () => _addTechnology(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Label('Links'),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _demoUrl,
                    label: 'Live demo URL',
                    hint: 'https://…',
                    keyboardType: TextInputType.url,
                    prefixIcon: Icons.open_in_new_rounded,
                    validator: (String? value) => Validators.url(value),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _repoUrl,
                    label: 'Repository URL',
                    hint: 'https://github.com/…',
                    keyboardType: TextInputType.url,
                    prefixIcon: Icons.code_rounded,
                    validator: (String? value) => Validators.url(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Label('Publishing'),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _status == ProjectStatus.published,
                    onChanged: (bool value) => setState(
                      () => _status = value ? ProjectStatus.published : ProjectStatus.draft,
                    ),
                    title: Text('Published', style: AppType.titleLarge().copyWith(fontSize: 14.5)),
                    subtitle: Text(
                      'Published projects are visible to every visitor.',
                      style: AppType.labelSmall(color: AppColors.textMuted),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _featured,
                    onChanged: (bool value) => setState(() => _featured = value),
                    title: Text('Featured', style: AppType.titleLarge().copyWith(fontSize: 14.5)),
                    subtitle: Text(
                      'Featured projects appear on the Home screen.',
                      style: AppType.labelSmall(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppDropdown<String>(
                    label: 'Card accent',
                    value: _accent,
                    items: _accents
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value[0].toUpperCase() + value.substring(1)),
                            ))
                        .toList(),
                    onChanged: (String? value) => setState(() => _accent = value ?? _accent),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Sort order',
                          style: AppType.labelSmall(color: AppColors.textMuted),
                        ),
                      ),
                      IconButton(
                        onPressed: _sortOrder > 1
                            ? () => setState(() => _sortOrder--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Flexible(
                        child: Text(
                          '$_sortOrder',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppType.mono(size: 14, color: AppColors.textPrimary),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _sortOrder++),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              InlineErrorCard(message: _error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryActionButton(
              label: _isNew ? 'Create project' : 'Save changes',
              icon: Icons.check_rounded,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _saving ? null : () => context.pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppType.labelSmall(color: AppColors.textMuted));
  }
}
