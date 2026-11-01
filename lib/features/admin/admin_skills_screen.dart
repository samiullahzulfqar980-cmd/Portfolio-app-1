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
import '../../data/models/skill.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'admin_scaffold.dart';

class AdminSkillsScreen extends ConsumerStatefulWidget {
  const AdminSkillsScreen({super.key});

  @override
  ConsumerState<AdminSkillsScreen> createState() => _AdminSkillsScreenState();
}

class _AdminSkillsScreenState extends ConsumerState<AdminSkillsScreen> {
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

  Future<void> _edit(Skill? skill, List<Skill> existing) async {
    final Skill? result = await showModalBottomSheet<Skill>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (BuildContext context) => _SkillSheet(
        skill: skill,
        defaultOrder: existing.isEmpty
            ? 1
            : existing.map((Skill s) => s.sortOrder).reduce((int a, int b) => a > b ? a : b) + 1,
      ),
    );
    if (result == null) return;
    await _run(
      () => ref.read(adminRepositoryProvider).saveSkill(result),
      success: skill == null ? 'Skill added' : 'Skill updated',
    );
  }

  Future<void> _delete(Skill skill) async {
    final bool ok = await confirmDestructive(
      context,
      title: 'Delete skill?',
      message: '“${skill.name}” will be removed from your About page.',
    );
    if (!ok) return;
    await _run(() => ref.read(adminRepositoryProvider).deleteSkill(skill.id), success: 'Skill deleted');
  }

  Future<void> _move(List<Skill> skills, int index, int delta) async {
    final int target = index + delta;
    if (target < 0 || target >= skills.length) return;
    final List<Skill> reordered = List<Skill>.of(skills);
    final Skill item = reordered.removeAt(index);
    reordered.insert(target, item);
    await _run(
      () => ref.read(adminRepositoryProvider).reorderSkills(
            <Skill>[
              for (int i = 0; i < reordered.length; i++) reordered[i].copyWith(sortOrder: i + 1),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Skill>> skills = ref.watch(adminSkillsProvider);
    final double gutter = AppSpacing.gutter(context);

    return AdminScaffold(
      title: 'Skills',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null, skills.value ?? const <Skill>[]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add skill'),
      ),
      child: skills.when(
        loading: () => const ListSkeleton(count: 5, height: 74),
        error: (Object error, StackTrace stack) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(adminSkillsProvider),
        ),
        data: (List<Skill> data) {
          if (data.isEmpty) {
            return EmptyStateView(
              title: 'No skills yet',
              message: 'Add skills to build the toolkit section on your About page.',
              icon: Icons.bolt_rounded,
              actionLabel: 'Add skill',
              onAction: () => _edit(null, data),
            );
          }
          final List<Skill> sorted = List<Skill>.of(data)
            ..sort((Skill a, Skill b) => a.sortOrder.compareTo(b.sortOrder));
          final Map<String, List<Skill>> grouped = groupSkills(sorted);

          return ListView(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 140),
            children: <Widget>[
              for (final String category in grouped.keys) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 6),
                  child: Text(category.toUpperCase(), style: AppType.labelSmall(color: AppColors.textMuted)),
                ),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    children: <Widget>[
                      for (final Skill skill in grouped[category]!) ...<Widget>[
                        _SkillRow(
                          skill: skill,
                          index: sorted.indexOf(skill),
                          total: sorted.length,
                          busy: _busy,
                          onEdit: () => _edit(skill, sorted),
                          onDelete: () => _delete(skill),
                          onMove: (int delta) => _move(sorted, sorted.indexOf(skill), delta),
                        ),
                        if (skill != grouped[category]!.last) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.skill,
    required this.index,
    required this.total,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  final Skill skill;
  final int index;
  final int total;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        skill.name,
                        style: AppType.bodyMedium(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text('${skill.proficiency}%', style: AppType.mono(size: 11, color: AppColors.textMuted)),
                  ],
                ),
                if (skill.note != null && skill.note!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(skill.note!, style: AppType.labelSmall(color: AppColors.textMuted)),
                ],
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: skill.proficiency / 100,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          AdminIconAction(
            icon: Icons.keyboard_arrow_up_rounded,
            tooltip: 'Move up',
            onPressed: busy || index == 0 ? null : () => onMove(-1),
          ),
          AdminIconAction(
            icon: Icons.keyboard_arrow_down_rounded,
            tooltip: 'Move down',
            onPressed: busy || index == total - 1 ? null : () => onMove(1),
          ),
          AdminIconAction(icon: Icons.edit_outlined, tooltip: 'Edit', onPressed: busy ? null : onEdit),
          AdminIconAction(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete',
            tone: AppColors.danger,
            onPressed: busy ? null : onDelete,
          ),
        ],
      ),
    );
  }
}

class _SkillSheet extends StatefulWidget {
  const _SkillSheet({this.skill, required this.defaultOrder});

  final Skill? skill;
  final int defaultOrder;

  @override
  State<_SkillSheet> createState() => _SkillSheetState();
}

class _SkillSheetState extends State<_SkillSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.skill?.name ?? '');
  late final TextEditingController _category =
      TextEditingController(text: widget.skill?.category ?? 'Mobile');
  late final TextEditingController _note = TextEditingController(text: widget.skill?.note ?? '');
  late double _proficiency = (widget.skill?.proficiency ?? 75).toDouble();

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Skill result = Skill(
      id: widget.skill?.id ?? '',
      name: Sanitizer.clean(_name.text, maxLength: 40),
      category: Sanitizer.clean(_category.text, maxLength: 40),
      proficiency: _proficiency.round().clamp(0, 100).toInt(),
      sortOrder: widget.skill?.sortOrder ?? widget.defaultOrder,
      note: Sanitizer.cleanOptional(_note.text, maxLength: 80),
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
              Text(widget.skill == null ? 'Add skill' : 'Edit skill', style: AppType.headlineMedium()),
              const SizedBox(height: 16),
              AppTextField(
                controller: _name,
                label: 'Skill',
                hint: 'Flutter & Dart',
                maxLength: 40,
                validator: (String? value) => Validators.requiredText(value, label: 'Skill', max: 40),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _category,
                label: 'Category',
                hint: 'Mobile, Web, Backend & Data…',
                maxLength: 40,
                helper: 'Skills with the same category are grouped together.',
                validator: (String? value) =>
                    Validators.requiredText(value, label: 'Category', max: 40),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _note,
                label: 'Note (optional)',
                hint: 'Riverpod, native channels',
                maxLength: 80,
              ),
              const SizedBox(height: 16),
              Text('PROFICIENCY — ${_proficiency.round()}%',
                  style: AppType.labelSmall(color: AppColors.textMuted)),
              Slider(
                value: _proficiency,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${_proficiency.round()}%',
                activeColor: AppColors.accent,
                onChanged: (double value) => setState(() => _proficiency = value),
              ),
              const SizedBox(height: 8),
              PrimaryActionButton(
                label: widget.skill == null ? 'Add skill' : 'Save changes',
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
