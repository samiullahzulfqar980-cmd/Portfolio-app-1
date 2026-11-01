import 'package:flutter/foundation.dart';

enum MessageStatus {
  unread,
  read,
  replied,
  archived;

  static MessageStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'read':
        return MessageStatus.read;
      case 'replied':
        return MessageStatus.replied;
      case 'archived':
        return MessageStatus.archived;
      default:
        return MessageStatus.unread;
    }
  }

  String get value => name;

  String get label => switch (this) {
        MessageStatus.unread => 'Unread',
        MessageStatus.read => 'Read',
        MessageStatus.replied => 'Replied',
        MessageStatus.archived => 'Archived',
      };
}

@immutable
class ContactMessage {
  const ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.status,
    required this.createdAt,
    this.subject,
    this.serviceInterest,
    this.budgetRange,
  });

  final String id;
  final String name;
  final String email;
  final String message;
  final MessageStatus status;
  final DateTime createdAt;
  final String? subject;
  final String? serviceInterest;
  final String? budgetRange;

  String get initials {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters2;
    return '${parts.first.characters2}${parts.last.characters2}';
  }

  factory ContactMessage.fromJson(Map<String, dynamic> json) => ContactMessage(
        id: json['id'].toString(),
        name: (json['name'] as String? ?? 'Unknown').trim(),
        email: (json['email'] as String? ?? '').trim(),
        message: (json['message'] as String? ?? '').trim(),
        subject: (json['subject'] as String?)?.trim(),
        serviceInterest: (json['service_interest'] as String?)?.trim(),
        budgetRange: (json['budget_range'] as String?)?.trim(),
        status: MessageStatus.parse(json['status'] as String?),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toInsertJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'message': message,
        'subject': subject,
        'service_interest': serviceInterest,
        'budget_range': budgetRange,
      };

  ContactMessage copyWith({MessageStatus? status}) => ContactMessage(
        id: id,
        name: name,
        email: email,
        message: message,
        status: status ?? this.status,
        createdAt: createdAt,
        subject: subject,
        serviceInterest: serviceInterest,
        budgetRange: budgetRange,
      );
}

extension on String {
  String get characters2 => isEmpty ? '?' : substring(0, 1).toUpperCase();
}
