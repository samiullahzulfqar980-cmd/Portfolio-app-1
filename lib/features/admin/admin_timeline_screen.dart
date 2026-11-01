import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/content_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../data/models/timeline_entry.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'admin_scaffold.dart';

class AdminTimelineScreen extends ConsumerStatefulWidget {
  const AdminTimelineScreen({super.key});

  @override
  ConsumerState<AdminTimelineScreen> createState() => _AdminTimelineScreenState();
}

class _AdminTimelineScreenState extends ConsumerState<AdminTimelineScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      invalidateAdminCaches(ref);
      ref.invalidate(portfolioProvider);
      if (success != null && mounted) Toast.success(context, success);
    } catch (error) {
      if (mounted) Toast.error(context, ErrorMapper.map(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(TimelineEntry? entry, List<TimelineEntry> existing) async {
    final TimelineEntry? result = await showModalBottomSheet<TimelineEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (BuildContext context) => _TimelineSheet(
        entry: entry,
        defaultOrder: existing.isEmpty
            ? 1
            : existing.map((TimelineEntry e) => e.sortOrder).reduce((int a, int b) => a > b ? a : b) + 1,
      ),
    );
    if (result == null) return;
    await _run(
      () => ref.read(adminRepositoryProvider).saveTimelineEntry(result),
      success: entry == null ? 'Entry added' : 'Entry updated',
    );
  }

  Future<void> _delete(TimelineEntry entry) async {
    final bool ok = await confirmDestructive(
      context,
      title: 'Delete entry?',
      message: '“${entry.role}” at ${entry.organization} will be removed.',
    );
    if (!ok) return;
    await _run(
      () => ref.read(adminRepositoryProvider).deleteTimelineEntry(entry.id),
      success: 'Entry deleted',
    );
  }

  Future<void> _move(List<TimelineEntry> entries, int index, int delta) async {
    final int target = index + delta;
    if (target < 0 || target >= entries.length) return;
    final List<TimelineEntry> reordered = List<TimelineEntry>.of(entries);
    final TimelineEntry item = reordered.removeAt(index);
    reordered.insert(target, item);
    await _run(
      () => ref.read(adminRepositoryProvider).reorderTimeline(
            <TimelineEntry>[
              for (int i = 0; i < reordered.length; i++) reordered[i].copyWith(sortOrder: i + 1),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TimelineEntry>> timeline = ref.watch(adminTimelineProvider);
    final double gutter = AppSpacing.gutter(context);

    return AdminScaffold(
      title: 'Timeline',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null, timeline.value ?? const <TimelineEntry>[]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add entry'),
      ),
      child: timeline.when(
        loading: () => const ListSkeleton(count: 4, height: 104),
        error: (Object error, StackTrace stack) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(adminTimelineProvider),
        ),
        data: (List<TimelineEntry> data) {
          if (data.isEmpty) {
            return EmptyStateView(
              title: 'Nothing here yet',
              message: 'Add your experience and education to populate the About and résumé screens.',
              icon: Icons.timeline_rounded,
              actionLabel: 'Add entry',
              onAction: () => _edit(null, data),
            );
          }
          final List<TimelineEntry> sorted = List<TimelineEntry>.of(data)
            ..sort((TimelineEntry a, TimelineEntry b) => a.sortOrder.compareTo(b.sortOrder));

          return ListView(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 140),
            children: <Widget>[
              for (final TimelineKind kind in TimelineKind.values) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    kind.label.toUpperCase(),
                    style: AppType.labelSmall(color: AppColors.textMuted),
                  ),
                ),
                if (sorted.where((TimelineEntry e) => e.kind == kind).isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'No ${kind.label.toLowerCase()} entries yet.',
                      style: AppType.bodySmall(color: AppColors.textMuted),
                    ),
                  ),
                for (final TimelineEntry entry in sorted.where((TimelineEntry e) => e.kind == kind))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () => _edit(entry, sorted),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  entry.role,
                                  style: AppType.titleLarge().copyWith(fontSize: 14.5),
                                ),
                              ),
                              StatusChip(
                                label: entry.period,
                                tone: kind == TimelineKind.education
                                    ? AppColors.accent
                                    : AppColors.primarySoft,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.location == null || entry.location!.isEmpty
                                ? entry.organization
                                : '${entry.organization} · ${entry.location}',
                            style: AppType.bodySmall(color: AppColors.textSecondary),
                          ),
                          if (entry.description != null && entry.description!.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            Text(
                              entry.description!,
                              style: AppType.bodySmall(color: AppColors.textMuted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            children: <Widget>[
                              AdminIconAction(
                                icon: Icons.keyboard_arrow_up_rounded,
                                tooltip: 'Move up',
                                onPressed: _busy || sorted.indexOf(entry) == 0
                                    ? null
                                    : () => _move(sorted, sorted.indexOf(entry), -1),
                              ),
                              AdminIconAction(
                                icon: Icons.keyboard_arrow_down_rounded,
                                tooltip: 'Move down',
                                onPressed: _busy || sorted.indexOf(entry) == sorted.length - 1
                                    ? null
                                    : () => _move(sorted, sorted.indexOf(entry), 1),
                              ),
                              const Spacer(),
                              AdminIconAction(
                                icon: Icons.edit_outlined,
                                tooltip: 'Edit',
                                onPressed: () => _edit(entry, sorted),
                              ),
                              AdminIconAction(
                                icon: Icons.delete_outline_rounded,
                                tooltip: 'Delete',
                                tone: AppColors.danger,
                                onPressed: _busy ? null : () => _delete(entry),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TimelineSheet extends StatefulWidget {
  const _TimelineSheet({this.entry, required this.defaultOrder});

  final TimelineEntry? entry;
  final int defaultOrder;

  @override
  State<_TimelineSheet> createState() => _TimelineSheetState();
}

class _TimelineSheetState extends State<_TimelineSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _organization =
      TextEditingController(text: widget.entry?.organization ?? '');
  late final TextEditingController _role = TextEditingController(text: widget.entry?.role ?? '');
  late final TextEditingController _start = TextEditingController(text: widget.entry?.startLabel ?? '');
  late final TextEditingController _end = TextEditingController(text: widget.entry?.endLabel ?? '');
  late final TextEditingController _location = TextEditingController(text: widget.entry?.location ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.entry?.description ?? '');
  late TimelineKind _kind = widget.entry?.kind ?? TimelineKind.experience;
  late bool _isCurrent = widget.entry?.isCurrent ?? false;

  @override
  void dispose() {
    _organization.dispose();
    _role.dispose();
    _start.dispose();
    _end.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final TimelineEntry result = TimelineEntry(
      id: widget.entry?.id ?? '',
      kind: _kind,
      organization: Sanitizer.clean(_organization.text, maxLength: 80),
      role: Sanitizer.clean(_role.text, maxLength: 80),
      startLabel: Sanitizer.clean(_start.text, maxLength: 20),
      endLabel: _isCurrent ? null : Sanitizer.cleanOptional(_end.text, maxLength: 20),
      isCurrent: _isCurrent,
      description: Sanitizer.multiline(_description.text, maxLength: 400),
      location: Sanitizer.cleanOptional(_location.text, maxLength: 60),
      sortOrder: widget.entry?.sortOrder ?? widget.defaultOrder,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.entry == null ? 'Add entry' : 'Edit entry',
                style: AppType.headlineMedium(),
              ),
              const SizedBox(height: 14),
              SegmentedButton<TimelineKind>(
                segments: const <ButtonSegment<TimelineKind>>[
                  ButtonSegment<TimelineKind>(
                    value: TimelineKind.experience,
                    label: Text('Experience'),
                  ),
                  ButtonSegment<TimelineKind>(
                    value: TimelineKind.education,
                    label: Text('Education'),
                  ),
                ],
                selected: <TimelineKind>{_kind},
                onSelectionChanged: (Set<TimelineKind> values) =>
                    setState(() => _kind = values.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary.withValues(alpha: 0.24);
                    }
                    return AppColors.surfaceAlt;
                  }),
                  side: const WidgetStatePropertyAll<BorderSide>(
                    BorderSide(color: AppColors.border),
                  ),
                  textStyle: WidgetStatePropertyAll<TextStyle>(
                    AppType.labelSmall(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _role,
                label: _kind == TimelineKind.education ? 'Qualification' : 'Role',
                hint: _kind == TimelineKind.education ? 'BS Computer Science' : 'Mobile Developer',
                maxLength: 80,
                validator: (String? value) =>
                    Validators.requiredText(value, label: 'Role', max: 80),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _organization,
                label: _kind == TimelineKind.education ? 'Institution' : 'Company',
                maxLength: 80,
                validator: (String? value) =>
                    Validators.requiredText(value, label: 'Organization', max: 80),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _start,
                      label: 'Start',
                      hint: '2024',
                      maxLength: 20,
                      validator: (String? value) =>
                          Validators.requiredText(value, label: 'Start date', max: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      controller: _end,
                      label: 'End',
                      hint: '2025',
                      maxLength: 20,
                      enabled: !_isCurrent,
                      validator: (String? value) {
                        if (_isCurrent) return null;
                        return Validators.requiredText(value, label: 'End date', max: 20);
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isCurrent,
                onChanged: (bool value) => setState(() => _isCurrent = value),
                title: Text('Current', style: AppType.bodyMedium(color: AppColors.textPrimary)),
                subtitle: Text(
                  'Shows “Present” instead of an end date.',
                  style: AppType.labelSmall(color: AppColors.textMuted),
                ),
              ),
              AppTextField(
                controller: _location,
                label: 'Location (optional)',
                hint: 'Remote, Islamabad',
                maxLength: 60,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _description,
                label: 'Description (optional)',
                hint: 'What you did and the impact.',
                maxLines: 4,
                minLines: 3,
                maxLength: 400,
                showCounter: true,
              ),
              const SizedBox(height: 16),
              PrimaryActionButton(
                label: widget.entry == null ? 'Add entry' : 'Save changes',
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
