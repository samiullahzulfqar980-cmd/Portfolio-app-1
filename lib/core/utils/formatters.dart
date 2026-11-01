import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Date / duration / number formatting without pulling in intl.
class Formatters {
  const Formatters._();

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String shortDate(DateTime value) =>
      '${_months[value.month - 1]} ${value.day}, ${value.year}';

  static String monthYear(DateTime value) => '${_months[value.month - 1]} ${value.year}';

  /// "3h ago", "2d ago" — uses the device clock for a friendly inbox view.
  static String relative(DateTime value, {DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    final Duration diff = current.difference(value.toLocal());
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return shortDate(value.toLocal());
  }

  /// Joins a start/end pair such as "2024 — Present".
  static String dateRange({required String start, String? end, bool isCurrent = false}) {
    final String finish = isCurrent ? 'Present' : (end == null || end.isEmpty ? 'Present' : end);
    return '$start — $finish';
  }

  static String compactCount(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      final double k = value / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    final double m = value / 1000000;
    return '${m.toStringAsFixed(1)}m';
  }
}

/// Splits a list of technologies into chips with stable, tasteful colours.
class TagPalette {
  const TagPalette._();

  static const List<Color> _palette = <Color>[
    Color(0xFF7C5CFF),
    Color(0xFF2EE6D6),
    Color(0xFFFFB86B),
    Color(0xFF66A3FF),
    Color(0xFFF07CD0),
    Color(0xFF8FE388),
  ];

  static Color colorFor(String tag) {
    int hash = 0;
    for (final int unit in tag.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  static Color backgroundFor(String tag) => colorFor(tag).withValues(alpha: 0.14);

  static Color borderFor(String tag) => colorFor(tag).withValues(alpha: 0.28);

  static Color textFor(String tag) => Color.lerp(colorFor(tag), Colors.white, 0.35)!;
}

/// Icon key → icon mapping shared by services and admin editors.
class IconKeys {
  const IconKeys._();

  static const Map<String, IconData> map = <String, IconData>{
    'mobile': Icons.smartphone_rounded,
    'web': Icons.language_rounded,
    'backend': Icons.dns_rounded,
    'design': Icons.draw_rounded,
    'cloud': Icons.cloud_rounded,
    'rocket': Icons.rocket_launch_rounded,
    'spark': Icons.auto_awesome_rounded,
    'database': Icons.storage_rounded,
    'shield': Icons.shield_rounded,
    'chart': Icons.insights_rounded,
  };

  static List<String> get keys => map.keys.toList(growable: false);

  static IconData resolve(String? key) => map[key] ?? Icons.auto_awesome_rounded;
}

/// Normalises stored colour accents (e.g. "violet") to the palette.
class AccentKey {
  const AccentKey._();

  static Color resolve(String? key) {
    switch (key) {
      case 'cyan':
        return AppColors.accent;
      case 'amber':
        return AppColors.warm;
      case 'violet':
        return AppColors.primary;
      case 'mint':
        return AppColors.success;
      case 'rose':
        return const Color(0xFFFF8FB1);
      default:
        return AppColors.primary;
    }
  }
}
