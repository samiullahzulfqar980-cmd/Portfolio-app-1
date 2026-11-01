import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';

/// Small technology / category chip with a deterministic accent colour.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.onTap, this.selected = false, this.icon});

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color accent = TagPalette.colorFor(label);
    final Color fg = selected ? Colors.white : TagPalette.textFor(label);
    return Semantics(
      selected: onTap == null ? null : selected,
      button: onTap != null,
      label: label,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.9) : TagPalette.backgroundFor(label),
        shape: StadiumBorder(
          side: BorderSide(color: selected ? accent : TagPalette.borderFor(label)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 12.5, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: AppType.labelSmall(color: fg).copyWith(fontSize: 11.5, letterSpacing: 0.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Availability pill with a live-looking pulse (respects reduced motion).
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({
    super.key,
    required this.isAvailable,
    this.label,
  });

  final bool isAvailable;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Color tone = isAvailable ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _PulseDot(color: tone, animate: isAvailable),
          const SizedBox(width: 7),
          Text(
            label ?? (isAvailable ? 'Available for work' : 'Currently unavailable'),
            style: AppType.labelSmall(color: tone).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.animate});

  final Color color;
  final bool animate;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !reduce) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          width: 12,
          height: 12,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(
                opacity: (1 - _controller.value) * 0.5,
                child: Container(
                  width: 6 + 6 * _controller.value,
                  height: 6 + 6 * _controller.value,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Status chip used for draft/published and message states.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppType.labelSmall(color: tone).copyWith(fontSize: 10.5, letterSpacing: 0.3),
      ),
    );
  }
}
