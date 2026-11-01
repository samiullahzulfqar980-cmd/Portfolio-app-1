import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/config/app_env.dart';
import '../../core/errors/app_failure.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/contact_message.dart';
import '../../data/models/project.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'admin_scaffold.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String email = ref.watch(authUserProvider).value?.email ?? '';
    final AsyncValue<List<Project>> projects = ref.watch(adminProjectsProvider);
    final AsyncValue<Map<String, int>> counts = ref.watch(messageCountsProvider);
    final AsyncValue<List<ContactMessage>> messages = ref.watch(adminMessagesProvider);
    final double gutter = AppSpacing.gutter(context);

    return AdminScaffold(
      title: 'Dashboard',
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: RoundIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Sign out',
            onPressed: () async {
              final bool ok = await confirmDestructive(
                context,
                title: 'Sign out?',
                message: 'You will need your email and password to manage content again.',
                confirmLabel: 'Sign out',
              );
              if (!ok) return;
              try {
                await ref.read(authControllerProvider).signOut();
                if (context.mounted) context.go(AppRoutes.home);
              } on AppFailure catch (failure) {
                if (context.mounted) Toast.error(context, failure.message);
              }
            },
          ),
        ),
      ],
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          invalidateAdminCaches(ref);
          await ref.read(adminProjectsProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 120),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: <Widget>[
            if (!AppEnv.isConfigured) const AdminOfflineNotice(),
            Text(
              'Signed in as',
              style: AppType.labelSmall(color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(email, style: AppType.titleLarge()),
            const SizedBox(height: AppSpacing.lg),
            _StatsRow(projects: projects, counts: counts),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(eyebrow: 'Manage', title: 'Content'),
            _ActionGrid(
              actions: <_AdminAction>[
                _AdminAction(
                  icon: Icons.grid_view_rounded,
                  label: 'Projects',
                  detail: projects.value == null
                      ? ''
                      : '${projects.value!.length} total',
                  route: AppRoutes.adminProjects,
                ),
                _AdminAction(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  detail: 'Bio, links, résumé',
                  route: AppRoutes.adminProfile,
                ),
                _AdminAction(
                  icon: Icons.bolt_rounded,
                  label: 'Skills',
                  detail: 'Groups & levels',
                  route: AppRoutes.adminSkills,
                ),
                _AdminAction(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Services',
                  detail: 'Offers & icons',
                  route: AppRoutes.adminServices,
                ),
                _AdminAction(
                  icon: Icons.timeline_rounded,
                  label: 'Timeline',
                  detail: 'Experience & education',
                  route: AppRoutes.adminTimeline,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              eyebrow: 'Inbox',
              title: 'Recent inquiries',
              actionLabel: 'Open inbox',
              onAction: () => context.push(AppRoutes.adminMessages),
            ),
            messages.when(
              loading: () => const Skeleton(height: 150),
              error: (Object error, StackTrace stack) => InlineErrorCard(
                message: ErrorMapper.map(error).message,
                onRetry: () => ref.invalidate(adminMessagesProvider),
              ),
              data: (List<ContactMessage> data) {
                if (data.isEmpty) {
                  return const EmptyStateView(
                    title: 'No inquiries yet',
                    message: 'Messages sent from the Contact tab will appear here.',
                    icon: Icons.inbox_rounded,
                    compact: true,
                  );
                }
                return Column(
                  children: <Widget>[
                    for (final ContactMessage message in data.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => context.push(AppRoutes.adminMessage(message.id)),
                          child: Row(
                            children: <Widget>[
                              _StatusDot(status: message.status),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      message.name,
                                      style: AppType.labelLarge(color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      message.subject ?? message.message,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppType.bodySmall(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Formatters.relative(message.createdAt),
                                style: AppType.mono(size: 10.5, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Visitor view', style: AppType.titleLarge()),
                  const SizedBox(height: 4),
                  Text(
                    'Check how the portfolio looks to everyone else after making changes.',
                    style: AppType.bodySmall(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  SecondaryActionButton(
                    label: 'Open public home',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.projects, required this.counts});

  final AsyncValue<List<Project>> projects;
  final AsyncValue<Map<String, int>> counts;

  @override
  Widget build(BuildContext context) {
    final int total = projects.value?.length ?? 0;
    final int published = projects.value?.where((Project p) => p.isPublished).length ?? 0;
    final int drafts = total - published;
    final int unread = counts.value?['unread'] ?? 0;

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(label: 'Published', value: '$published', icon: Icons.public_rounded, tone: AppColors.success),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(label: 'Drafts', value: '$drafts', icon: Icons.drafts_outlined, tone: AppColors.warning),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(label: 'Unread', value: '$unread', icon: Icons.mark_email_unread_outlined, tone: AppColors.accent),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 17, color: tone),
          const SizedBox(height: 10),
          Text(value, style: AppType.headlineLarge()),
          const SizedBox(height: 2),
          Text(label, style: AppType.labelSmall(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_AdminAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gap = 10;
        final double width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: actions
              .map(
                (_AdminAction action) => SizedBox(
                  width: width,
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => context.push(action.route),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(action.icon, size: 20, color: AppColors.accentSoft),
                        const SizedBox(height: 12),
                        Text(action.label, style: AppType.titleLarge().copyWith(fontSize: 14.5)),
                        const SizedBox(height: 2),
                        Text(
                          action.detail,
                          style: AppType.labelSmall(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final Color tone = switch (status) {
      MessageStatus.unread => AppColors.accent,
      MessageStatus.read => AppColors.textMuted,
      MessageStatus.replied => AppColors.success,
      MessageStatus.archived => AppColors.textMuted,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
    );
  }
}

class _AdminAction {
  const _AdminAction({
    required this.icon,
    required this.label,
    required this.detail,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String detail;
  final String route;
}
