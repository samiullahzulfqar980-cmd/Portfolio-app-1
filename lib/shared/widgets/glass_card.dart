import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Frosted, bordered surface used for almost every container in the app.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.onLongPress,
    this.borderRadius = AppRadius.card,
    this.gradient,
    this.borderColor,
    this.background,
    this.showShadow = true,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final List<Color>? gradient;
  final Color? borderColor;
  final Color? background;
  final bool showShadow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = gradient ??
        <Color>[
          Colors.white.withValues(alpha: 0.055),
          Colors.white.withValues(alpha: 0.018),
        ];

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: background,
        gradient: background == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              )
            : null,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: showShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            splashColor: AppColors.primary.withValues(alpha: 0.12),
            highlightColor: AppColors.primary.withValues(alpha: 0.06),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return Semantics(label: semanticLabel, container: true, child: surface);
    }

    return surface;
  }
}

/// Card with a coloured gradient border, used for hero/featured surfaces.
class GradientBorderCard extends StatelessWidget {
  const GradientBorderCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.colors = AppColors.triGradient,
    this.borderRadius = AppRadius.card,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final List<Color> colors;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.first.withValues(alpha: 0.55),
            colors.last.withValues(alpha: 0.35),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.first.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF10162A), Color(0xFF0A0F1D)],
            ),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: AppColors.primary.withValues(alpha: 0.12),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String title;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (eyebrow != null) ...<Widget>[
                  Text(eyebrow!.toUpperCase(), style: theme.textTheme.labelSmall),
                  const SizedBox(height: 6),
                ],
                Text(title, style: theme.textTheme.headlineMedium),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            Flexible(
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        actionLabel!,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(color: AppColors.accentSoft),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.accentSoft),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
