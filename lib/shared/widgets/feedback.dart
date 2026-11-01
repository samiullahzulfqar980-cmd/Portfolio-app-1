import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum ToastTone { info, success, error }

/// App-wide snackbar helper with consistent styling and screen-reader support.
class Toast {
  const Toast._();

  static void show(
    BuildContext context,
    String message, {
    ToastTone tone = ToastTone.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final Color toneColor = switch (tone) {
      ToastTone.success => AppColors.success,
      ToastTone.error => AppColors.danger,
      ToastTone.info => AppColors.accent,
    };
    final IconData icon = switch (tone) {
      ToastTone.success => Icons.check_circle_outline_rounded,
      ToastTone.error => Icons.error_outline_rounded,
      ToastTone.info => Icons.info_outline_rounded,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: Duration(seconds: tone == ToastTone.error ? 5 : 3),
          content: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: toneColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppType.bodyMedium(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: AppColors.accentSoft,
                  onPressed: onAction,
                ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, tone: ToastTone.success);

  static void error(BuildContext context, String message) =>
      show(context, message, tone: ToastTone.error);
}

/// Confirmation dialog used by destructive admin actions.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  await HapticFeedback.mediumImpact();
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Small reusable modal sheet with grab handle + title.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 20,
          right: 20,
          top: title == null ? 8 : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title != null) ...<Widget>[
              Text(title, style: AppType.headlineMedium()),
              const SizedBox(height: 14),
            ],
            Flexible(child: child),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
