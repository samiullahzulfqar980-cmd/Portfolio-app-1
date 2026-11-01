import 'package:flutter/foundation.dart';

@immutable
class SocialLink {
  const SocialLink({required this.key, required this.label, required this.url});

  final String key;
  final String label;
  final String url;

  static SocialLink? tryParse(String key, dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return SocialLink(key: key, label: _labelFor(key), url: value.trim());
    }
    if (value is Map) {
      final String? url = value['url'] as String?;
      if (url == null || url.trim().isEmpty) return null;
      final String? label = value['label'] as String?;
      return SocialLink(
        key: key,
        label: label?.trim().isNotEmpty == true ? label!.trim() : _labelFor(key),
        url: url.trim(),
      );
    }
    return null;
  }

  static String _labelFor(String key) {
    switch (key) {
      case 'github':
        return 'GitHub';
      case 'x':
      case 'twitter':
        return 'X / Twitter';
      case 'whatsapp':
        return 'WhatsApp';
      case 'email':
        return 'Email';
      case 'website':
        return 'Website';
      case 'dribbble':
        return 'Dribbble';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'url': url, 'label': label};

  static const List<String> supportedKeys = <String>[
    'github',
    'whatsapp',
    'x',
    'website',
    'dribbble',
  ];
}

@immutable
class ProfileStat {
  const ProfileStat({required this.label, required this.value, this.iconKey});

  final String label;
  final String value;
  final String? iconKey;

  factory ProfileStat.fromJson(Map<String, dynamic> json) => ProfileStat(
        label: (json['label'] as String? ?? '').trim(),
        value: (json['value'] as String? ?? '').trim(),
        iconKey: json['icon'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'value': value,
        if (iconKey != null) 'icon': iconKey,
      };
}

@immutable
class AppProfile {
  const AppProfile({
    required this.id,
    required this.fullName,
    required this.headline,
    required this.roles,
    required this.shortIntro,
    required this.bio,
    required this.availabilityStatus,
    required this.email,
    required this.socialLinks,
    this.availabilityNote,
    this.phone,
    this.location,
    this.timezone,
    this.avatarPath,
    this.resumePath,
    this.stats = const <ProfileStat>[],
  });

  final String id;
  final String fullName;
  final String headline;
  final List<String> roles;
  final String shortIntro;
  final String bio;
  final String availabilityStatus;
  final String? availabilityNote;
  final String email;
  final String? phone;
  final String? location;
  final String? timezone;
  final Map<String, SocialLink> socialLinks;
  final String? avatarPath;
  final String? resumePath;
  final List<ProfileStat> stats;

  bool get isAvailable {
    final String s = availabilityStatus.toLowerCase();
    return s.contains('available') || s.contains('open');
  }

  String get primaryRole => roles.isNotEmpty ? roles.first : headline;

  /// The WhatsApp entry from [socialLinks], when the owner has added one.
  SocialLink? get whatsappLink => socialLinks['whatsapp'];

  /// The website entry from [socialLinks], when the owner has added one.
  SocialLink? get websiteLink => socialLinks['website'];

  /// Website address without the scheme, e.g. `portfolio.example.com`.
  String? get websiteHost {
    final String raw = websiteLink?.url ?? '';
    if (raw.trim().isEmpty) return null;
    final Uri? uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.host.isEmpty) {
      return raw.replaceFirst(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/+$'), '');
    }
    return uri.host;
  }

  /// Human-readable WhatsApp number, e.g. `+923470563895` -> `+92 347 0563895`.
  ///
  /// Returns null when no WhatsApp link exists. Numbers that are stored as a
  /// `wa.me` link are extracted; anything unparseable is shown as-is.
  String? get whatsappDisplay {
    final String raw = whatsappLink?.url ?? '';
    if (raw.trim().isEmpty) return null;
    final String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) return raw;
    // `+923470563895` -> `+92 347 0563895` (country code + mobile prefix + line).
    // Unusual lengths fall back to plain 3-digit grouping.
    final String country = digits.substring(0, 2);
    final String rest = digits.substring(2);
    if (rest.length == 10) {
      return '+$country ${rest.substring(0, 3)} ${rest.substring(3)}';
    }
    final List<String> chunks = <String>[];
    for (int i = 0; i < rest.length; i += 3) {
      chunks.add(rest.substring(i, i + 3 > rest.length ? rest.length : i + 3));
    }
    return '+$country ${chunks.join(' ')}';
  }

  List<SocialLink> get orderedSocialLinks {
    const List<String> order = <String>['github', 'whatsapp', 'website', 'x', 'dribbble'];
    final List<SocialLink> links = socialLinks.values.toList();
    links.sort((SocialLink a, SocialLink b) {
      final int ai = order.indexOf(a.key);
      final int bi = order.indexOf(b.key);
      return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
    });
    return links;
  }

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    final List<String> roles = <String>[];
    final dynamic rawRoles = json['roles'];
    if (rawRoles is List) {
      for (final dynamic r in rawRoles) {
        if (r is String && r.trim().isNotEmpty) roles.add(r.trim());
      }
    }
    final String? headline = (json['headline'] as String?)?.trim();
    if (roles.isEmpty && headline != null && headline.isNotEmpty) roles.add(headline);

    final Map<String, SocialLink> links = <String, SocialLink>{};
    final dynamic rawLinks = json['social_links'];
    if (rawLinks is Map) {
      rawLinks.forEach((dynamic key, dynamic value) {
        final SocialLink? link = SocialLink.tryParse(key.toString(), value);
        if (link != null) links[link.key] = link;
      });
    }

    final List<ProfileStat> stats = <ProfileStat>[];
    final dynamic rawStats = json['stats'];
    if (rawStats is List) {
      for (final dynamic s in rawStats) {
        if (s is Map) stats.add(ProfileStat.fromJson(Map<String, dynamic>.from(s)));
      }
    }

    return AppProfile(
      id: json['id'] as String? ?? 'owner',
      fullName: (json['full_name'] as String? ?? 'Your Name').trim(),
      headline: headline ?? roles.join(' • '),
      roles: roles,
      shortIntro: (json['short_intro'] as String? ?? '').trim(),
      bio: (json['bio'] as String? ?? '').trim(),
      availabilityStatus: (json['availability_status'] as String? ?? 'open').trim(),
      availabilityNote: (json['availability_note'] as String?)?.trim(),
      email: (json['email'] as String? ?? '').trim(),
      phone: (json['phone'] as String?)?.trim(),
      location: (json['location'] as String?)?.trim(),
      timezone: (json['timezone'] as String?)?.trim(),
      socialLinks: links,
      avatarPath: (json['avatar_path'] as String?)?.trim(),
      resumePath: (json['resume_path'] as String?)?.trim(),
      stats: stats,
    );
  }

  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
        'full_name': fullName,
        'headline': headline,
        'roles': roles,
        'short_intro': shortIntro,
        'bio': bio,
        'availability_status': availabilityStatus,
        'availability_note': availabilityNote,
        'email': email,
        'phone': phone,
        'location': location,
        'timezone': timezone,
        'social_links': socialLinks.map(
          (String key, SocialLink value) => MapEntry<String, dynamic>(key, value.toJson()),
        ),
        'avatar_path': avatarPath,
        'resume_path': resumePath,
        'stats': stats.map((ProfileStat s) => s.toJson()).toList(),
      };
}
