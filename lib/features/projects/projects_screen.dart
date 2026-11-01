import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/motion.dart';
import '../../core/providers/content_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/portfolio_data.dart';
import '../../data/models/project.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/project_card.dart';
import '../../shared/widgets/state_views.dart';

/// Searchable, filterable project list. Filter state is local to the screen so
/// it survives tab switches (the branch keeps its state alive).
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _category;
  String? _technology;
  bool _featuredOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Project> _filter(List<Project> projects) {
    final String query = _query.trim().toLowerCase();
    return projects.where((Project project) {
      if (_featuredOnly && !project.isFeatured) return false;
      if (_category != null && project.category != _category) return false;
      if (_technology != null && !project.technologies.contains(_technology)) return false;
      if (query.isEmpty) return true;
      final String haystack = <String>[
        project.title,
        project.summary,
        project.description,
        project.category,
        project.technologies.join(' '),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
      _technology = null;
      _featuredOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PortfolioData> portfolio = ref.watch(portfolioProvider);

    return AppPage(
      appBar: AuroraAppBar(
        showBackButton: false,
        titleSpacing: AppSpacing.gutter(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('WORK', style: AppType.overline(color: AppColors.accentSoft)),
            Text('Projects', style: AppType.headlineLarge()),
          ],
        ),
      ),
      body: portfolio.when(
        loading: () => const ListSkeleton(count: 4, height: 132),
        error: (Object error, StackTrace stack) => ErrorStateView(
          error: error,
          onRetry: () => ref.read(portfolioProvider.notifier).refresh(),
        ),
        data: (PortfolioData data) {
          final List<Project> projects = data.publishedProjects;
          final List<Project> filtered = _filter(projects);
          final double gutter = AppSpacing.gutter(context);

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.read(portfolioProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SearchField(
                          controller: _searchController,
                          onChanged: (String value) => setState(() => _query = value),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            children: <Widget>[
                              TagChip(
                                label: 'All',
                                selected: _category == null && !_featuredOnly,
                                onTap: () => setState(() {
                                  _category = null;
                                  _featuredOnly = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              TagChip(
                                label: 'Featured',
                                icon: Icons.auto_awesome_rounded,
                                selected: _featuredOnly,
                                onTap: () => setState(() => _featuredOnly = !_featuredOnly),
                              ),
                              for (final String category in data.projectCategories) ...<Widget>[
                                const SizedBox(width: 8),
                                TagChip(
                                  label: category,
                                  selected: _category == category,
                                  onTap: () => setState(
                                    () => _category = _category == category ? null : category,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (data.projectTechnologies.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    'Stack',
                                    style: AppType.labelSmall(color: AppColors.textMuted),
                                  ),
                                ),
                                for (final String tech in data.projectTechnologies.take(8)) ...<Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: TagChip(
                                      label: tech,
                                      selected: _technology == tech,
                                      onTap: () => setState(
                                        () => _technology = _technology == tech ? null : tech,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                '${filtered.length} ${filtered.length == 1 ? 'project' : 'projects'}',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.labelSmall(color: AppColors.textSecondary),
                              ),
                            ),
                            if (_query.isNotEmpty || _category != null || _technology != null || _featuredOnly) ...<Widget>[
                              const SizedBox(width: 6),
                              Flexible(
                                child: TextButton(
                                  onPressed: _resetFilters,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Clear filters',
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (data.isPreview)
                              StatusChip(label: 'Sample data', tone: AppColors.warning),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
                if (projects.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      title: 'No projects published',
                      message: 'New work will show up here once it is published.',
                      icon: Icons.grid_view_rounded,
                      actionLabel: data.isPreview ? null : 'Retry',
                      onAction: data.isPreview
                          ? null
                          : () => ref.read(portfolioProvider.notifier).refresh(),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      title: 'Nothing matches that',
                      message: 'Try a different keyword, or clear the filters to see every project.',
                      icon: Icons.search_off_rounded,
                      actionLabel: 'Clear filters',
                      onAction: _resetFilters,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 120),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: AppSpacing.sm + 2),
                      itemBuilder: (BuildContext context, int index) {
                        return AnimatedEntry(
                          index: index.clamp(0, 8).toInt(),
                          offsetY: 10,
                          child: ProjectListTile(
                            project: filtered[index],
                            onTap: () => context.push(AppRoutes.project(filtered[index].slug)),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Search projects',
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppType.bodyLarge(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by name, stack or category',
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(Icons.search_rounded, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (BuildContext context, TextEditingValue value, Widget? child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              );
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
