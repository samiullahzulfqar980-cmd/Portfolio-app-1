import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/storage_urls.dart';

/// Avatar that accepts a bundled asset, a network URL or a Supabase object
/// path, and degrades to elegant initials.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imagePath,
    required this.name,
    this.size = 72,
    this.showRing = true,
    this.bucket = StorageUrl.profileBucket,
  });

  final String? imagePath;
  final String name;
  final double size;
  final bool showRing;
  final String bucket;

  String get _initials {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? provider = resolveImageProvider(imagePath, bucket: bucket);

    final Widget inner = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: provider == null
            ? _Initials(initials: _initials, size: size)
            : Image(
                image: provider,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                    _Initials(initials: _initials, size: size),
              ),
      ),
    );

    if (!showRing) return inner;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: AppColors.triGradient),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
        child: inner,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2A2154), Color(0xFF12303A)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppType.headlineMedium(color: AppColors.textPrimary)
              .copyWith(fontSize: size * 0.34, letterSpacing: 1),
        ),
      ),
    );
  }
}

/// Rounded cover image with a gradient placeholder + graceful error state.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    this.imagePath,
    this.height = 168,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.bucket = StorageUrl.projectBucket,
    this.accent = AppColors.primary,
    this.fit = BoxFit.cover,
  });

  final String? imagePath;
  final double height;
  final BorderRadius borderRadius;
  final String bucket;
  final Color accent;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? provider = resolveImageProvider(imagePath, bucket: bucket);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    accent.withValues(alpha: 0.35),
                    const Color(0xFF0A0F1D),
                  ],
                ),
              ),
            ),
            if (provider != null)
              Image(
                image: provider,
                fit: fit,
                filterQuality: FilterQuality.medium,
                errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                    const SizedBox.shrink(),
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? progress,
                ) {
                  if (progress == null) return child;
                  return const _CoverLoading();
                },
              ),
            // Bottom scrim keeps overlaid text readable.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: height * 0.45,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0),
                        AppColors.background.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverLoading extends StatelessWidget {
  const _CoverLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
      ),
    );
  }
}
