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
import '../../data/models/project.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/info_tiles.dart';
import '../../shared/widgets/project_card.dart';
import '../../shared/widgets/state_views.dart';
import '../auth/auth_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PortfolioData> portfolio = ref.watch(portfolioProvider);

    return AppPage(
      appBar: AuroraAppBar(
        showBackButton: false,
        title: Row(
          children: <Widget>[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(colors: AppColors.auraGradient),
              ),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Sora',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text('Portfolio', style: AppType.overline(color: AppColors.textSecondary)),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RoundIconButton(
              icon: Icons.tune_rounded,
              tooltip: 'Shortcuts and owner access',
              onPressed: () => _showShortcuts(context, ref),
            ),
          ),
        ],
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
          child: _HomeContent(data: data),
        ),
      ),
    );
  }

  void _showShortcuts(BuildContext context, WidgetRef ref) {
    final bool signedIn = ref.read(authUserProvider).value != null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Shortcuts', style: AppType.headlineMedium()),
                const SizedBox(height: 4),
                Text(
                  'Everything here works without an account.',
                  style: AppType.bodySmall(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                _ShortcutTile(
                  icon: Icons.description_outlined,
                  label: 'Résumé',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.resume);
                  },
                ),
                _ShortcutTile(
                  icon: Icons.science_outlined,
                  label: 'Replay the intro guide',
                  onTap: () async {
                    await ref.read(preferencesProvider).resetOnboarding();
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    if (context.mounted) context.go(AppRoutes.onboarding);
                  },
                ),
                const Divider(height: 24),
                _ShortcutTile(
                  icon: signedIn ? Icons.admin_panel_settings_outlined : Icons.lock_outline_rounded,
                  label: signedIn ? 'Open admin area' : 'Owner sign in',
                  trailing: signedIn ? null : const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (signedIn) {
                      context.push(AppRoutes.admin);
                    } else {
                      AuthSheet.showSignIn(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 19, color: AppColors.accentSoft),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppType.bodyMedium(color: AppColors.textPrimary))),
            trailing ?? const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.data});

  final PortfolioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double gutter = AppSpacing.gutter(context);
    final AppProfile profile = data.profile;
    final List<Project> featured =
        data.featuredProjects.isNotEmpty ? data.featuredProjects : data.latestProjects(limit: 2);

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 120),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: <Widget>[
        if (data.isPreview) ...<Widget>[
          const _PreviewNotice(),
          const SizedBox(height: AppSpacing.md),
        ],
        AnimatedEntry(index: 0, child: _Hero(profile: profile, data: data)),
        const SizedBox(height: AppSpacing.lg),
        AnimatedEntry(index: 1, child: _Actions(profile: profile)),
        const SizedBox(height: AppSpacing.xl),
        if (profile.stats.isNotEmpty)
          AnimatedEntry(
            index: 2,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < profile.stats.length; i++) ...<Widget>[
                    if (i > 0)
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: AppColors.border,
                      ),
                    Expanded(
                      child: StatTile(
                        label: profile.stats[i].label,
                        value: profile.stats[i].value,
                        icon: profile.stats[i].iconKey == null
                            ? null
                            : IconKeys.resolve(profile.stats[i].iconKey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        AnimatedEntry(
          index: 3,
          child: SectionHeader(
            eyebrow: 'Selected work',
            title: 'Featured projects',
            actionLabel: 'All projects',
            onAction: () => context.go(AppRoutes.projects),
          ),
        ),
        if (featured.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: EmptyStateView(
              title: 'No projects yet',
              message: 'Published projects will appear here as soon as they are added.',
              icon: Icons.grid_view_rounded,
              compact: true,
            ),
          )
        else
          Column(
            children: <Widget>[
              for (int i = 0; i < featured.length; i++) ...<Widget>[
                AnimatedEntry(
                  index: 4 + i,
                  child: FeaturedProjectCard(
                    project: featured[i],
                    onTap: () => context.push(AppRoutes.project(featured[i].slug)),
                  ),
                ),
                if (i != featured.length - 1) const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        const SizedBox(height: AppSpacing.xl),
        AnimatedEntry(
          index: 6,
          child: SectionHeader(
            eyebrow: 'How I can help',
            title: 'Services',
            actionLabel: 'About me',
            onAction: () => context.go(AppRoutes.about),
          ),
        ),
        AnimatedEntry(
          index: 7,
          child: Column(
            children: <Widget>[
              for (final service in data.publishedServices.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => context.go(AppRoutes.about),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: <Color>[
                                AppColors.primary.withValues(alpha: 0.28),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(service.title, style: AppType.titleLarge().copyWith(fontSize: 14.5)),
                              const SizedBox(height: 2),
                              Text(
                                service.description,
                                style: AppType.bodySmall(color: AppColors.textMuted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedEntry(
          index: 8,
          child: GradientBorderCard(
            onTap: () => context.go(AppRoutes.contact),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.rocket_launch_rounded, size: 17, color: AppColors.accentSoft),
                    const SizedBox(width: 8),
                    Text('OPEN FOR WORK', style: AppType.overline(color: AppColors.accentSoft)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Have something in mind?',
                  style: AppType.headlineMedium(),
                ),
                const SizedBox(height: 6),
                Text(
                  'Send a short brief and I will reply with next steps, timeline and scope.',
                  style: AppType.bodySmall(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Text(
                      'Start a conversation',
                      style: AppType.labelSmall(color: AppColors.accentSoft).copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accentSoft),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            '© ${DateTime.now().year} ${data.profile.fullName}',
            style: AppType.labelSmall(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.profile, required this.data});

  final AppProfile profile;
  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AvailabilityBadge(
                    isAvailable: profile.isAvailable,
                    label: profile.availabilityNote?.isNotEmpty == true
                        ? profile.availabilityNote
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Hello, I am', style: AppType.bodyLarge(color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(profile.fullName, style: AppType.displayMedium()),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppAvatar(
              imagePath: profile.avatarPath,
              name: profile.fullName,
              size: 78,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final String role in profile.roles)
              TagChip(label: role, icon: Icons.bolt_rounded),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(profile.shortIntro, style: AppType.bodyLarge(color: AppColors.textSecondary)),
        if (profile.location != null && profile.location!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                profile.location!,
                style: AppType.labelSmall(color: AppColors.textMuted).copyWith(fontSize: 11.5),
              ),
              if (profile.timezone != null) ...<Widget>[
                Text(' · ', style: AppType.labelSmall(color: AppColors.textMuted)),
                Text(
                  profile.timezone!,
                  style: AppType.labelSmall(color: AppColors.textMuted).copyWith(fontSize: 11.5),
                ),
              ],
            ],
          ),
        ],
        if (profile.orderedSocialLinks.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.orderedSocialLinks
                .map((link) => _SocialChip(link: link))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.link});

  final SocialLink link;

  IconData get _icon {
    switch (link.key) {
      case 'github':
        return Icons.code_rounded;
      case 'whatsapp':
        return Icons.chat_bubble_outline_rounded;
      case 'x':
        return Icons.alternate_email_rounded;
      case 'website':
        return Icons.language_rounded;
      case 'dribbble':
        return Icons.brush_outlined;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${link.label}',
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () async {
            try {
              await const LauncherService().openSocial(link);
            } on AppFailure catch (failure) {
              if (context.mounted) Toast.error(context, failure.message);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(_icon, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(link.label, style: AppType.labelSmall(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.profile});

  final AppProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: PrimaryActionButton(
                label: 'View projects',
                icon: Icons.grid_view_rounded,
                onPressed: () => context.go(AppRoutes.projects),
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.resume),
            icon: const Icon(Icons.description_outlined, size: 18),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.white.withValues(alpha: 0.02),
            ),
            label: const Text('Résumé'),
          ),
        ),
      ],
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.science_outlined, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Preview mode: showing bundled sample content. Add your Supabase keys to load live data.',
              style: AppType.bodySmall(color: AppColors.warning).copyWith(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
