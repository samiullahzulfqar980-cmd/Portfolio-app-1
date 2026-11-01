import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Centres a small amount of content vertically **without** ever overflowing.
///
/// Short viewports (landscape phones, split screen) and large accessibility text
/// sizes can make a full-height `Column` taller than the screen. This widget
/// keeps the content centred when it fits and lets it scroll when it does not,
/// so state/message screens can never raise a `RenderFlex overflowed` error.
class ScrollableCenter extends StatelessWidget {
  const ScrollableCenter({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.maxWidth = 460,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available = constraints.hasBoundedHeight
            ? math.max(0.0, constraints.maxHeight - padding.vertical)
            : 0;
        return SingleChildScrollView(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: available,
                maxWidth: maxWidth,
              ),
              child: Center(child: child),
            ),
          ),
        );
      },
    );
  }
}
