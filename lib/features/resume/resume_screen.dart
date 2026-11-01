import 'package:flutter/material.dart';
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
import '../../core/utils/storage_urls.dart';
import '../../data/models/app_profile.dart';
import '../../data/models/portfolio_data.dart';
import '../../data/models/skill.dart';
import '../../data/models/timeline_entry.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/info_tiles.dart';
import '../../shared/widgets/state_views.dart';

/// In-app résumé summary plus an "open the PDF" action backed by Supabase
/// Storage. The PDF is never bundled, so the owner can update it without a
/// store release.
class ResumeScreen extends ConsumerWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PortfolioData> portfolio = ref.watch(portfolioProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Résumé', style: AppType.headlineMedium()),
        backgroundColor: AppColors.background.withValues(alpha: 0.92),
      ),
      body: AppBackground(
        child: portfolio.when(
          loading: () => const ListSkeleton(count: 3, height: 170),
          error: (Object error, StackTrace stack) => ErrorStateView(
            error: error,
            onRetry: () => ref.read(portfolioProvider.notifier).refresh(),
          ),
          data: (PortfolioData data) => _ResumeBody(data: data),
        ),
      ),
    );
  }
}

class _ResumeBody extends StatelessWidget {
  const _ResumeBody({required this.data});

  final PortfolioData data;

  Future<void> _openPdf(BuildContext context) async {
    try {
      await const LauncherService().openResume(data.profile.resumePath);
    } on AppFailure catch (failure) {
      if (context.mounted) {
        Toast.show(
          context,
          failure.message,
          tone: ToastTone.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppProfile profile = data.profile;
    final double gutter = AppSpacing.gutter(context);
    final List<TimelineEntry> experience = data.experience;
    final List<TimelineEntry> education = data.education;
    final Map<String, List<Skill>> skills = groupSkills(data.skills);

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 120),
      children: <Widget>[
        AnimatedEntry(
          index: 0,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppAvatar(
                      imagePath: profile.avatarPath,
                      name: profile.fullName,
                      size: 62,
                      showRing: false,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(profile.fullName, style: AppType.headlineMedium()),
                          const SizedBox(height: 3),
                          Text(
                            profile.roles.join(' · '),
                            style: AppType.bodySmall(color: AppColors.accentSoft),
                          ),
                          if (profile.location != null) ...<Widget>[
                            const SizedBox(height: 6),
                            Text(
                              profile.location!,
                              style: AppType.labelSmall(color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PrimaryActionButton(
                        label: 'Open PDF',
                        icon: Icons.picture_as_pdf_outlined,
                        onPressed: () => _openPdf(context),
                      ),
                    ),
                  ],
                ),
                if (profile.resumePath == null || profile.resumePath!.isEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'No PDF uploaded yet. This summary is generated from your portfolio content.',
                          style: AppType.bodySmall(color: AppColors.warning).copyWith(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedEntry(
          index: 1,
          child: _Block(
            title: 'Profile',
            child: Text(profile.bio.split('\n\n').first, style: AppType.bodyMedium()),
          ),
        ),
        if (experience.isNotEmpty)
          AnimatedEntry(
            index: 2,
            child: _Block(
              title: 'Experience',
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < experience.length; i++)
                    TimelineRow(
                      period: experience[i].period,
                      title: experience[i].role,
                      organization: experience[i].organization,
                      description: experience[i].description,
                      location: experience[i].location,
                      isLast: i == experience.length - 1,
                    ),
                ],
              ),
            ),
          ),
        if (education.isNotEmpty)
          AnimatedEntry(
            index: 3,
            child: _Block(
              title: 'Education',
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < education.length; i++)
                    TimelineRow(
                      period: education[i].period,
                      title: education[i].role,
                      organization: education[i].organization,
                      description: education[i].description,
                      location: education[i].location,
                      isLast: i == education.length - 1,
                      accent: AppColors.accent,
                    ),
                ],
              ),
            ),
          ),
        if (skills.isNotEmpty)
          AnimatedEntry(
            index: 4,
            child: _Block(
              title: 'Skills',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final String category in skills.keys) ...<Widget>[
                    Text(
                      category.toUpperCase(),
                      style: AppType.labelSmall(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skills[category]!
                          .map((Skill skill) => TagChip(label: skill.name))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Generated from the same live content as the rest of the app.',
          style: AppType.labelSmall(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => context.go(AppRoutes.contact),
            icon: const Icon(Icons.mail_outline_rounded, size: 16),
            label: const Text('Contact me'),
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(colors: AppColors.auraGradient),
                  ),
                ),
                const SizedBox(width: 8),
                Text(title, style: AppType.titleLarge()),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
