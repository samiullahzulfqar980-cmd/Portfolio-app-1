import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/content_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/project.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'admin_scaffold.dart';

/// Full project management: create, edit, publish/unpublish, feature, reorder
/// and delete.
class AdminProjectsScreen extends ConsumerStatefulWidget {
  const AdminProjectsScreen({super.key});

  @override
  ConsumerState<AdminProjectsScreen> createState() => _AdminProjectsScreenState();
}

class _AdminProjectsScreenState extends ConsumerState<AdminProjectsScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      invalidateAdminCaches(ref);
      ref.invalidate(portfolioProvider);
      if (success != null && mounted) Toast.success(context, success);
    } catch (error) {
      if (mounted) Toast.error(context, ErrorMapper.map(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleStatus(Project project) async {
    final ProjectStatus next =
        project.isPublished ? ProjectStatus.draft : ProjectStatus.published;
    await _run(
      () => ref.read(adminRepositoryProvider).setProjectStatus(project, next),
      success: next == ProjectStatus.published ? 'Published' : 'Moved back to drafts',
    );
  }

  Future<void> _toggleFeatured(Project project) async {
    await _run(
      () => ref.read(adminRepositoryProvider).setProjectFeatured(project, !project.isFeatured),
      success: project.isFeatured ? 'Removed from featured' : 'Added to featured',
    );
  }

  Future<void> _delete(Project project) async {
    final bool ok = await confirmDestructive(
      context,
      title: 'Delete project?',
      message: '“${project.title}” will be permanently removed, including its public page.',
    );
    if (!ok) return;
    await _run(
      () => ref.read(adminRepositoryProvider).deleteProject(project.id),
      success: 'Project deleted',
    );
  }

  Future<void> _move(List<Project> projects, int index, int delta) async {
    final int target = index + delta;
    if (target < 0 || target >= projects.length) return;
    final List<Project> reordered = List<Project>.of(projects);
    final Project item = reordered.removeAt(index);
    reordered.insert(target, item);
    final List<Project> withOrder = <Project>[
      for (int i = 0; i < reordered.length; i++) reordered[i].copyWith(sortOrder: i + 1),
    ];
    await _run(() => ref.read(adminRepositoryProvider).reorderProjects(withOrder));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Project>> projects = ref.watch(adminProjectsProvider);
    final double gutter = AppSpacing.gutter(context);

    return AdminScaffold(
      title: 'Projects',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminProjectNew),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New project'),
      ),
      child: Stack(
        children: <Widget>[
          projects.when(
            loading: () => const ListSkeleton(count: 3, height: 132),
            error: (Object error, StackTrace stack) => ErrorStateView(
              error: error,
              onRetry: () => ref.invalidate(adminProjectsProvider),
            ),
            data: (List<Project> data) {
              if (data.isEmpty) {
                return EmptyStateView(
                  title: 'No projects yet',
                  message: 'Create your first project — it stays a draft until you publish it.',
                  icon: Icons.grid_view_rounded,
                  actionLabel: 'New project',
                  onAction: () => context.push(AppRoutes.adminProjectNew),
                );
              }
              final List<Project> sorted = List<Project>.of(data)
                ..sort((Project a, Project b) => a.sortOrder.compareTo(b.sortOrder));
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 120),
                itemCount: sorted.length,
                itemBuilder: (BuildContext context, int index) {
                  final Project project = sorted[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => context.push(
                        AppRoutes.adminProjectEditPath(project.id),
                        extra: project,
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 66,
                                child: CoverImage(
                                  imagePath: project.imagePath,
                                  height: 66,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      project.title,
                                      style: AppType.titleLarge().copyWith(fontSize: 14.5),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: <Widget>[
                                        StatusChip(
                                          label: project.status.label,
                                          tone: project.isPublished
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                        const SizedBox(width: 6),
                                        if (project.isFeatured)
                                          const StatusChip(
                                            label: 'Featured',
                                            tone: AppColors.accent,
                                          ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            project.category,
                                            style: AppType.labelSmall(color: AppColors.textMuted),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Divider(height: 12),
                          Row(
                            children: <Widget>[
                              AdminIconAction(
                                icon: Icons.keyboard_arrow_up_rounded,
                                tooltip: 'Move up',
                                onPressed: index == 0 ? null : () => _move(sorted, index, -1),
                              ),
                              AdminIconAction(
                                icon: Icons.keyboard_arrow_down_rounded,
                                tooltip: 'Move down',
                                onPressed:
                                    index == sorted.length - 1 ? null : () => _move(sorted, index, 1),
                              ),
                              const Spacer(),
                              AdminIconAction(
                                icon: project.isFeatured
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                tooltip: project.isFeatured
                                    ? 'Remove from featured'
                                    : 'Mark as featured',
                                tone: AppColors.warm,
                                onPressed: _busy ? null : () => _toggleFeatured(project),
                              ),
                              AdminIconAction(
                                icon: project.isPublished
                                    ? Icons.visibility_off_outlined
                                    : Icons.publish_rounded,
                                tooltip: project.isPublished ? 'Unpublish' : 'Publish',
                                tone: AppColors.accent,
                                onPressed: _busy ? null : () => _toggleStatus(project),
                              ),
                              AdminIconAction(
                                icon: Icons.edit_outlined,
                                tooltip: 'Edit',
                                onPressed: () => context.push(
                                  AppRoutes.adminProjectEditPath(project.id),
                                  extra: project,
                                ),
                              ),
                              AdminIconAction(
                                icon: Icons.delete_outline_rounded,
                                tooltip: 'Delete',
                                tone: AppColors.danger,
                                onPressed: _busy ? null : () => _delete(project),
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
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
