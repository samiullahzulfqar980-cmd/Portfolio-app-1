import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_profile.dart';
import '../../data/models/portfolio_data.dart';
import '../../data/models/project.dart';
import '../../data/models/service.dart';
import '../../data/models/skill.dart';
import '../../data/models/timeline_entry.dart';
import '../../data/repositories/portfolio_repository.dart';
import 'app_providers.dart';

/// Loads (and can refresh) the public portfolio snapshot.
class PortfolioController extends AsyncNotifier<PortfolioData> {
  @override
  Future<PortfolioData> build() {
    return ref.watch(portfolioRepositoryProvider).load();
  }

  Future<void> refresh() async {
    state = const AsyncValue<PortfolioData>.loading();
    state = await AsyncValue.guard<PortfolioData>(
      () => ref.read(portfolioRepositoryProvider).load(),
    );
  }
}

final AsyncNotifierProvider<PortfolioController, PortfolioData> portfolioProvider =
    AsyncNotifierProvider<PortfolioController, PortfolioData>(PortfolioController.new);

/// Convenience selectors with sensible fallbacks while loading.
final Provider<AppProfile?> profileProvider = Provider<AppProfile?>((Ref ref) {
  return ref.watch(portfolioProvider).value?.profile;
});

final Provider<List<Project>> publishedProjectsProvider = Provider<List<Project>>((Ref ref) {
  return ref.watch(portfolioProvider).value?.publishedProjects ?? const <Project>[];
});

final Provider<List<Service>> servicesProvider = Provider<List<Service>>((Ref ref) {
  return ref.watch(portfolioProvider).value?.publishedServices ?? const <Service>[];
});

final Provider<List<Skill>> skillsProvider = Provider<List<Skill>>((Ref ref) {
  return ref.watch(portfolioProvider).value?.skills ?? const <Skill>[];
});

final Provider<List<TimelineEntry>> timelineProvider = Provider<List<TimelineEntry>>((Ref ref) {
  return ref.watch(portfolioProvider).value?.timeline ?? const <TimelineEntry>[];
});

/// Resolves a project by slug for the detail screen.
///
/// Uses the cached snapshot first; falls back to a direct fetch so deep links
/// opened from a notification still work before the portfolio finishes loading.
final projectBySlugProvider = FutureProvider.family<Project?, String>(
    (Ref ref, String slug) async {
  final PortfolioData? cached = ref.watch(portfolioProvider).value;
  if (cached != null) {
    for (final Project project in cached.projects) {
      if (project.slug == slug) return project;
    }
  }
  return ref.watch(portfolioRepositoryProvider).projectBySlug(slug);
});

final Provider<PortfolioRepository> repositoryProvider = portfolioRepositoryProvider;
