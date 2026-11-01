import 'package:flutter/foundation.dart';

import 'app_profile.dart';
import 'project.dart';
import 'service.dart';
import 'skill.dart';
import 'timeline_entry.dart';

/// Immutable snapshot of everything the public portfolio screens render.
@immutable
class PortfolioData {
  const PortfolioData({
    required this.profile,
    required this.projects,
    required this.skills,
    required this.services,
    required this.timeline,
    this.isPreview = false,
  });

  final AppProfile profile;
  final List<Project> projects;
  final List<Skill> skills;
  final List<Service> services;
  final List<TimelineEntry> timeline;

  /// True when this snapshot comes from the bundled demo content.
  final bool isPreview;

  List<Project> get publishedProjects =>
      projects.where((Project p) => p.isPublished).toList(growable: false);

  List<Project> get featuredProjects =>
      publishedProjects.where((Project p) => p.isFeatured).toList(growable: false);

  List<Project> latestProjects({int limit = 3}) {
    final List<Project> sorted = List<Project>.of(publishedProjects)
      ..sort((Project a, Project b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.take(limit).toList(growable: false);
  }

  List<String> get projectCategories {
    final Set<String> categories = <String>{};
    for (final Project project in publishedProjects) {
      if (project.category.trim().isNotEmpty) categories.add(project.category.trim());
    }
    final List<String> sorted = categories.toList()..sort();
    return sorted;
  }

  List<String> get projectTechnologies {
    final Set<String> tech = <String>{};
    for (final Project project in publishedProjects) {
      tech.addAll(project.technologies);
    }
    final List<String> sorted = tech.toList()..sort();
    return sorted;
  }

  List<TimelineEntry> get experience => timeline
      .where((TimelineEntry e) => e.kind == TimelineKind.experience)
      .toList(growable: false);

  List<TimelineEntry> get education => timeline
      .where((TimelineEntry e) => e.kind == TimelineKind.education)
      .toList(growable: false);

  List<Service> get publishedServices =>
      services.where((Service s) => s.isPublished).toList(growable: false);

  PortfolioData copyWith({
    AppProfile? profile,
    List<Project>? projects,
    List<Skill>? skills,
    List<Service>? services,
    List<TimelineEntry>? timeline,
    bool? isPreview,
  }) =>
      PortfolioData(
        profile: profile ?? this.profile,
        projects: projects ?? this.projects,
        skills: skills ?? this.skills,
        services: services ?? this.services,
        timeline: timeline ?? this.timeline,
        isPreview: isPreview ?? this.isPreview,
      );

  static PortfolioData empty(AppProfile profile) => PortfolioData(
        profile: profile,
        projects: const <Project>[],
        skills: const <Skill>[],
        services: const <Service>[],
        timeline: const <TimelineEntry>[],
      );
}
