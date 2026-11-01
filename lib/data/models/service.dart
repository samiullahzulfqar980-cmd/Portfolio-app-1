import 'package:flutter/foundation.dart';

import 'project.dart' show asInt, asStringList;

@immutable
class Service {
  const Service({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.sortOrder,
    this.technologies = const <String>[],
    this.isPublished = true,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final int sortOrder;
  final List<String> technologies;
  final bool isPublished;

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'].toString(),
        title: (json['title'] as String? ?? '').trim(),
        description: (json['description'] as String? ?? '').trim(),
        iconKey: (json['icon_key'] as String? ?? 'spark').trim(),
        sortOrder: asInt(json['sort_order']),
        technologies: asStringList(json['technologies']),
        isPublished: json['is_published'] as bool? ?? true,
      );

  Map<String, dynamic> toUpsertJson() => <String, dynamic>{
        'title': title,
        'description': description,
        'icon_key': iconKey,
        'sort_order': sortOrder,
        'technologies': technologies,
        'is_published': isPublished,
      };

  Service copyWith({
    String? title,
    String? description,
    String? iconKey,
    int? sortOrder,
    List<String>? technologies,
    bool? isPublished,
  }) =>
      Service(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        iconKey: iconKey ?? this.iconKey,
        sortOrder: sortOrder ?? this.sortOrder,
        technologies: technologies ?? this.technologies,
        isPublished: isPublished ?? this.isPublished,
      );

  static Service blank({int sortOrder = 0}) => Service(
        id: '',
        title: '',
        description: '',
        iconKey: 'spark',
        sortOrder: sortOrder,
      );
}
