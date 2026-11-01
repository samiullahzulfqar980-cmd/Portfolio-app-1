import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/content_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/service.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'admin_scaffold.dart';

class AdminServicesScreen extends ConsumerStatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  ConsumerState<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends ConsumerState<AdminServicesScreen> {
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

  Future<void> _edit(Service? service, List<Service> existing) async {
    final Service? result = await showModalBottomSheet<Service>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (BuildContext context) => _ServiceSheet(
        service: service,
        defaultOrder: existing.isEmpty
            ? 1
            : existing.map((Service s) => s.sortOrder).reduce((int a, int b) => a > b ? a : b) + 1,
      ),
    );
    if (result == null) return;
    await _run(
      () => ref.read(adminRepositoryProvider).saveService(result),
      success: service == null ? 'Service added' : 'Service updated',
    );
  }

  Future<void> _delete(Service service) async {
    final bool ok = await confirmDestructive(
      context,
      title: 'Delete service?',
      message: '“${service.title}” will be removed from the portfolio.',
    );
    if (!ok) return;
    await _run(
      () => ref.read(adminRepositoryProvider).deleteService(service.id),
      success: 'Service deleted',
    );
  }

  Future<void> _togglePublished(Service service) async {
    await _run(
      () => ref.read(adminRepositoryProvider).saveService(
            service.copyWith(isPublished: !service.isPublished),
          ),
      success: service.isPublished ? 'Hidden from visitors' : 'Published',
    );
  }

  Future<void> _move(List<Service> services, int index, int delta) async {
    final int target = index + delta;
    if (target < 0 || target >= services.length) return;
    final List<Service> reordered = List<Service>.of(services);
    final Service item = reordered.removeAt(index);
    reordered.insert(target, item);
    await _run(
      () => ref.read(adminRepositoryProvider).reorderServices(
            <Service>[
              for (int i = 0; i < reordered.length; i++) reordered[i].copyWith(sortOrder: i + 1),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Service>> services = ref.watch(adminServicesProvider);
    final double gutter = AppSpacing.gutter(context);

    return AdminScaffold(
      title: 'Services',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null, services.value ?? const <Service>[]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add service'),
      ),
      child: services.when(
        loading: () => const ListSkeleton(count: 4, height: 118),
        error: (Object error, StackTrace stack) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(adminServicesProvider),
        ),
        data: (List<Service> data) {
          if (data.isEmpty) {
            return EmptyStateView(
              title: 'No services yet',
              message: 'Describe what you offer. These cards appear on Home and About.',
              icon: Icons.auto_awesome_rounded,
              actionLabel: 'Add service',
              onAction: () => _edit(null, data),
            );
          }
          final List<Service> sorted = List<Service>.of(data)
            ..sort((Service a, Service b) => a.sortOrder.compareTo(b.sortOrder));
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 140),
            itemCount: sorted.length,
            itemBuilder: (BuildContext context, int index) {
              final Service service = sorted[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => _edit(service, sorted),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              color: AppColors.primary.withValues(alpha: 0.16),
                            ),
                            child: Icon(
                              IconKeys.resolve(service.iconKey),
                              size: 18,
                              color: AppColors.accentSoft,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              service.title,
                              style: AppType.titleLarge().copyWith(fontSize: 14.5),
                            ),
                          ),
                          StatusChip(
                            label: service.isPublished ? 'Live' : 'Hidden',
                            tone: service.isPublished ? AppColors.success : AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.description,
                        style: AppType.bodySmall(color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (service.technologies.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: service.technologies
                              .take(4)
                              .map((String tech) => TagChip(label: tech))
                              .toList(),
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        children: <Widget>[
                          AdminIconAction(
                            icon: Icons.keyboard_arrow_up_rounded,
                            tooltip: 'Move up',
                            onPressed: _busy || index == 0 ? null : () => _move(sorted, index, -1),
                          ),
                          AdminIconAction(
                            icon: Icons.keyboard_arrow_down_rounded,
                            tooltip: 'Move down',
                            onPressed: _busy || index == sorted.length - 1
                                ? null
                                : () => _move(sorted, index, 1),
                          ),
                          const Spacer(),
                          AdminIconAction(
                            icon: service.isPublished
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            tooltip: service.isPublished ? 'Hide' : 'Publish',
                            tone: AppColors.accent,
                            onPressed: _busy ? null : () => _togglePublished(service),
                          ),
                          AdminIconAction(
                            icon: Icons.edit_outlined,
                            tooltip: 'Edit',
                            onPressed: () => _edit(service, sorted),
                          ),
                          AdminIconAction(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Delete',
                            tone: AppColors.danger,
                            onPressed: _busy ? null : () => _delete(service),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ServiceSheet extends StatefulWidget {
  const _ServiceSheet({this.service, required this.defaultOrder});

  final Service? service;
  final int defaultOrder;

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(text: widget.service?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.service?.description ?? '');
  late final TextEditingController _technologies =
      TextEditingController(text: widget.service?.technologies.join(', ') ?? '');
  late String _iconKey = widget.service?.iconKey ?? IconKeys.keys.first;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _technologies.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Service result = Service(
      id: widget.service?.id ?? '',
      title: Sanitizer.clean(_title.text, maxLength: 60),
      description: Sanitizer.multiline(_description.text, maxLength: 300),
      iconKey: _iconKey,
      sortOrder: widget.service?.sortOrder ?? widget.defaultOrder,
      technologies: _technologies.text
          .split(',')
          .map((String t) => Sanitizer.clean(t, maxLength: 24))
          .where((String t) => t.isNotEmpty)
          .toList(),
      isPublished: widget.service?.isPublished ?? true,
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
                widget.service == null ? 'Add service' : 'Edit service',
                style: AppType.headlineMedium(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _title,
                label: 'Title',
                hint: 'Cross-platform mobile apps',
                maxLength: 60,
                validator: (String? value) => Validators.requiredText(value, label: 'Title', max: 60),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _description,
                label: 'Description',
                hint: 'What you deliver and for whom.',
                maxLines: 4,
                minLines: 3,
                maxLength: 300,
                showCounter: true,
                validator: (String? value) => Validators.message(value, min: 20, max: 300),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _technologies,
                label: 'Tags (comma separated)',
                hint: 'Flutter, React Native',
                maxLength: 120,
              ),
              const SizedBox(height: 12),
              Text('ICON', style: AppType.labelSmall(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IconKeys.keys.map((String key) {
                  final bool selected = key == _iconKey;
                  return InkWell(
                    onTap: () => setState(() => _iconKey = key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        IconKeys.resolve(key),
                        size: 19,
                        color: selected ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: widget.service == null ? 'Add service' : 'Save changes',
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
