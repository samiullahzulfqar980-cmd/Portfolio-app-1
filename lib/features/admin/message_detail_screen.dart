import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/platform/launcher_service.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/contact_message.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'admin_scaffold.dart';

class MessageDetailScreen extends ConsumerWidget {
  const MessageDetailScreen({super.key, required this.messageId});

  final String messageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ContactMessage>> messages = ref.watch(adminMessagesProvider);
    final double gutter = AppSpacing.gutter(context);

    return AdminScaffold(
      title: 'Inquiry',
      child: messages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(adminMessagesProvider),
        ),
        data: (List<ContactMessage> data) {
          ContactMessage? message;
          for (final ContactMessage item in data) {
            if (item.id == messageId) message = item;
          }
          if (message == null) {
            return EmptyStateView(
              title: 'Message not found',
              message: 'It may have been deleted from another device.',
              icon: Icons.mail_outline_rounded,
              actionLabel: 'Back to inbox',
              onAction: () => context.go(AppRoutes.adminMessages),
            );
          }
          final ContactMessage item = message;
          return ListView(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 100),
            children: <Widget>[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(item.name, style: AppType.headlineMedium()),
                        ),
                        StatusChip(
                          label: item.status.label,
                          tone: switch (item.status) {
                            MessageStatus.unread => AppColors.accent,
                            MessageStatus.replied => AppColors.success,
                            MessageStatus.read => AppColors.textMuted,
                            MessageStatus.archived => AppColors.warning,
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.email, style: AppType.bodySmall(color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.shortDate(item.createdAt.toLocal()),
                      style: AppType.mono(size: 11, color: AppColors.textMuted),
                    ),
                    if (item.serviceInterest != null || item.budgetRange != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          if (item.serviceInterest != null)
                            TagChip(label: item.serviceInterest!, icon: Icons.bolt_rounded),
                          if (item.budgetRange != null)
                            TagChip(label: item.budgetRange!, icon: Icons.payments_outlined),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    if (item.subject != null) ...<Widget>[
                      Text(
                        item.subject!,
                        style: AppType.titleLarge().copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SelectableText(
                      item.message,
                      style: AppType.bodyLarge(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryActionButton(
                label: 'Reply by email',
                icon: Icons.reply_rounded,
                onPressed: () async {
                  try {
                    await const LauncherService().openEmail(
                      item.email,
                      subject: item.subject ?? 'Re: your inquiry',
                    );
                    await ref
                        .read(adminRepositoryProvider)
                        .setMessageStatus(item.id, MessageStatus.replied);
                    invalidateAdminCaches(ref);
                    if (context.mounted) Toast.success(context, 'Marked as replied');
                  } on AppFailure catch (failure) {
                    if (context.mounted) Toast.error(context, failure.message);
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SecondaryActionButton(
                      label: 'Mark read',
                      icon: Icons.mark_email_read_outlined,
                      onPressed: () => _updateStatus(
                        context,
                        ref,
                        item,
                        MessageStatus.read,
                        'Marked as read',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryActionButton(
                      label: 'Archive',
                      icon: Icons.archive_outlined,
                      onPressed: () async {
                        final bool ok = await _updateStatus(
                          context,
                          ref,
                          item,
                          MessageStatus.archived,
                          'Archived',
                        );
                        if (ok && context.mounted) context.go(AppRoutes.adminMessages);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  final bool ok = await confirmDestructive(
                    context,
                    title: 'Delete inquiry?',
                    message: 'This cannot be undone.',
                  );
                  if (!ok) return;
                  try {
                    await ref.read(adminRepositoryProvider).deleteMessage(item.id);
                    invalidateAdminCaches(ref);
                    if (context.mounted) {
                      Toast.success(context, 'Message deleted');
                      context.go(AppRoutes.adminMessages);
                    }
                  } on AppFailure catch (failure) {
                    if (context.mounted) Toast.error(context, failure.message);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Delete message'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    ContactMessage message,
    MessageStatus status,
    String confirmation,
  ) async {
    try {
      await ref.read(adminRepositoryProvider).setMessageStatus(message.id, status);
      invalidateAdminCaches(ref);
      if (context.mounted) Toast.success(context, confirmation);
      return true;
    } on Object catch (error) {
      if (context.mounted) Toast.error(context, ErrorMapper.map(error).message);
      return false;
    }
  }
}
