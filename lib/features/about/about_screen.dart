import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/motion/motion.dart';
import '../../core/platform/launcher_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/content_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_profile.dart';
import '../../data/models/portfolio_data.dart';
import '../../data/models/service.dart';
import '../../data/models/skill.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/info_tiles.dart';
import '../../shared/widgets/preview_notice.dart';
import '../../shared/widgets/state_views.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PortfolioData> portfolio = ref.watch(portfolioProvider);

    return AppPage(
      appBar: AuroraAppBar(
        showBackButton: false,
        titleSpacing: AppSpacing.gutter(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('PROFILE', style: AppType.overline(color: AppColors.accentSoft)),
            Text('About', style: AppType.headlineLarge()),
          ],
        ),
      ),
      body: portfolio.when(
        loading: () => const HomeSkeleton(),
        error: (Object error, StackTrace stack) => ErrorStateView(
          error: error,
          onRetry: () => ref.read(portfolioProvider.notifier).refresh(),
        ),
        data: (PortfolioData data) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.read(portfolioProvider.notifier).refresh(),
          child: _AboutBody(data: data),
        ),
      ),
    );
  }
}

class _AboutBody extends ConsumerStatefulWidget {
  const _AboutBody({required this.data});

  final PortfolioData data;

  @override
  ConsumerState<_AboutBody> createState() => _AboutBodyState();
}

class _AboutBodyState extends ConsumerState<_AboutBody> {
  String? _skillFilter;

  /// Opens an external destination and reports failures inline.
  Future<void> _open(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } on AppFailure catch (failure) {
      if (context.mounted) Toast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PortfolioData data = widget.data;
    final AppProfile profile = data.profile;
    final double gutter = AppSpacing.gutter(context);
    final Map<String, List<Skill>> grouped = groupSkills(data.skills);
    final List<String> categories = grouped.keys.toList(growable: false);
    final String? activeCategory = _skillFilter ?? (categories.isEmpty ? null : categories.first);
    final List<Skill> visibleSkills = activeCategory == null
        ? const <Skill>[]
        : (grouped[activeCategory] ?? const <Skill>[]);

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 120),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: <Widget>[
        if (data.isPreview) ...<Widget>[
          const PreviewNotice(),
          const SizedBox(height: AppSpacing.md),
        ],
        AnimatedEntry(
          index: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AppAvatar(
                imagePath: profile.avatarPath,
                name: profile.fullName,
                size: 82,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(profile.fullName, style: AppType.headlineLarge()),
                    const SizedBox(height: 4),
                    Text(
                      profile.roles.join(' · '),
                      style: AppType.bodySmall(color: AppColors.accentSoft),
                    ),
                    const SizedBox(height: 8),
                    AvailabilityBadge(
                      isAvailable: profile.isAvailable,
                      label: profile.isAvailable ? 'Available' : 'Unavailable',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AnimatedEntry(
          index: 1,
          child: SectionHeader(eyebrow: 'Biography', title: 'My story'),
        ),
        AnimatedEntry(
          index: 2,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final String paragraph in profile.bio
                    .split(RegExp(r'\n\s*\n'))
                    .map((String p) => p.trim())
                    .where((String p) => p.isNotEmpty)) ...<Widget>[
                  Text(paragraph, style: AppType.bodyMedium()),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 20),
                const SizedBox(height: 6),
                if (profile.location != null)
                  InfoRow(
                    icon: Icons.place_outlined,
                    label: 'Location',
                    value: profile.location!,
                  ),
                if (profile.timezone != null)
                  InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Time zone',
                    value: profile.timezone!,
                  ),
                InfoRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: profile.email,
                  onTap: () async {
                    try {
                      await const LauncherService().openEmail(profile.email);
                    } on AppFailure catch (failure) {
                      if (context.mounted) Toast.error(context, failure.message);
                    }
                  },
                ),
                if (profile.whatsappLink != null)
                  InfoRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'WhatsApp',
                    value: profile.whatsappDisplay ?? 'Message on WhatsApp',
                    onTap: () => _open(
                      context,
                      () => const LauncherService()
                          .openWhatsApp(profile.whatsappLink!.url),
                    ),
                  ),
                if (profile.websiteLink != null)
                  InfoRow(
                    icon: Icons.language_rounded,
                    label: 'Website',
                    value: profile.websiteHost ?? profile.websiteLink!.url,
                    onTap: () => _open(
                      context,
                      () => const LauncherService().openUrl(profile.websiteLink!.url),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (data.publishedServices.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          AnimatedEntry(
            index: 3,
            child: SectionHeader(eyebrow: 'Services', title: 'What I deliver'),
          ),
          for (int i = 0; i < data.publishedServices.length; i++)
            AnimatedEntry(
              index: 4 + i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceCard(service: data.publishedServices[i]),
              ),
            ),
        ],
        if (categories.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          AnimatedEntry(
            index: 5,
            child: SectionHeader(eyebrow: 'Skills', title: 'Technical toolkit'),
          ),
          AnimatedEntry(
            index: 6,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final String category in categories) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TagChip(
                        label: category,
                        selected: activeCategory == category,
                        onTap: () => setState(() => _skillFilter = category),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedEntry(
            index: 7,
            child: GlassCard(
              child: Column(
                children: <Widget>[
                  for (final Skill skill in visibleSkills)
                    SkillBar(
                      name: skill.name,
                      proficiency: skill.proficiency,
                      note: skill.note,
                    ),
                ],
              ),
            ),
          ),
        ],
        if (data.experience.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          AnimatedEntry(
            index: 8,
            child: SectionHeader(eyebrow: 'Experience', title: 'Where I have worked'),
          ),
          AnimatedEntry(
            index: 9,
            child: GlassCard(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < data.experience.length; i++)
                    TimelineRow(
                      period: data.experience[i].period,
                      title: data.experience[i].role,
                      organization: data.experience[i].organization,
                      location: data.experience[i].location,
                      description: data.experience[i].description,
                      isLast: i == data.experience.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
        if (data.education.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          AnimatedEntry(
            index: 10,
            child: SectionHeader(eyebrow: 'Education', title: 'Academic background'),
          ),
          AnimatedEntry(
            index: 11,
            child: GlassCard(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < data.education.length; i++)
                    TimelineRow(
                      period: data.education[i].period,
                      title: data.education[i].role,
                      organization: data.education[i].organization,
                      location: data.education[i].location,
                      description: data.education[i].description,
                      isLast: i == data.education.length - 1,
                      accent: AppColors.accent,
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AnimatedEntry(
          index: 12,
          child: Row(
            children: <Widget>[
              Expanded(
                child: PrimaryActionButton(
                  label: 'Résumé',
                  icon: Icons.description_outlined,
                  onPressed: () => context.push(AppRoutes.resume),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryActionButton(
                  label: 'Contact',
                  icon: Icons.mail_outline_rounded,
                  onPressed: () => context.go(AppRoutes.contact),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AnimatedEntry(
          index: 13,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: <Widget>[
                _FooterAction(
                  icon: Icons.science_outlined,
                  label: 'Replay the intro guide',
                  onTap: () async {
                    await ref.read(preferencesProvider).resetOnboarding();
                    if (context.mounted) context.go(AppRoutes.onboarding);
                  },
                ),
                _FooterAction(
                  icon: Icons.lock_outline_rounded,
                  label: 'Owner sign in',
                  onTap: () => context.push(AppRoutes.signIn),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'Portfolio content is managed from the in-app admin area.',
            style: AppType.labelSmall(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.accent.withValues(alpha: 0.14),
                    ],
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  IconKeys.resolve(service.iconKey),
                  size: 19,
                  color: AppColors.accentSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.title,
                  style: AppType.titleLarge().copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(service.description, style: AppType.bodySmall(color: AppColors.textSecondary)),
          if (service.technologies.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: service.technologies
                  .map((String tech) => TagChip(label: tech))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: AppType.bodyMedium(color: AppColors.textSecondary)),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
