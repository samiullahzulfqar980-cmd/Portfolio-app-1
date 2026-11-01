import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/motion/motion.dart';
import '../../core/platform/launcher_service.dart';
import '../../core/providers/content_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/project.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Project?> project = ref.watch(projectBySlugProvider(slug));

    return project.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const AppBackground(child: ListSkeleton(count: 2, height: 190)),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: AppBackground(
          child: ErrorStateView(
            error: error,
            onRetry: () => ref.invalidate(projectBySlugProvider(slug)),
          ),
        ),
      ),
      data: (Project? value) {
        if (value == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: AppBackground(
              child: EmptyStateView(
                title: 'Project not found',
                message: 'It may have been unpublished or the link changed.',
                icon: Icons.folder_off_outlined,
                actionLabel: 'Back to projects',
                onAction: () => context.go(AppRoutes.projects),
              ),
            ),
          );
        }
        return _ProjectDetailBody(project: value);
      },
    );
  }
}

class _ProjectDetailBody extends StatelessWidget {
  const _ProjectDetailBody({required this.project});

  final Project project;

  Future<void> _open(BuildContext context, String? url, {String? missing}) async {
    if (url == null || url.trim().isEmpty) {
      Toast.show(context, missing ?? 'No link provided for this project.');
      return;
    }
    try {
      await const LauncherService().openUrl(url);
    } on AppFailure catch (failure) {
      if (context.mounted) Toast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = AccentKey.resolve(project.accentKey);
    final double gutter = AppSpacing.gutter(context);
    final List<String> paragraphs = project.description
        .split(RegExp(r'\n\s*\n'))
        .map((String p) => p.trim())
        .where((String p) => p.isNotEmpty)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 260,
              backgroundColor: AppColors.background.withValues(alpha: 0.9),
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Center(
                  child: RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.projects),
                  ),
                ),
              ),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: RoundIconButton(
                    icon: Icons.ios_share_rounded,
                    tooltip: 'Copy project link',
                    onPressed: () async {
                      final String shareText = project.demoUrl?.isNotEmpty == true
                          ? project.demoUrl!
                          : (project.repoUrl?.isNotEmpty == true
                              ? project.repoUrl!
                              : '${project.title} — ${project.summary}');
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (context.mounted) Toast.success(context, 'Link copied to clipboard');
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CoverImage(
                      imagePath: project.imagePath,
                      height: 260,
                      accent: accent,
                      borderRadius: BorderRadius.zero,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 120,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              AppColors.background.withValues(alpha: 0),
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  AnimatedEntry(
                    index: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(child: TagChip(label: project.category, selected: true)),
                            if (project.year != null) ...<Widget>[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  project.year!,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.mono(size: 11.5, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                            if (!project.isPublished) ...<Widget>[
                              const SizedBox(width: 8),
                              const StatusChip(label: 'Draft', tone: AppColors.warning),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          project.title,
                          style: AppType.displayMedium(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          project.summary,
                          style: AppType.bodyLarge(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedEntry(
                    index: 1,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: PrimaryActionButton(
                            label: 'Live demo',
                            icon: Icons.open_in_new_rounded,
                            onPressed: () => _open(
                              context,
                              project.demoUrl,
                              missing: 'No live demo is linked for this project.',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SecondaryActionButton(
                            label: 'Source',
                            icon: Icons.code_rounded,
                            onPressed: () => _open(
                              context,
                              project.repoUrl,
                              missing: 'This project is not open source.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedEntry(
                    index: 2,
                    child: SectionHeader(
                      eyebrow: 'Overview',
                      title: 'Inside the build',
                      padding: const EdgeInsets.only(bottom: 10),
                    ),
                  ),
                  AnimatedEntry(
                    index: 3,
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (paragraphs.isEmpty)
                            Text(
                              'More detail will be added soon.',
                              style: AppType.bodyMedium(color: AppColors.textMuted),
                            )
                          else
                            for (int i = 0; i < paragraphs.length; i++) ...<Widget>[
                              Text(
                                paragraphs[i],
                                style: AppType.bodyMedium(color: AppColors.textSecondary),
                              ),
                              if (i != paragraphs.length - 1) const SizedBox(height: 14),
                            ],
                        ],
                      ),
                    ),
                  ),
                  if (project.technologies.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    AnimatedEntry(
                      index: 4,
                      child: SectionHeader(
                        eyebrow: 'Stack',
                        title: 'Built with',
                        padding: const EdgeInsets.only(bottom: 10),
                      ),
                    ),
                    AnimatedEntry(
                      index: 5,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: project.technologies
                            .map((String tech) => TagChip(label: tech, icon: Icons.bolt_rounded))
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedEntry(
                    index: 6,
                    child: GradientBorderCard(
                      onTap: () => context.go(AppRoutes.contact),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Need something similar?', style: AppType.headlineMedium()),
                          const SizedBox(height: 6),
                          Text(
                            'I can scope a build like this for your product — send a short brief and I will reply with next steps.',
                            style: AppType.bodySmall(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  'Start a conversation',
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.labelSmall(color: AppColors.accentSoft)
                                      .copyWith(fontSize: 12.5),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accentSoft),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
