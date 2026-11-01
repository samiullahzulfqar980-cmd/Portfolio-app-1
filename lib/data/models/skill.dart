import 'package:flutter/foundation.dart';

import 'project.dart' show asInt;

@immutable
class Skill {
  const Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.proficiency,
    required this.sortOrder,
    this.note,
  });

  final String id;
  final String name;
  final String category;
  final int proficiency;
  final int sortOrder;
  final String? note;

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'].toString(),
        name: (json['name'] as String? ?? '').trim(),
        category: (json['category'] as String? ?? 'General').trim(),
        proficiency: asInt(json['proficiency']).clamp(0, 100).toInt(),
        sortOrder: asInt(json['sort_order']),
        note: (json['note'] as String?)?.trim(),
      );

  Map<String, dynamic> toUpsertJson() => <String, dynamic>{
        'name': name,
        'category': category,
        'proficiency': proficiency,
        'sort_order': sortOrder,
        'note': note,
      };

  Skill copyWith({
    String? name,
    String? category,
    int? proficiency,
    int? sortOrder,
    String? note,
  }) =>
      Skill(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        proficiency: proficiency ?? this.proficiency,
        sortOrder: sortOrder ?? this.sortOrder,
        note: note ?? this.note,
      );

  static Skill blank({String category = 'Mobile', int sortOrder = 0}) => Skill(
        id: '',
        name: '',
        category: category,
        proficiency: 70,
        sortOrder: sortOrder,
      );
}

/// Groups skills by category while preserving the author-defined order.
Map<String, List<Skill>> groupSkills(List<Skill> skills) {
  final List<Skill> sorted = List<Skill>.of(skills)
    ..sort((Skill a, Skill b) => a.sortOrder.compareTo(b.sortOrder));
  final Map<String, List<Skill>> grouped = <String, List<Skill>>{};
  for (final Skill skill in sorted) {
    grouped.putIfAbsent(skill.category, () => <Skill>[]).add(skill);
  }
  return grouped;
}
