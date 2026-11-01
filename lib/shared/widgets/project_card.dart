import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/project.dart';
import 'app_avatar.dart';
import 'badges.dart';
import 'glass_card.dart';

/// Featured card used on Home and at the top of the Projects list.
class FeaturedProjectCard extends StatelessWidget {
  const FeaturedProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = AccentKey.resolve(project.accentKey);
    return Semantics(
      button: true,
      label: '${project.title}. ${project.category} project. ${project.summary}',
      child: GlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        borderColor: accent.withValues(alpha: 0.22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                CoverImage(
                  imagePath: project.imagePath,
                  height: 172,
                  accent: accent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Text(
                      project.category.toUpperCase(),
                      style: AppType.labelSmall(color: Colors.white).copyWith(
                        fontSize: 10,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ),
                if (project.isFeatured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.auraGradient),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              'Featured',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.labelSmall(color: Colors.white)
                                  .copyWith(fontSize: 10, letterSpacing: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    project.title,
                    style: AppType.titleLarge(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project.summary,
                    style: AppType.bodySmall(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (project.technologies.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: project.technologies
                          .take(4)
                          .map((String tech) => TagChip(label: tech))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          'View case study',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.labelSmall(color: accentSoftFor(accent)).copyWith(
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: accentSoftFor(accent)),
                      const Spacer(),
                      if (project.year != null)
                        Flexible(
                          child: Text(
                            project.year!,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.mono(size: 11, color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color accentSoftFor(Color color) => Color.lerp(color, Colors.white, 0.35)!;
}

/// Compact row-style card for the searchable project list.
class ProjectListTile extends StatelessWidget {
  const ProjectListTile({super.key, required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = AccentKey.resolve(project.accentKey);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      semanticLabel: '${project.title}, ${project.category}. ${project.summary}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: CoverImage(
              imagePath: project.imagePath,
              height: 92,
              accent: accent,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        project.title,
                        style: AppType.titleLarge().copyWith(fontSize: 15.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (project.isFeatured)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  project.category,
                  style: AppType.labelSmall(color: AccentKey.resolve(project.accentKey))
                      .copyWith(fontSize: 10.5, letterSpacing: 0.6),
                ),
                const SizedBox(height: 6),
                Text(
                  project.summary,
                  style: AppType.bodySmall(color: AppColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: project.technologies
                      .take(3)
                      .map((String tech) => TagChip(label: tech))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
