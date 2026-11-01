import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../models/app_profile.dart';
import '../models/contact_message.dart';
import '../models/project.dart';
import '../models/service.dart';
import '../models/skill.dart';
import '../models/timeline_entry.dart';

/// Owner-only operations. The Supabase client is still constrained by RLS —
/// this class assumes (and re-checks) that the signed-in user is the admin.
class AdminRepository {
  AdminRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _db => _client ?? SupabaseBootstrap.client;

  static const String profilesTable = 'profiles';
  static const String projectsTable = 'projects';
  static const String skillsTable = 'skills';
  static const String servicesTable = 'services';
  static const String timelineTable = 'timeline';
  static const String messagesTable = 'contact_messages';

  // -- Auth / role ------------------------------------------------------------

  Future<bool> isAdmin() async {
    try {
      final dynamic result = await _db.rpc('is_admin');
      return result == true;
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[AdminRepository.isAdmin] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not verify your admin access.');
    }
  }

  // -- Generic read -----------------------------------------------------------

  Future<List<T>> _select<T>(
    String table,
    T Function(Map<String, dynamic>) parse, {
    String orderBy = 'sort_order',
    bool ascending = true,
  }) async {
    try {
      final List<dynamic> rows =
          await _db.from(table).select().order(orderBy, ascending: ascending);
      return rows
          .whereType<Object>()
          .map((Object row) => parse(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[AdminRepository.$table] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not load $table.');
    }
  }

  Future<List<Project>> fetchAllProjects() =>
      _select<Project>(projectsTable, Project.fromJson);

  Future<List<Skill>> fetchSkills() => _select<Skill>(skillsTable, Skill.fromJson);

  Future<List<Service>> fetchServices() => _select<Service>(servicesTable, Service.fromJson);

  Future<List<TimelineEntry>> fetchTimeline() =>
      _select<TimelineEntry>(timelineTable, TimelineEntry.fromJson);

  Future<List<ContactMessage>> fetchMessages({MessageStatus? filter}) async {
    try {
      // Two explicit branches keep the query statically typed.
      final List<dynamic> rows = filter == null
          ? await _db
              .from(messagesTable)
              .select()
              .order('created_at', ascending: false)
              .limit(200)
          : await _db
              .from(messagesTable)
              .select()
              .eq('status', filter.value)
              .order('created_at', ascending: false)
              .limit(200);
      return rows
          .whereType<Object>()
          .map((Object row) => ContactMessage.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[AdminRepository.messages] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not load messages.');
    }
  }

  // -- Generic write ----------------------------------------------------------

  Future<Map<String, dynamic>> _insert(String table, Map<String, dynamic> payload) async {
    try {
      final List<dynamic> rows = await _db.from(table).insert(payload).select();
      if (rows.isEmpty) {
        throw const AppFailure('The item was saved but could not be read back.');
      }
      return Map<String, dynamic>.from(rows.first as Map);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[AdminRepository.insert:$table] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not save this item.');
    }
  }

  Future<void> _update(
    String table,
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _db.from(table).update(payload).eq('id', id);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[AdminRepository.update:$table] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not update this item.');
    }
  }

  Future<void> _delete(String table, String id) async {
    try {
      await _db.from(table).delete().eq('id', id);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[AdminRepository.delete:$table] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not delete this item.');
    }
  }

  // -- Projects ---------------------------------------------------------------

  Future<Project> saveProject(Project project) async {
    if (project.id.isEmpty) {
      final Map<String, dynamic> row = await _insert(projectsTable, project.toUpsertJson());
      return Project.fromJson(row);
    }
    await _update(projectsTable, project.id, project.toUpsertJson());
    return project;
  }

  Future<void> setProjectStatus(Project project, ProjectStatus status) =>
      _update(projectsTable, project.id, <String, dynamic>{'status': status.value});

  Future<void> setProjectFeatured(Project project, bool featured) =>
      _update(projectsTable, project.id, <String, dynamic>{'is_featured': featured});

  Future<void> deleteProject(String id) => _delete(projectsTable, id);

  /// Persists a new ordering. `sorted` is the full list in its new order.
  Future<void> reorderProjects(List<Project> sorted) async {
    await _reorder(
      projectsTable,
      sorted.map((Project p) => MapEntry<String, int>(p.id, p.sortOrder)).toList(),
    );
  }

  Future<void> reorderSkills(List<Skill> sorted) async {
    await _reorder(
      skillsTable,
      List<MapEntry<String, int>>.generate(
        sorted.length,
        (int i) => MapEntry<String, int>(sorted[i].id, i + 1),
      ),
    );
  }

  Future<void> reorderServices(List<Service> sorted) async {
    await _reorder(
      servicesTable,
      List<MapEntry<String, int>>.generate(
        sorted.length,
        (int i) => MapEntry<String, int>(sorted[i].id, i + 1),
      ),
    );
  }

  Future<void> reorderTimeline(List<TimelineEntry> sorted) async {
    await _reorder(
      timelineTable,
      List<MapEntry<String, int>>.generate(
        sorted.length,
        (int i) => MapEntry<String, int>(sorted[i].id, i + 1),
      ),
    );
  }

  Future<void> _reorder(String table, List<MapEntry<String, int>> orders) async {
    try {
      for (final MapEntry<String, int> entry in orders) {
        if (entry.key.isEmpty) continue;
        await _db.from(table).update(<String, dynamic>{'sort_order': entry.value}).eq(
              'id',
              entry.key,
            );
      }
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[AdminRepository.reorder:$table] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not save the new order.');
    }
  }

  // -- Skills / services / timeline ------------------------------------------

  Future<Skill> saveSkill(Skill skill) async {
    if (skill.id.isEmpty) {
      return Skill.fromJson(await _insert(skillsTable, skill.toUpsertJson()));
    }
    await _update(skillsTable, skill.id, skill.toUpsertJson());
    return skill;
  }

  Future<void> deleteSkill(String id) => _delete(skillsTable, id);

  Future<Service> saveService(Service service) async {
    if (service.id.isEmpty) {
      return Service.fromJson(await _insert(servicesTable, service.toUpsertJson()));
    }
    await _update(servicesTable, service.id, service.toUpsertJson());
    return service;
  }

  Future<void> deleteService(String id) => _delete(servicesTable, id);

  Future<TimelineEntry> saveTimelineEntry(TimelineEntry entry) async {
    if (entry.id.isEmpty) {
      return TimelineEntry.fromJson(await _insert(timelineTable, entry.toUpsertJson()));
    }
    await _update(timelineTable, entry.id, entry.toUpsertJson());
    return entry;
  }

  Future<void> deleteTimelineEntry(String id) => _delete(timelineTable, id);

  // -- Messages ---------------------------------------------------------------

  Future<void> setMessageStatus(String id, MessageStatus status) =>
      _update(messagesTable, id, <String, dynamic>{'status': status.value});

  Future<void> deleteMessage(String id) => _delete(messagesTable, id);

  Future<Map<String, int>> messageCounts() async {
    try {
      final List<dynamic> rows =
          await _db.from(messagesTable).select('status').limit(1000);
      final Map<String, int> counts = <String, int>{
        'unread': 0,
        'read': 0,
        'replied': 0,
        'archived': 0,
      };
      for (final dynamic row in rows) {
        if (row is Map) {
          final String key = (row['status'] as String? ?? 'unread');
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
      return counts;
    } catch (error) {
      throw ErrorMapper.map(error, fallback: 'Could not load message counts.');
    }
  }

  // -- Profile ----------------------------------------------------------------

  Future<AppProfile> fetchProfile() async {
    try {
      final List<dynamic> rows = await _db.from(profilesTable).select().limit(1);
      if (rows.isEmpty) {
        throw const AppFailure('No profile row exists yet. Run the seed migration first.');
      }
      return AppProfile.fromJson(Map<String, dynamic>.from(rows.first as Map));
    } catch (error, stack) {
      if (error is AppFailure) rethrow;
      if (kDebugMode) debugPrint('[AdminRepository.fetchProfile] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not load your profile.');
    }
  }

  Future<void> saveProfile(AppProfile profile) async {
    try {
      await _db.from(profilesTable).update(profile.toUpdateJson()).eq('id', profile.id);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[AdminRepository.saveProfile] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not save your profile.');
    }
  }

  // -- Storage ----------------------------------------------------------------

  /// Uploads an image to a public bucket and returns the object path.
  Future<String> uploadImage({
    required String bucket,
    required String folder,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      final String ext = _extensionOf(fileName, fallback: 'jpg');
      final String path =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_${_safeName(fileName, ext)}';
      await _db.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType ?? _contentTypeFor(ext),
              upsert: false,
            ),
          );
      return path;
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[AdminRepository.uploadImage] $error\n$stack');
      throw ErrorMapper.map(
        error,
        fallback: 'Upload failed. Check the storage bucket and your connection.',
      );
    }
  }

  String _extensionOf(String fileName, {required String fallback}) {
    final int dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return fallback;
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _safeName(String fileName, String ext) {
    final String base = fileName
        .replaceAll(RegExp(r'\.[^.]*$'), '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final String trimmed = base.length > 40 ? base.substring(0, 40) : base;
    return '${trimmed.isEmpty ? 'file' : trimmed}.$ext';
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
