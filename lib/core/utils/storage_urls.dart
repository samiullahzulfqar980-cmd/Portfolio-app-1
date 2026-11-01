import 'package:flutter/material.dart';

import '../config/app_env.dart';

/// Builds a public URL for an object inside a Supabase Storage bucket.
///
/// Buckets are created as *public* by the migrations (portfolio imagery is
/// public content), so a plain public URL keeps image widgets simple and
/// cache-friendly. Paths may already be absolute URLs (e.g. sample content
/// served from a CDN) — those are returned untouched.
class StorageUrl {
  const StorageUrl._();

  static const String profileBucket = 'profile-images';
  static const String projectBucket = 'project-images';
  static const String resumeBucket = 'resume-files';

  static bool isAbsolute(String? path) {
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://') || path.startsWith('asset:');
  }

  static String publicUrl(String bucket, String? objectPath) {
    if (objectPath == null || objectPath.trim().isEmpty) return '';
    final String path = objectPath.trim();
    if (path.startsWith('assets/')) return path;
    if (isAbsolute(path)) return path;
    final String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${AppEnv.supabaseUrl.replaceAll(RegExp(r'/+$'), '')}'
        '/storage/v1/object/public/$bucket/${Uri.encodeFull(cleanPath)}';
  }

  static String profileImage(String? objectPath) => publicUrl(profileBucket, objectPath);

  static String projectImage(String? objectPath) => publicUrl(projectBucket, objectPath);

  static String resume(String? objectPath) => publicUrl(resumeBucket, objectPath);
}

/// Convenience `ImageProvider` resolver: handles bundled assets, network URLs
/// and Supabase object paths in one place.
ImageProvider? resolveImageProvider(String? path, {String? bucket}) {
  if (path == null || path.trim().isEmpty) return null;
  final String value = path.trim();
  if (value.startsWith('assets/')) return AssetImage(value);
  String resolved = value;
  if (isRelativeStoragePath(value) && bucket != null) {
    resolved = StorageUrl.publicUrl(bucket, value);
  }
  if (resolved.startsWith('http')) return NetworkImage(resolved);
  return null;
}

bool isRelativeStoragePath(String value) =>
    !value.startsWith('http') && !value.startsWith('assets/');
