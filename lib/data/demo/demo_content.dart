import '../models/app_profile.dart';
import '../models/portfolio_data.dart';
import '../models/project.dart';
import '../models/service.dart';
import '../models/skill.dart';
import '../models/timeline_entry.dart';

/// Offline preview content.
///
/// This mirrors `supabase/seed.sql` and exists so the app is fully explorable
/// before Supabase is configured. Every value here is a **placeholder** and is
/// editable from the in-app admin area once Supabase is connected.
class DemoContent {
  const DemoContent._();

  static const String _sampleNote =
      'Sample content — edit this from the admin area once Supabase is connected.';

  static PortfolioData portfolio() => PortfolioData(
        profile: profile(),
        projects: projects(),
        skills: skills(),
        services: services(),
        timeline: timeline(),
        isPreview: true,
      );

  static AppProfile profile() => const AppProfile(
        id: 'owner',
        fullName: 'Samiullah Zulfqar',
        headline: 'Mobile & Web App Developer',
        roles: <String>['Flutter Developer', 'React Native Engineer', 'Full-Stack Web'],
        shortIntro:
            'I design and build fast, accessible cross-platform apps and the web platforms behind them.',
        bio: 'I am a software developer focused on cross-platform mobile apps with Flutter and '
            'React Native, plus the web front ends and APIs that support them.\n\n'
            'I care about the details that make software feel premium: 60fps motion, clear '
            'information hierarchy, accessible contrast, honest loading states and code that is '
            'easy for the next engineer to change.\n\n'
            '$_sampleNote',
        availabilityStatus: 'available',
        availabilityNote: 'Open to freelance projects and full-time roles',
        email: 'samiullahzulfqar980@gmail.com',
        phone: null,
        location: 'Islamabad, Pakistan',
        timezone: 'UTC+5',
        avatarPath: 'assets/images/avatar.png',
        resumePath: null,
        socialLinks: <String, SocialLink>{
          'github': SocialLink(
            key: 'github',
            label: 'GitHub',
            url: 'https://github.com/samiullahzulfqar980-cmd',
          ),
          'whatsapp': SocialLink(
            key: 'whatsapp',
            label: 'WhatsApp',
            url: '+923470563895',
          ),
          'website': SocialLink(
            key: 'website',
            label: 'Website',
            url: 'https://portfolio-website-six-rosy-97.vercel.app/',
          ),
        },
        stats: <ProfileStat>[
          ProfileStat(label: 'Focus', value: 'Mobile + Web', iconKey: 'mobile'),
          ProfileStat(label: 'Stack', value: 'Flutter · RN · TS', iconKey: 'web'),
          ProfileStat(label: 'Based in', value: 'Islamabad, PK', iconKey: 'cloud'),
        ],
      );

  static List<Project> projects() => const <Project>[
        Project(
          id: 'demo-1',
          title: 'FinPulse — Fintech Wallet',
          slug: 'finpulse-fintech-wallet',
          summary:
              'A cross-platform wallet concept with a live market feed, budget insights and biometric unlock.',
          description:
              'FinPulse explores what a calm, trustworthy fintech app feels like. The home screen '
              'leads with balance and cashflow instead of charts, motion is used to explain change '
              'rather than decorate it, and every destructive action is guarded.\n\n'
              'Built as a reference architecture: feature-first folder structure, repository layer, '
              'typed API models and a design system that adapts to small phones and large text.\n\n'
              '$_sampleNote',
          category: 'Mobile',
          technologies: <String>['Flutter', 'Dart', 'Riverpod', 'Supabase'],
          status: ProjectStatus.published,
          sortOrder: 1,
          imagePath: 'assets/images/projects/finpulse.png',
          demoUrl: 'https://github.com/samiullahzulfqar980-cmd',
          repoUrl: 'https://github.com/samiullahzulfqar980-cmd',
          isFeatured: true,
          year: '2025',
          accentKey: 'violet',
        ),
        Project(
          id: 'demo-2',
          title: 'DevFlow — Developer Workspace',
          slug: 'devflow-developer-workspace',
          summary:
              'A web workspace for snippets, reviews and release notes with keyboard-first navigation.',
          description:
              'DevFlow is a full-stack web app for small engineering teams: searchable snippets, a '
              'review queue and release notes that render from a single source of truth.\n\n'
              'The interesting engineering is in the data layer — Postgres full-text search, '
              'row-level security per workspace and optimistic UI that survives a dropped '
              'websocket.\n\n'
              '$_sampleNote',
          category: 'Web',
          technologies: <String>['Next.js', 'TypeScript', 'PostgreSQL', 'Tailwind'],
          status: ProjectStatus.published,
          sortOrder: 2,
          imagePath: 'assets/images/projects/devflow.png',
          demoUrl: 'https://github.com/samiullahzulfqar980-cmd',
          repoUrl: 'https://github.com/samiullahzulfqar980-cmd',
          isFeatured: true,
          year: '2025',
          accentKey: 'cyan',
        ),
        Project(
          id: 'demo-3',
          title: 'FoodExpress — Delivery',
          slug: 'foodexpress-delivery',
          summary:
              'On-demand delivery flow with live order tracking, driver handoff states and offline menus.',
          description:
              'A delivery app concept built around the 40 seconds that actually matter: choosing, '
              'paying and knowing where the order is.\n\n'
              'Offline-first cart, deterministic order state machine, and a map view that degrades '
              'gracefully when the network is slow.\n\n'
              '$_sampleNote',
          category: 'Mobile',
          technologies: <String>['React Native', 'Expo', 'Node.js', 'MongoDB'],
          status: ProjectStatus.published,
          sortOrder: 3,
          imagePath: 'assets/images/projects/foodexpress.png',
          repoUrl: 'https://github.com/samiullahzulfqar980-cmd',
          year: '2024',
          accentKey: 'amber',
        ),
        Project(
          id: 'demo-4',
          title: 'Aura — Interactive Storefront',
          slug: 'aura-interactive-storefront',
          summary:
              'A 3D product customiser that stays under budget on mid-range phones.',
          description:
              'A storefront experiment: real-time product materials, lighting presets and a '
              'checkout that never blocks the viewport.\n\n'
              'Progressive loading, texture budgets and a reduced-motion fallback are what make it '
              'usable on real devices rather than only on a laptop.\n\n'
              '$_sampleNote',
          category: 'Web',
          technologies: <String>['React', 'Three.js', 'WebGL', 'Stripe'],
          status: ProjectStatus.published,
          sortOrder: 4,
          imagePath: 'assets/images/projects/aura3d.png',
          demoUrl: 'https://github.com/samiullahzulfqar980-cmd',
          year: '2024',
          accentKey: 'rose',
        ),
        Project(
          id: 'demo-5',
          title: 'HealthSync — Care Companion',
          slug: 'healthsync-care-companion',
          summary:
              'A telehealth companion app for appointments, vitals and secure document sharing.',
          description:
              'HealthSync pairs a patient app with a clinician dashboard. The mobile client keeps '
              'vitals readable at a glance and makes consent explicit at every step.\n\n'
              'Focus areas: encrypted storage, audit trails, and a reading experience that works '
              'for users with low vision.\n\n'
              '$_sampleNote',
          category: 'Mobile',
          technologies: <String>['Flutter', 'FastAPI', 'PostgreSQL', 'WebRTC'],
          status: ProjectStatus.published,
          sortOrder: 5,
          imagePath: 'assets/images/projects/healthsync.png',
          repoUrl: 'https://github.com/samiullahzulfqar980-cmd',
          year: '2024',
          accentKey: 'mint',
        ),
        Project(
          id: 'demo-6',
          title: 'TaskMaster — Planning Board',
          slug: 'taskmaster-planning-board',
          summary:
              'A kanban planning tool with sprint estimation, drag-and-drop and instant undo.',
          description:
              'A productivity workspace built to answer one question: what should I do next?\n\n'
              'Smooth drag-and-drop with accessible keyboard alternatives, a durable undo stack, '
              'and summary views that stay fast with thousands of cards.\n\n'
              '$_sampleNote',
          category: 'Full-stack',
          technologies: <String>['React', 'Zustand', 'Node.js', 'PostgreSQL'],
          status: ProjectStatus.published,
          sortOrder: 6,
          imagePath: 'assets/images/projects/taskmaster.png',
          demoUrl: 'https://github.com/samiullahzulfqar980-cmd',
          year: '2023',
          accentKey: 'violet',
        ),
        Project(
          id: 'demo-7',
          title: 'Portfolio App (this app)',
          slug: 'portfolio-app',
          summary: 'The Flutter + Supabase app you are reading — draft entry kept for the admin demo.',
          description:
              'A draft record so the admin area has something unpublished to manage. Publish it or '
              'delete it once Supabase is connected.\n\n'
              '$_sampleNote',
          category: 'Mobile',
          technologies: <String>['Flutter', 'Supabase', 'go_router'],
          status: ProjectStatus.draft,
          sortOrder: 7,
          imagePath: 'assets/images/projects/taskmaster.png',
          year: '2026',
        ),
      ];

  static List<Skill> skills() => const <Skill>[
        Skill(id: 's1', name: 'Flutter & Dart', category: 'Mobile', proficiency: 92, sortOrder: 1, note: 'Bloc, Riverpod, native channels'),
        Skill(id: 's2', name: 'React Native / Expo', category: 'Mobile', proficiency: 88, sortOrder: 2, note: 'Expo Router, gestures, EAS'),
        Skill(id: 's3', name: 'Offline-first storage', category: 'Mobile', proficiency: 84, sortOrder: 3, note: 'SQLite, Hive, sync queues'),
        Skill(id: 's4', name: 'React & Next.js', category: 'Web', proficiency: 90, sortOrder: 4, note: 'App Router, server components'),
        Skill(id: 's5', name: 'TypeScript', category: 'Web', proficiency: 88, sortOrder: 5, note: 'Strict types, generics'),
        Skill(id: 's6', name: 'Design systems', category: 'Web', proficiency: 82, sortOrder: 6, note: 'Tokens, theming, a11y'),
        Skill(id: 's7', name: 'Node.js & REST', category: 'Backend & Data', proficiency: 86, sortOrder: 7, note: 'Express, validation, auth'),
        Skill(id: 's8', name: 'PostgreSQL & Supabase', category: 'Backend & Data', proficiency: 85, sortOrder: 8, note: 'RLS, migrations, storage'),
        Skill(id: 's9', name: 'Firebase', category: 'Backend & Data', proficiency: 78, sortOrder: 9, note: 'Auth, Firestore, FCM'),
        Skill(id: 's10', name: 'Git & CI', category: 'Tooling', proficiency: 90, sortOrder: 10, note: 'Actions, reviews, releases'),
        Skill(id: 's11', name: 'Figma to code', category: 'Tooling', proficiency: 84, sortOrder: 11, note: 'Handoff, prototypes'),
      ];

  static List<Service> services() => const <Service>[
        Service(
          id: 'svc1',
          title: 'Cross-platform mobile apps',
          description:
              'Production Flutter and React Native apps with native-feeling motion, offline support and clean architecture.',
          iconKey: 'mobile',
          sortOrder: 1,
          technologies: <String>['Flutter', 'React Native', 'Expo'],
        ),
        Service(
          id: 'svc2',
          title: 'Full-stack web platforms',
          description:
              'Fast, accessible web front ends backed by typed APIs, authentication and a database you can audit.',
          iconKey: 'web',
          sortOrder: 2,
          technologies: <String>['Next.js', 'TypeScript', 'PostgreSQL'],
        ),
        Service(
          id: 'svc3',
          title: 'Backend & API architecture',
          description:
              'Schema design, row-level security, storage policies and API layers that keep data safe by default.',
          iconKey: 'backend',
          sortOrder: 3,
          technologies: <String>['Supabase', 'Node.js', 'REST'],
        ),
        Service(
          id: 'svc4',
          title: 'UI engineering & polish',
          description:
              'Design systems, motion and accessibility passes that make an existing product feel considered.',
          iconKey: 'design',
          sortOrder: 4,
          technologies: <String>['Design tokens', 'Motion', 'A11y'],
        ),
      ];

  static List<TimelineEntry> timeline() => const <TimelineEntry>[
        TimelineEntry(
          id: 't1',
          kind: TimelineKind.experience,
          organization: 'Independent / Freelance (sample)',
          role: 'Mobile & Web App Developer',
          startLabel: '2023',
          isCurrent: true,
          location: 'Remote',
          description:
              'Sample entry — replace with your own history in Admin. Placeholder description: '
              'shipped cross-platform apps with Flutter and React Native, and web dashboards with Next.js.',
          sortOrder: 1,
        ),
        TimelineEntry(
          id: 't2',
          kind: TimelineKind.experience,
          organization: 'Add your employer (sample)',
          role: 'Software Developer',
          startLabel: '2022',
          endLabel: '2023',
          location: 'Islamabad, PK',
          description: 'Sample entry — describe the product, your role and one measurable outcome.',
          sortOrder: 2,
        ),
        TimelineEntry(
          id: 't3',
          kind: TimelineKind.education,
          organization: 'Add your institution (sample)',
          role: 'BS Computer Science',
          startLabel: '2020',
          endLabel: '2024',
          description: 'Sample entry — coursework, thesis or focus areas.',
          sortOrder: 3,
        ),
      ];
}
