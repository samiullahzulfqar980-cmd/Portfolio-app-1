import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
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

class AdminMessagesScreen extends ConsumerStatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  ConsumerState<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends ConsumerState<AdminMessagesScreen> {
  MessageStatus? _filter;
  bool _busy = false;

  Color _tone(MessageStatus status) => switch (status) {
        MessageStatus.unread => AppColors.accent,
        MessageStatus.read => AppColors.textMuted,
        MessageStatus.replied => AppColors.success,
        MessageStatus.archived => AppColors.warning,
      };

  Future<void> _setStatus(ContactMessage message, MessageStatus status) async {
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).setMessageStatus(message.id, status);
      invalidateAdminCaches(ref);
      if (mounted) Toast.success(context, 'Marked as ${status.label.toLowerCase()}');
    } catch (error) {
      if (mounted) Toast.error(context, ErrorMapper.map(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ContactMessage message) async {
    final bool ok = await confirmDestructive(
      context,
      title: 'Delete inquiry?',
      message: 'The message from ${message.name} will be permanently removed.',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).deleteMessage(message.id);
      invalidateAdminCaches(ref);
      if (mounted) Toast.success(context, 'Message deleted');
    } catch (error) {
      if (mounted) Toast.error(context, ErrorMapper.map(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ContactMessage>> messages = ref.watch(adminMessagesProvider);
    final double gutter = AppSpacing.gutter(context);

    return AdminScaffold(
      title: 'Inquiries',
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: RoundIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh inbox',
            onPressed: () => invalidateAdminCaches(ref),
          ),
        ),
      ],
      child: Stack(
        children: <Widget>[
          messages.when(
            loading: () => const ListSkeleton(count: 4, height: 108),
            error: (Object error, StackTrace stack) => ErrorStateView(
              error: error,
              onRetry: () => ref.invalidate(adminMessagesProvider),
            ),
            data: (List<ContactMessage> data) {
              final List<ContactMessage> filtered = _filter == null
                  ? data
                  : data.where((ContactMessage m) => m.status == _filter).toList();
              return Column(
                children: <Widget>[
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      children: <Widget>[
                        TagChip(
                          label: 'All (${data.length})',
                          selected: _filter == null,
                          onTap: () => setState(() => _filter = null),
                        ),
                        for (final MessageStatus status in MessageStatus.values) ...<Widget>[
                          const SizedBox(width: 8),
                          TagChip(
                            label:
                                '${status.label} (${data.where((ContactMessage m) => m.status == status).length})',
                            selected: _filter == status,
                            onTap: () => setState(() => _filter = status),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? EmptyStateView(
                            title: data.isEmpty ? 'Inbox is empty' : 'Nothing in this filter',
                            message: data.isEmpty
                                ? 'Inquiries sent from the Contact tab land here privately.'
                                : 'Try another status filter.',
                            icon: Icons.inbox_rounded,
                            actionLabel: _filter == null ? null : 'Show all',
                            onAction: _filter == null ? null : () => setState(() => _filter = null),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 120),
                            itemCount: filtered.length,
                            itemBuilder: (BuildContext context, int index) {
                              final ContactMessage message = filtered[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(14),
                                  onTap: () => context.push(AppRoutes.adminMessage(message.id)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              message.name,
                                              style: AppType.labelLarge(
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          StatusChip(
                                            label: message.status.label,
                                            tone: _tone(message.status),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        message.email,
                                        style: AppType.labelSmall(color: AppColors.textMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      if (message.subject != null)
                                        Text(
                                          message.subject!,
                                          style: AppType.bodyMedium(
                                            color: AppColors.textPrimary,
                                          ).copyWith(fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        message.message,
                                        style: AppType.bodySmall(color: AppColors.textMuted),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: <Widget>[
                                          Text(
                                            Formatters.relative(message.createdAt),
                                            style: AppType.mono(
                                              size: 10.5,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (message.status == MessageStatus.unread)
                                            AdminIconAction(
                                              icon: Icons.mark_email_read_outlined,
                                              tooltip: 'Mark as read',
                                              onPressed: _busy
                                                  ? null
                                                  : () => _setStatus(message, MessageStatus.read),
                                            ),
                                          AdminIconAction(
                                            icon: Icons.archive_outlined,
                                            tooltip: 'Archive',
                                            onPressed: _busy
                                                ? null
                                                : () => _setStatus(
                                                      message,
                                                      MessageStatus.archived,
                                                    ),
                                          ),
                                          AdminIconAction(
                                            icon: Icons.delete_outline_rounded,
                                            tooltip: 'Delete',
                                            tone: AppColors.danger,
                                            onPressed: _busy ? null : () => _delete(message),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
