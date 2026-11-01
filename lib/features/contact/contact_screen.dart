import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/motion/motion.dart';
import '../../core/platform/launcher_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/content_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/validators.dart';
import '../../data/models/app_profile.dart';
import '../../data/models/portfolio_data.dart';
import '../../data/repositories/contact_repository.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/info_tiles.dart';
import '../../shared/widgets/state_views.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PortfolioData> portfolio = ref.watch(portfolioProvider);

    return AppPage(
      appBar: AuroraAppBar(
        showBackButton: false,
        titleSpacing: AppSpacing.gutter(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('GET IN TOUCH', style: AppType.overline(color: AppColors.accentSoft)),
            Text('Contact', style: AppType.headlineLarge()),
          ],
        ),
      ),
      body: portfolio.when(
        loading: () => const ListSkeleton(count: 3, height: 160),
        error: (Object error, StackTrace stack) => ErrorStateView(
          error: error,
          onRetry: () => ref.read(portfolioProvider.notifier).refresh(),
        ),
        data: (PortfolioData data) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.read(portfolioProvider.notifier).refresh(),
          child: _ContactBody(data: data),
        ),
      ),
    );
  }
}

class _ContactBody extends ConsumerStatefulWidget {
  const _ContactBody({required this.data});

  final PortfolioData data;

  @override
  ConsumerState<_ContactBody> createState() => _ContactBodyState();
}

class _ContactBodyState extends ConsumerState<_ContactBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();
  final TextEditingController _honeypot = TextEditingController();

  late final DateTime _formOpenedAt = DateTime.now();
  String? _serviceInterest;
  String? _budgetRange;
  bool _sending = false;
  bool _sent = false;
  String _sentToName = '';
  String? _submitError;

  static const List<String> _services = <String>[
    'Cross-platform mobile app',
    'Full-stack web platform',
    'Backend / API work',
    'UI engineering & polish',
    'Something else',
  ];

  static const List<String> _budgets = <String>[
    'Under \$2k',
    '\$2k – \$5k',
    '\$5k – \$10k',
    'Full-time role',
    'Not sure yet',
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    _honeypot.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    dismissKeyboard(context);
    setState(() => _submitError = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      Haptics.error();
      setState(() => _submitError = 'Please fix the highlighted fields and try again.');
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(contactRepositoryProvider).submit(
            ContactSubmission(
              name: _name.text,
              email: _email.text,
              message: _message.text,
              subject: _subject.text,
              serviceInterest: _serviceInterest,
              budgetRange: _budgetRange,
              honeypot: _honeypot.text,
              formOpenedAt: _formOpenedAt,
            ),
          );
      if (!mounted) return;
      Haptics.success();
      final String cleanedName = _name.text.trim();
      setState(() {
        _sending = false;
        _sent = true;
        _sentToName = cleanedName.split(' ').first;
      });
      _formKey.currentState?.reset();
      _name.clear();
      _email.clear();
      _subject.clear();
      _message.clear();
    } catch (error) {
      if (!mounted) return;
      final AppFailure failure = ErrorMapper.map(error);
      Haptics.error();
      setState(() {
        _sending = false;
        _submitError = failure.message;
      });
    }
  }

  void _writeAnother() {
    setState(() {
      _sent = false;
      _submitError = null;
      _serviceInterest = null;
      _budgetRange = null;
    });
  }

  Future<void> _launch(Future<void> Function() action) async {
    try {
      await action();
    } on AppFailure catch (failure) {
      if (mounted) Toast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppProfile profile = widget.data.profile;
    final double gutter = AppSpacing.gutter(context);
    final LauncherService launcher = const LauncherService();

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 120),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: <Widget>[
        AnimatedEntry(
          index: 0,
          child: Text(
            'Have a project, a role or a question? Send a short brief and it lands in a private inbox — no account needed.',
            style: AppType.bodyLarge(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedEntry(
          index: 1,
          child: GlassCard(
            child: Column(
              children: <Widget>[
                InfoRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: profile.email,
                  onTap: () => _launch(() => launcher.openEmail(profile.email)),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 15, color: AppColors.textMuted),
                ),
                if (profile.phone != null && profile.phone!.isNotEmpty)
                  InfoRow(
                    icon: Icons.call_outlined,
                    label: 'Phone',
                    value: profile.phone!,
                    onTap: () => _launch(() => launcher.openPhone(profile.phone!)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                  ),
                if (profile.location != null)
                  InfoRow(
                    icon: Icons.place_outlined,
                    label: 'Based in',
                    value: profile.timezone == null
                        ? profile.location!
                        : '${profile.location!} · ${profile.timezone!}',
                  ),
                if (profile.orderedSocialLinks.isNotEmpty) ...<Widget>[
                  const Divider(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.orderedSocialLinks
                          .map(
                            (SocialLink link) => PillButton(
                              label: link.label,
                              icon: Icons.link_rounded,
                              onPressed: () => _launch(() => launcher.openSocial(link)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AnimatedEntry(
          index: 2,
          child: SectionHeader(eyebrow: 'Inquiry', title: 'Send a message'),
        ),
        AnimatedEntry(
          index: 3,
          child: _sent
              ? SuccessCard(
                  title: 'Message sent',
                  message:
                      'Thanks${_sentToName.isEmpty ? '' : ' $_sentToName'} — your inquiry is in the private inbox. '
                      'If it needs a reply, you will hear back at the email address you used.',
                  actionLabel: 'Write another',
                  onAction: _writeAnother,
                )
              : GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md + 2),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppTextField(
                          controller: _name,
                          label: 'Your name',
                          hint: 'Ada Lovelace',
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const <String>[AutofillHints.name],
                          maxLength: Validators.nameMax,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: Validators.name,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _email,
                          label: 'Email',
                          hint: 'you@company.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[AutofillHints.email],
                          prefixIcon: Icons.alternate_email_rounded,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 14),
                        AppDropdown<String>(
                          label: 'What do you need?',
                          value: _serviceInterest,
                          hint: 'Optional — pick a service',
                          items: _services
                              .map((String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ))
                              .toList(),
                          onChanged: (String? value) => setState(() => _serviceInterest = value),
                        ),
                        const SizedBox(height: 14),
                        AppDropdown<String>(
                          label: 'Budget or engagement',
                          value: _budgetRange,
                          hint: 'Optional',
                          items: _budgets
                              .map((String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ))
                              .toList(),
                          onChanged: (String? value) => setState(() => _budgetRange = value),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _subject,
                          label: 'Subject',
                          hint: 'Optional — a one-line summary',
                          textInputAction: TextInputAction.next,
                          maxLength: 120,
                          prefixIcon: Icons.label_outline_rounded,
                          validator: Validators.optionalSubject,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _message,
                          label: 'Project details',
                          hint: 'What are you building, what is the timeline, and what does success look like?',
                          maxLines: 6,
                          minLines: 5,
                          maxLength: Validators.messageMax,
                          showCounter: true,
                          textCapitalization: TextCapitalization.sentences,
                          validator: Validators.message,
                        ),
                        // Honeypot: hidden from humans, tempting to bots.
                        SizedBox(
                          height: 0,
                          width: 0,
                          child: ExcludeSemantics(
                            child: TextFormField(
                              controller: _honeypot,
                              focusNode: FocusNode(skipTraversal: true),
                              enableInteractiveSelection: false,
                              autofocus: false,
                              decoration: const InputDecoration(
                                labelText: 'Company website (leave blank)',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        if (_submitError != null) ...<Widget>[
                          const SizedBox(height: 6),
                          InlineErrorCard(message: _submitError!),
                        ],
                        const SizedBox(height: 16),
                        PrimaryActionButton(
                          label: 'Send message',
                          icon: Icons.send_rounded,
                          isLoading: _sending,
                          onPressed: _sending ? null : _submit,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.shield_outlined, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Inquiries are private: only the portfolio owner can read them, and they are never shown publicly.',
                                style: AppType.labelSmall(color: AppColors.textMuted)
                                    .copyWith(height: 1.35),
                              ),
                            ),
                          ],
                        ),
                        if (widget.data.isPreview) ...<Widget>[
                          const SizedBox(height: 12),
                          const StatusChip(
                            label: 'Preview mode — submissions are simulated',
                            tone: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AnimatedEntry(
          index: 4,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Prefer another channel?', style: AppType.titleLarge()),
                const SizedBox(height: 6),
                Text(
                  'Email works too, and the social links above open in the right app.',
                  style: AppType.bodySmall(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                SecondaryActionButton(
                  label: 'Copy email address',
                  icon: Icons.copy_rounded,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: profile.email));
                    if (context.mounted) Toast.success(context, 'Email address copied');
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: TextButton.icon(
            onPressed: () => context.push(AppRoutes.signIn),
            icon: const Icon(Icons.lock_outline_rounded, size: 15),
            label: Text(
              'Portfolio owner? Sign in',
              style: AppType.labelSmall(color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}
