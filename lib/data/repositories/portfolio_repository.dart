import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_env.dart';
import '../../core/errors/app_failure.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../demo/demo_content.dart';
import '../models/app_profile.dart';
import '../models/portfolio_data.dart';
import '../models/project.dart';
import '../models/service.dart';
import '../models/skill.dart';
import '../models/timeline_entry.dart';

/// Reads the public portfolio. Visitors never need to sign in; RLS guarantees
/// only published rows are visible to the anon key.
class PortfolioRepository {
  PortfolioRepository({SupabaseClient? client, bool? useBackend})
      : _client = client,
        _useBackend = useBackend ?? (AppEnv.isConfiguredHttp && SupabaseBootstrap.isReady);

  final SupabaseClient? _client;
  final bool _useBackend;

  SupabaseClient get _db => _client ?? SupabaseBootstrap.client;

  bool get isPreviewMode => !_useBackend;

  Future<PortfolioData> load() async {
    if (!_useBackend) {
      // Small delay so preview mode still exercises loading states.
      await Future<void>.delayed(const Duration(milliseconds: 260));
      return DemoContent.portfolio();
    }

    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        _db.from('profiles').select().limit(1),
        _db.from('projects').select().eq('status', 'published').order('sort_order'),
        _db.from('skills').select().order('sort_order'),
        _db.from('services').select().eq('is_published', true).order('sort_order'),
        _db.from('timeline').select().order('sort_order'),
      ]);

      final dynamic rawProfileRows = results[0];
      if (rawProfileRows is! List || rawProfileRows.isEmpty) {
        throw const AppFailure(
          'No profile row found. Run the seed migration or create your profile in the admin area.',
          code: 'missing_profile',
        );
      }

      return PortfolioData(
        profile: AppProfile.fromJson(
          Map<String, dynamic>.from(rawProfileRows.first as Map),
        ),
        projects: _mapList(results[1], Project.fromJson),
        skills: _mapList(results[2], Skill.fromJson),
        services: _mapList(results[3], Service.fromJson),
        timeline: _mapList(results[4], TimelineEntry.fromJson),
      );
    } on AppFailure {
      rethrow;
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[PortfolioRepository.load] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not load the portfolio. Pull to retry.');
    }
  }

  Future<Project?> projectBySlug(String slug) async {
    if (!_useBackend) {
      final List<Project> projects = DemoContent.projects();
      for (final Project project in projects) {
        if (project.slug == slug) return project;
      }
      return null;
    }
    try {
      final List<dynamic> rows = await _db
          .from('projects')
          .select()
          .eq('slug', slug)
          .eq('status', 'published')
          .limit(1);
      if (rows.isEmpty) return null;
      return Project.fromJson(Map<String, dynamic>.from(rows.first as Map));
    } catch (error) {
      throw ErrorMapper.map(error, fallback: 'Could not open that project.');
    }
  }

  List<T> _mapList<T>(dynamic rows, T Function(Map<String, dynamic>) parse) {
    if (rows is! List) return <T>[];
    return rows
        .whereType<Object>()
        .map((Object row) => parse(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }
}
