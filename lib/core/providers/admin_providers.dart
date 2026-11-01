import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_profile.dart';
import '../../data/models/contact_message.dart';
import '../../data/models/project.dart';
import '../../data/models/service.dart';
import '../../data/models/skill.dart';
import '../../data/models/timeline_entry.dart';
import 'app_providers.dart';
import 'content_providers.dart';

/// Admin data is intentionally separate from the public snapshot so drafts and
/// inbox items are only fetched for the authenticated owner.

final FutureProvider<List<Project>> adminProjectsProvider = FutureProvider<List<Project>>(
  (Ref ref) async {
    // Re-fetch when the signed-in user changes.
    ref.watch(authUserProvider);
    return ref.watch(adminRepositoryProvider).fetchAllProjects();
  },
);

final FutureProvider<List<Skill>> adminSkillsProvider = FutureProvider<List<Skill>>(
  (Ref ref) async {
    ref.watch(authUserProvider);
    return ref.watch(adminRepositoryProvider).fetchSkills();
  },
);

final FutureProvider<List<Service>> adminServicesProvider = FutureProvider<List<Service>>(
  (Ref ref) async {
    ref.watch(authUserProvider);
    return ref.watch(adminRepositoryProvider).fetchServices();
  },
);

final FutureProvider<List<TimelineEntry>> adminTimelineProvider =
    FutureProvider<List<TimelineEntry>>((Ref ref) async {
  ref.watch(authUserProvider);
  return ref.watch(adminRepositoryProvider).fetchTimeline();
});

final FutureProvider<List<ContactMessage>> adminMessagesProvider =
    FutureProvider<List<ContactMessage>>((Ref ref) async {
  ref.watch(authUserProvider);
  return ref.watch(adminRepositoryProvider).fetchMessages();
});

final FutureProvider<Map<String, int>> messageCountsProvider = FutureProvider<Map<String, int>>(
  (Ref ref) async {
    ref.watch(authUserProvider);
    ref.watch(adminMessagesProvider);
    return ref.watch(adminRepositoryProvider).messageCounts();
  },
);

final FutureProvider<AppProfile> adminProfileProvider = FutureProvider<AppProfile>((Ref ref) async {
  ref.watch(authUserProvider);
  return ref.watch(adminRepositoryProvider).fetchProfile();
});

/// Invalidates every admin cache plus the public snapshot after a mutation.
void invalidateAdminCaches(WidgetRef ref) {
  ref.invalidate(adminProjectsProvider);
  ref.invalidate(adminSkillsProvider);
  ref.invalidate(adminServicesProvider);
  ref.invalidate(adminTimelineProvider);
  ref.invalidate(adminMessagesProvider);
  ref.invalidate(messageCountsProvider);
  ref.invalidate(adminProfileProvider);
}

void invalidatePublicContent(WidgetRef ref) {
  ref.invalidate(portfolioProvider);
}
