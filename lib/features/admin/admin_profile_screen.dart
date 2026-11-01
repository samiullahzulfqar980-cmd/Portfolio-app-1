import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_env.dart';
import '../../core/errors/app_failure.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/content_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/storage_urls.dart';
import '../../core/utils/validators.dart';
import '../../data/models/app_profile.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'admin_scaffold.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _headline = TextEditingController();
  final TextEditingController _roles = TextEditingController();
  final TextEditingController _shortIntro = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _availabilityNote = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _timezone = TextEditingController();

  final Map<String, TextEditingController> _socials = <String, TextEditingController>{
    for (final String key in SocialLink.supportedKeys) key: TextEditingController(),
  };

  AppProfile? _profile;
  bool _hydrated = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _uploadingResume = false;
  String _availability = 'available';
  String? _avatarPath;
  String? _resumePath;
  String? _error;

  static const List<String> _availabilityOptions = <String>['available', 'open', 'unavailable'];

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _name,
      _headline,
      _roles,
      _shortIntro,
      _bio,
      _availabilityNote,
      _email,
      _phone,
      _location,
      _timezone,
      ..._socials.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _hydrate(AppProfile profile) {
    _profile = profile;
    _name.text = profile.fullName;
    _headline.text = profile.headline;
    _roles.text = profile.roles.join(', ');
    _shortIntro.text = profile.shortIntro;
    _bio.text = profile.bio;
    _availability = _availabilityOptions.contains(profile.availabilityStatus)
        ? profile.availabilityStatus
        : 'available';
    _availabilityNote.text = profile.availabilityNote ?? '';
    _email.text = profile.email;
    _phone.text = profile.phone ?? '';
    _location.text = profile.location ?? '';
    _timezone.text = profile.timezone ?? '';
    _avatarPath = profile.avatarPath;
    _resumePath = profile.resumePath;
    for (final MapEntry<String, TextEditingController> entry in _socials.entries) {
      entry.value.text = profile.socialLinks[entry.key]?.url ?? '';
    }
  }

  Future<void> _uploadAvatar() async {
    if (!AppEnv.isConfigured) {
      Toast.error(context, 'Connect Supabase to upload an avatar.');
      return;
    }
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      setState(() => _uploadingAvatar = true);
      final String path = await ref.read(adminRepositoryProvider).uploadImage(
            bucket: StorageUrl.profileBucket,
            folder: 'avatar',
            fileName: file.name,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() {
        _avatarPath = path;
        _uploadingAvatar = false;
      });
      Toast.success(context, 'Avatar uploaded — save to apply');
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      Toast.error(context, ErrorMapper.map(error, fallback: 'Upload failed.').message);
    }
  }

  Future<void> _uploadResume() async {
    if (!AppEnv.isConfigured) {
      Toast.error(context, 'Connect Supabase to upload a résumé.');
      return;
    }
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf'],
        withData: true,
      );
      final PlatformFile? file =
          result == null || result.files.isEmpty ? null : result.files.first;
      if (file == null || file.bytes == null) return;
      if (file.bytes!.lengthInBytes > 10 * 1024 * 1024) {
        if (mounted) Toast.error(context, 'Please choose a PDF under 10 MB.');
        return;
      }
      setState(() => _uploadingResume = true);
      final String path = await ref.read(adminRepositoryProvider).uploadImage(
            bucket: StorageUrl.resumeBucket,
            folder: 'resume',
            fileName: file.name,
            bytes: file.bytes!,
            contentType: 'application/pdf',
          );
      if (!mounted) return;
      setState(() {
        _resumePath = path;
        _uploadingResume = false;
      });
      Toast.success(context, 'Résumé uploaded — save to apply');
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingResume = false);
      Toast.error(context, ErrorMapper.map(error, fallback: 'Upload failed.').message);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      Haptics.error();
      return;
    }
    final AppProfile? existing = _profile;
    if (existing == null) {
      setState(() => _error = 'Profile not loaded yet.');
      return;
    }

    final Map<String, SocialLink> links = <String, SocialLink>{};
    for (final MapEntry<String, TextEditingController> entry in _socials.entries) {
      final SocialLink? link = SocialLink.tryParse(
        entry.key,
        Sanitizer.clean(entry.value.text, maxLength: 300),
      );
      if (link != null) links[link.key] = link;
    }

    final AppProfile updated = AppProfile(
      id: existing.id,
      fullName: _name.text.trim(),
      headline: _headline.text.trim(),
      roles: _roles.text
          .split(',')
          .map((String r) => Sanitizer.clean(r, maxLength: 40))
          .where((String r) => r.isNotEmpty)
          .toList(),
      shortIntro: Sanitizer.clean(_shortIntro.text, maxLength: 300),
      bio: Sanitizer.multiline(_bio.text, maxLength: 4000),
      availabilityStatus: _availability,
      availabilityNote: Sanitizer.cleanOptional(_availabilityNote.text, maxLength: 80),
      email: Sanitizer.clean(_email.text, maxLength: 254),
      phone: Sanitizer.cleanOptional(_phone.text, maxLength: 30),
      location: Sanitizer.cleanOptional(_location.text, maxLength: 80),
      timezone: Sanitizer.cleanOptional(_timezone.text, maxLength: 40),
      socialLinks: links,
      avatarPath: _avatarPath,
      resumePath: _resumePath,
      stats: existing.stats,
    );

    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).saveProfile(updated);
      if (!mounted) return;
      Haptics.success();
      invalidateAdminCaches(ref);
      ref.invalidate(portfolioProvider);
      setState(() {
        _saving = false;
        _profile = updated;
      });
      Toast.success(context, 'Profile saved');
    } catch (error) {
      if (!mounted) return;
      Haptics.error();
      setState(() {
        _saving = false;
        _error = ErrorMapper.map(error).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppProfile> profile = ref.watch(adminProfileProvider);
    final double gutter = AppSpacing.gutter(context);

    if (profile.hasValue && !_hydrated) {
      _hydrated = true;
      _hydrate(profile.requireValue);
    }

    return AdminScaffold(
      title: 'Profile',
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: _saving || !profile.hasValue ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ),
      ],
      child: profile.when(
        loading: () => const ListSkeleton(count: 3, height: 160),
        error: (Object error, StackTrace stack) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(adminProfileProvider),
        ),
        data: (AppProfile _) => Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 140),
            children: <Widget>[
              if (!AppEnv.isConfigured) const AdminOfflineNotice(),
              GlassCard(
                child: Column(
                  children: <Widget>[
                    AppAvatar(
                      imagePath: _avatarPath,
                      name: _name.text.isEmpty ? 'Owner' : _name.text,
                      size: 86,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name.text.isEmpty ? 'Your name' : _name.text,
                      style: AppType.titleLarge(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: SecondaryActionButton(
                            label: _uploadingAvatar ? 'Uploading…' : 'Change avatar',
                            icon: Icons.image_outlined,
                            isLoading: _uploadingAvatar,
                            onPressed: _uploadingAvatar ? null : _uploadAvatar,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('IDENTITY', style: AppType.labelSmall(color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _name,
                      label: 'Full name',
                      hint: 'Your name',
                      maxLength: 80,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.name,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _headline,
                      label: 'Headline',
                      hint: 'Mobile & Web App Developer',
                      maxLength: 90,
                      validator: (String? value) =>
                          Validators.requiredText(value, label: 'Headline', max: 90),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _roles,
                      label: 'Roles (comma separated)',
                      hint: 'Flutter Developer, Full-Stack Web',
                      maxLength: 140,
                      helper: 'Shown as chips on Home. 2–3 works best.',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _shortIntro,
                      label: 'Short intro',
                      hint: 'One sentence that appears under your name.',
                      maxLines: 3,
                      minLines: 2,
                      maxLength: 300,
                      showCounter: true,
                      validator: (String? value) => Validators.message(value, min: 20, max: 300),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('BIOGRAPHY', style: AppType.labelSmall(color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _bio,
                      label: 'About you',
                      hint: 'Paragraphs separated by a blank line.',
                      maxLines: 12,
                      minLines: 6,
                      maxLength: 4000,
                      showCounter: true,
                      validator: (String? value) => Validators.message(value, min: 40, max: 4000),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('AVAILABILITY', style: AppType.labelSmall(color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    AppDropdown<String>(
                      label: 'Status',
                      value: _availability,
                      items: _availabilityOptions
                          .map((String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value[0].toUpperCase() + value.substring(1)),
                              ))
                          .toList(),
                      onChanged: (String? value) => setState(() => _availability = value ?? 'available'),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _availabilityNote,
                      label: 'Badge text (optional)',
                      hint: 'Open to freelance projects',
                      maxLength: 80,
                    ),
                    const SizedBox(height: 8),
                    AvailabilityBadge(
                      isAvailable: _availability != 'unavailable',
                      label: _availabilityNote.text.isEmpty ? null : _availabilityNote.text,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('CONTACT DETAILS', style: AppType.labelSmall(color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _phone,
                      label: 'Phone (optional)',
                      keyboardType: TextInputType.phone,
                      maxLength: 30,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _location,
                      label: 'Location',
                      hint: 'City, Country',
                      maxLength: 80,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _timezone,
                      label: 'Time zone',
                      hint: 'UTC+5',
                      maxLength: 40,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('SOCIAL LINKS', style: AppType.labelSmall(color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    for (final String key in SocialLink.supportedKeys) ...<Widget>[
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _socials[key],
                        label: SocialLink(key: key, label: key, url: '').label,
                        hint: 'https://…',
                        keyboardType: TextInputType.url,
                        validator: (String? value) => Validators.url(value),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('RÉSUMÉ', style: AppType.labelSmall(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Text(
                      _resumePath == null || _resumePath!.isEmpty
                          ? 'No PDF uploaded. The résumé screen will show the generated summary.'
                          : 'Stored at: $_resumePath',
                      style: AppType.bodySmall(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: SecondaryActionButton(
                            label: _uploadingResume ? 'Uploading…' : 'Upload PDF',
                            icon: Icons.upload_file_rounded,
                            isLoading: _uploadingResume,
                            onPressed: _uploadingResume ? null : _uploadResume,
                          ),
                        ),
                        if (_resumePath != null) ...<Widget>[
                          const SizedBox(width: 10),
                          Expanded(
                            child: SecondaryActionButton(
                              label: 'Remove',
                              icon: Icons.close_rounded,
                              onPressed: () => setState(() => _resumePath = null),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                InlineErrorCard(message: _error!),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryActionButton(
                label: 'Save profile',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
