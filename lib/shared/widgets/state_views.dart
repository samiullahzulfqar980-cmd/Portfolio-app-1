import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_buttons.dart';
import 'glass_card.dart';

/// Full-screen friendly error with retry + optional secondary action.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.title = 'That did not work',
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppFailure failure = ErrorMapper.map(error);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _StateIcon(
                icon: failure.isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                tone: AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                failure.isOffline ? 'You appear to be offline' : title,
                style: AppType.headlineMedium(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                failure.message,
                style: AppType.bodyMedium(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              if (failure.code != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Reference: ${failure.code}',
                  style: AppType.mono(size: 11.5, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (onRetry != null)
                PrimaryActionButton(label: retryLabel, icon: Icons.refresh_rounded, onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly empty state with a single primary action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: compact ? AppSpacing.xl : AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _StateIcon(icon: icon, tone: AppColors.primarySoft),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppType.headlineMedium(), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppType.bodyMedium(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 220,
                child: PrimaryActionButton(label: actionLabel!, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.icon, required this.tone});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.withValues(alpha: 0.12),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: tone.withValues(alpha: 0.18), blurRadius: 32, spreadRadius: 2),
        ],
      ),
      child: Icon(icon, size: 30, color: tone),
    );
  }
}

/// Shimmering skeleton block. Static when reduced motion is enabled.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 10,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget base = Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );

    if (Motion.reduced(context)) return base;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2.6 - 1, 0),
              end: Alignment(-1 + t * 2.6 + 0.2, 0),
              colors: <Color>[
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton layout used while the portfolio loads.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: const <Widget>[
        SizedBox(height: 12),
        Skeleton(height: 14, width: 140),
        SizedBox(height: 18),
        Skeleton(height: 30, width: 240),
        SizedBox(height: 10),
        Skeleton(height: 30, width: 180),
        SizedBox(height: 24),
        Skeleton(height: 120),
        SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(child: Skeleton(height: 52)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 52)),
          ],
        ),
        SizedBox(height: 28),
        Skeleton(height: 190),
        SizedBox(height: 16),
        Skeleton(height: 190),
      ],
    );
  }
}

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 3, this.height = 150});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: count,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 14),
      itemBuilder: (BuildContext context, int index) => Skeleton(height: height),
    );
  }
}

/// Inline error card used inside lists / forms (does not take over the screen).
class InlineErrorCard extends StatelessWidget {
  const InlineErrorCard({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.danger.withValues(alpha: 0.28),
      background: AppColors.danger.withValues(alpha: 0.07),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppType.bodySmall(color: AppColors.textPrimary).copyWith(height: 1.4),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Success confirmation card (contact form, admin saves).
class SuccessCard extends StatelessWidget {
  const SuccessCard({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.success.withValues(alpha: 0.3),
      background: AppColors.success.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppType.titleLarge())),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: AppType.bodyMedium(color: AppColors.textSecondary)),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            SecondaryActionButton(label: actionLabel!, onPressed: onAction, expand: false),
          ],
        ],
      ),
    );
  }
}
