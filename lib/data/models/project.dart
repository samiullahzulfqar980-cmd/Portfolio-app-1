import 'package:flutter/foundation.dart';

enum ProjectStatus {
  draft,
  published;

  static ProjectStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'published':
        return ProjectStatus.published;
      default:
        return ProjectStatus.draft;
    }
  }

  String get value => name;

  String get label => this == ProjectStatus.published ? 'Published' : 'Draft';
}

@immutable
class Project {
  const Project({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    required this.description,
    required this.category,
    required this.technologies,
    required this.status,
    required this.sortOrder,
    this.imagePath,
    this.demoUrl,
    this.repoUrl,
    this.isFeatured = false,
    this.year,
    this.accentKey,
    this.createdAt,
  });

  final String id;
  final String title;
  final String slug;
  final String summary;
  final String description;
  final String category;
  final List<String> technologies;
  final ProjectStatus status;
  final int sortOrder;
  final String? imagePath;
  final String? demoUrl;
  final String? repoUrl;
  final bool isFeatured;
  final String? year;
  final String? accentKey;
  final DateTime? createdAt;

  bool get isPublished => status == ProjectStatus.published;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'].toString(),
      title: (json['title'] as String? ?? 'Untitled').trim(),
      slug: (json['slug'] as String? ?? '').trim(),
      summary: (json['summary'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? 'General').trim(),
      technologies: _stringList(json['technologies']),
      status: ProjectStatus.parse(json['status'] as String?),
      sortOrder: _asInt(json['sort_order']),
      imagePath: (json['image_path'] as String?)?.trim(),
      demoUrl: (json['demo_url'] as String?)?.trim(),
      repoUrl: (json['repo_url'] as String?)?.trim(),
      isFeatured: json['is_featured'] as bool? ?? false,
      year: (json['year'] as String?)?.trim(),
      accentKey: json['accent'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toUpsertJson() => <String, dynamic>{
        'title': title,
        'slug': slug,
        'summary': summary,
        'description': description,
        'category': category,
        'technologies': technologies,
        'status': status.value,
        'sort_order': sortOrder,
        'image_path': imagePath,
        'demo_url': demoUrl,
        'repo_url': repoUrl,
        'is_featured': isFeatured,
        'year': year,
        'accent': accentKey,
      };

  Project copyWith({
    String? title,
    String? slug,
    String? summary,
    String? description,
    String? category,
    List<String>? technologies,
    ProjectStatus? status,
    int? sortOrder,
    String? imagePath,
    String? demoUrl,
    String? repoUrl,
    bool? isFeatured,
    String? year,
    String? accentKey,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      category: category ?? this.category,
      technologies: technologies ?? this.technologies,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      imagePath: imagePath ?? this.imagePath,
      demoUrl: demoUrl ?? this.demoUrl,
      repoUrl: repoUrl ?? this.repoUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      year: year ?? this.year,
      accentKey: accentKey ?? this.accentKey,
      createdAt: createdAt,
    );
  }

  static Project blank({int sortOrder = 0}) => Project(
        id: '',
        title: '',
        slug: '',
        summary: '',
        description: '',
        category: 'Mobile',
        technologies: const <String>[],
        status: ProjectStatus.draft,
        sortOrder: sortOrder,
      );
}

List<String> _stringList(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Object>()
        .map((Object e) => e.toString().trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return raw
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

int _asInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? 0;
  return 0;
}

List<String> asStringList(dynamic raw) => _stringList(raw);
int asInt(dynamic raw) => _asInt(raw);
