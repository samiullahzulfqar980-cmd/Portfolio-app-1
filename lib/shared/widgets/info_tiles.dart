import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Small label + value row used in profile / contact cards.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, size: 17, color: AppColors.accentSoft),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: AppType.labelSmall(color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(value, style: AppType.bodyMedium(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact stat block (label + value) used on Home.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(height: 6),
        ],
        Text(
          value,
          style: AppType.titleLarge(color: AppColors.textPrimary).copyWith(fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(label, style: AppType.labelSmall(color: AppColors.textMuted)),
      ],
    );
  }
}

/// Proficiency bar with an accessible value announcement.
class SkillBar extends StatelessWidget {
  const SkillBar({
    super.key,
    required this.name,
    required this.proficiency,
    this.note,
  });

  final String name;
  final int proficiency;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final double value = proficiency.clamp(0, 100).toDouble() / 100;
    return Semantics(
      label: '$name, $proficiency percent',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    name,
                    style: AppType.bodyMedium(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$proficiency%', style: AppType.mono(size: 11, color: AppColors.textMuted)),
              ],
            ),
            if (note != null && note!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(note!, style: AppType.bodySmall(color: AppColors.textMuted, ).copyWith(fontSize: 11.5)),
            ],
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: value),
                duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double animated, _) {
                  return LinearProgressIndicator(
                    value: animated,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical timeline row for experience / education.
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.period,
    required this.title,
    required this.organization,
    this.description,
    this.location,
    this.isLast = false,
    this.accent = AppColors.primary,
  });

  final String period;
  final String title;
  final String organization;
  final String? description;
  final String? location;
  final bool isLast;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 26,
            child: Column(
              children: <Widget>[
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            accent.withValues(alpha: 0.45),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(period, style: AppType.mono(size: 11, color: AppColors.accentSoft)),
                  const SizedBox(height: 5),
                  Text(title, style: AppType.titleLarge().copyWith(fontSize: 15.5)),
                  const SizedBox(height: 2),
                  Text(
                    location == null || location!.isEmpty
                        ? organization
                        : '$organization · $location',
                    style: AppType.bodySmall(color: AppColors.textSecondary),
                  ),
                  if (description != null && description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(description!, style: AppType.bodySmall(color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
