import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';

/// Gradient primary action with a built-in busy state.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.gradient = AppColors.auraGradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final Widget content = AnimatedSwitcher(
      duration: Motion.duration(context, Motion.fast),
      child: isLoading
          ? const SizedBox(
              key: ValueKey<String>('busy'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            )
          : Row(
              key: const ValueKey<String>('label'),
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(label, style: AppType.labelLarge(color: Colors.white)),
              ],
            ),
    );

    final Widget button = Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: Opacity(
        opacity: disabled && !isLoading ? 0.55 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: gradient),
            boxShadow: disabled
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.34),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: disabled
                  ? null
                  : () {
                      Haptics.light();
                      onPressed!.call();
                    },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary (outlined) action with optional leading icon.
class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading)
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
          )
        else if (icon != null) ...<Widget>[
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 8),
        ],
        if (!isLoading) Text(label, style: AppType.labelLarge()),
      ],
    );

    final Widget button = OutlinedButton(
      onPressed: onPressed == null || isLoading ? null : () {
        Haptics.tap();
        onPressed!.call();
      },
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Compact pill button used inside cards and sheets.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.tone = PillTone.neutral,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color border) = switch (tone) {
      PillTone.neutral => (
          Colors.white.withValues(alpha: 0.06),
          AppColors.textPrimary,
          AppColors.border,
        ),
      PillTone.accent => (
          AppColors.accent.withValues(alpha: 0.14),
          AppColors.accentSoft,
          AppColors.accent.withValues(alpha: 0.3),
        ),
      PillTone.danger => (
          AppColors.danger.withValues(alpha: 0.12),
          AppColors.danger,
          AppColors.danger.withValues(alpha: 0.3),
        ),
    };

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: BorderSide(color: border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed == null
              ? null
              : () {
                  Haptics.tap();
                  onPressed!.call();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppType.labelSmall(color: fg).copyWith(fontSize: 12.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum PillTone { neutral, accent, danger }

/// Circular icon button with a consistent hit target.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.tone = PillTone.neutral,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final Color fg = switch (tone) {
      PillTone.neutral => AppColors.textPrimary,
      PillTone.accent => AppColors.accentSoft,
      PillTone.danger => AppColors.danger,
    };
    final Widget button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, size: 20, color: fg),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
