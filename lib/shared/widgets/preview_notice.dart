import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Shown only when the app was launched without a Supabase configuration.
///
/// Live builds never render this: every profile, project, skill, service,
/// timeline entry, inquiry and media file is read from Supabase, so the bundled
/// sample content exists purely so the UI can be reviewed offline.
class PreviewNotice extends StatelessWidget {
  const PreviewNotice({
    super.key,
    this.message =
        'Preview mode: showing bundled sample content. Add your Supabase keys to load live data.',
  });

  final String message;

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
              message,
              style: AppType.bodySmall(color: AppColors.warning).copyWith(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
