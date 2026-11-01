import 'package:flutter/foundation.dart';

import 'project.dart' show asInt;

enum TimelineKind {
  experience,
  education;

  static TimelineKind parse(String? raw) =>
      (raw ?? '').toLowerCase() == 'education' ? TimelineKind.education : TimelineKind.experience;

  String get value => name;

  String get label => this == TimelineKind.education ? 'Education' : 'Experience';
}

@immutable
class TimelineEntry {
  const TimelineEntry({
    required this.id,
    required this.kind,
    required this.organization,
    required this.role,
    required this.startLabel,
    required this.sortOrder,
    this.endLabel,
    this.isCurrent = false,
    this.description,
    this.location,
  });

  final String id;
  final TimelineKind kind;

  /// Company or institution.
  final String organization;

  /// Job title or qualification.
  final String role;
  final String startLabel;
  final String? endLabel;
  final bool isCurrent;
  final String? description;
  final String? location;
  final int sortOrder;

  String get period => isCurrent ? '$startLabel — Present' : '$startLabel — ${endLabel ?? 'Present'}';

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => TimelineEntry(
        id: json['id'].toString(),
        kind: TimelineKind.parse(json['kind'] as String?),
        organization: (json['organization'] as String? ?? '').trim(),
        role: (json['role'] as String? ?? '').trim(),
        startLabel: (json['start_label'] as String? ?? '').trim(),
        endLabel: (json['end_label'] as String?)?.trim(),
        isCurrent: json['is_current'] as bool? ?? false,
        description: (json['description'] as String?)?.trim(),
        location: (json['location'] as String?)?.trim(),
        sortOrder: asInt(json['sort_order']),
      );

  Map<String, dynamic> toUpsertJson() => <String, dynamic>{
        'kind': kind.value,
        'organization': organization,
        'role': role,
        'start_label': startLabel,
        'end_label': endLabel,
        'is_current': isCurrent,
        'description': description,
        'location': location,
        'sort_order': sortOrder,
      };

  TimelineEntry copyWith({
    TimelineKind? kind,
    String? organization,
    String? role,
    String? startLabel,
    String? endLabel,
    bool? isCurrent,
    String? description,
    String? location,
    int? sortOrder,
  }) =>
      TimelineEntry(
        id: id,
        kind: kind ?? this.kind,
        organization: organization ?? this.organization,
        role: role ?? this.role,
        startLabel: startLabel ?? this.startLabel,
        endLabel: endLabel ?? this.endLabel,
        isCurrent: isCurrent ?? this.isCurrent,
        description: description ?? this.description,
        location: location ?? this.location,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  static TimelineEntry blank({
    TimelineKind kind = TimelineKind.experience,
    int sortOrder = 0,
  }) =>
      TimelineEntry(
        id: '',
        kind: kind,
        organization: '',
        role: '',
        startLabel: '',
        sortOrder: sortOrder,
      );
}
