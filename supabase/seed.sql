-- =============================================================================
-- Sample portfolio content
--
-- Everything here is PLACEHOLDER data. Replace it from the in-app admin area
-- (or edit this file before seeding).
--
-- Project images point at bundled app assets so the app looks complete right
-- after seeding. Upload real screenshots to the `project-images` bucket and set
-- `image_path` to the object path (e.g. 'projects/finpulse.png') to switch.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Profile (single row)
-- -----------------------------------------------------------------------------
insert into public.profiles (
  id, full_name, headline, roles, short_intro, bio, email, phone, location, timezone,
  availability_status, availability_note, social_links, avatar_path, resume_path, stats
) values (
  '00000000-0000-4000-a000-000000000001',
  'Your Name',
  'Mobile & Web App Developer',
  array['Flutter Developer', 'React Native Engineer', 'Full-Stack Web'],
  'I design and build fast, accessible cross-platform apps and the web platforms behind them.',
  E'I am a software developer focused on cross-platform mobile apps with Flutter and React Native, plus the web front ends and APIs that support them.\n\n'
  'I care about the details that make software feel premium: 60fps motion, clear hierarchy, accessible contrast, honest loading states and code that is easy for the next engineer to change.\n\n'
  'Sample content — edit this from the admin area.',
  'you@example.com',
  null,
  'Islamabad, Pakistan',
  'UTC+5',
  'available',
  'Open to freelance projects and full-time roles',
  jsonb_build_object(
    'github',   jsonb_build_object('url', 'https://github.com/your-username', 'label', 'GitHub'),
    'linkedin', jsonb_build_object('url', 'https://www.linkedin.com/in/your-username', 'label', 'LinkedIn'),
    'whatsapp', jsonb_build_object('url', '+923470563895', 'label', 'WhatsApp'),
    'website', jsonb_build_object('url', 'https://portfolio-website-six-rosy-97.vercel.app/', 'label', 'Website')
  ),
  'avatar/avatar.png',
  null,
  jsonb_build_array(
    jsonb_build_object('label', 'Focus', 'value', 'Mobile + Web', 'icon', 'mobile'),
    jsonb_build_object('label', 'Stack', 'value', 'Flutter · RN · TS', 'icon', 'web'),
    jsonb_build_object('label', 'Based in', 'value', 'Islamabad, PK', 'icon', 'cloud')
  )
)
on conflict (id) do update set
  full_name = excluded.full_name,
  headline = excluded.headline,
  roles = excluded.roles,
  short_intro = excluded.short_intro,
  bio = excluded.bio,
  email = excluded.email,
  phone = excluded.phone,
  location = excluded.location,
  timezone = excluded.timezone,
  availability_status = excluded.availability_status,
  availability_note = excluded.availability_note,
  social_links = excluded.social_links,
  avatar_path = excluded.avatar_path,
  resume_path = excluded.resume_path,
  stats = excluded.stats;

-- -----------------------------------------------------------------------------
-- Projects (6 published + 1 draft to exercise the admin draft flow)
-- -----------------------------------------------------------------------------
insert into public.projects (
  id, title, slug, summary, description, category, technologies,
  image_path, demo_url, repo_url, is_featured, sort_order, status, year, accent
) values
(
  '10000000-0000-4000-a000-000000000001',
  'FinPulse — Fintech Wallet',
  'finpulse-fintech-wallet',
  'A cross-platform wallet concept with a live market feed, budget insights and biometric unlock.',
  E'FinPulse explores what a calm, trustworthy fintech app feels like. The home screen leads with balance and cashflow instead of charts, motion explains change rather than decorating it, and every destructive action is guarded.\n\nBuilt as a reference architecture: feature-first folder structure, repository layer, typed API models and a design system that adapts to small phones and large text.\n\nSample content — replace with your own case study.',
  'Mobile',
  array['Flutter', 'Dart', 'Riverpod', 'Supabase'],
  'assets/images/projects/finpulse.png',
  'https://github.com/your-username',
  'https://github.com/your-username',
  true, 1, 'published', '2026', 'violet'
),
(
  '10000000-0000-4000-a000-000000000002',
  'DevFlow — Developer Workspace',
  'devflow-developer-workspace',
  'A web workspace for snippets, reviews and release notes with keyboard-first navigation.',
  E'DevFlow is a full-stack web app for small engineering teams: searchable snippets, a review queue and release notes that render from a single source of truth.\n\nThe interesting engineering is in the data layer — Postgres full-text search, row-level security per workspace and optimistic UI that survives a dropped websocket.\n\nSample content — replace with your own case study.',
  'Web',
  array['Next.js', 'TypeScript', 'PostgreSQL', 'Tailwind'],
  'assets/images/projects/devflow.png',
  'https://github.com/your-username',
  'https://github.com/your-username',
  true, 2, 'published', '2026', 'cyan'
),
(
  '10000000-0000-4000-a000-000000000003',
  'FoodExpress — Delivery',
  'foodexpress-delivery',
  'On-demand delivery flow with live order tracking, driver handoff states and offline menus.',
  E'A delivery app concept built around the 40 seconds that actually matter: choosing, paying and knowing where the order is.\n\nOffline-first cart, deterministic order state machine, and a map view that degrades gracefully when the network is slow.\n\nSample content — replace with your own case study.',
  'Mobile',
  array['React Native', 'Expo', 'Node.js', 'MongoDB'],
  'assets/images/projects/foodexpress.png',
  'https://github.com/your-username',
  'https://github.com/your-username',
  false, 3, 'published', '2025', 'amber'
),
(
  '10000000-0000-4000-a000-000000000004',
  'Aura — Interactive Storefront',
  'aura-interactive-storefront',
  'A 3D product customiser that stays under budget on mid-range phones.',
  E'A storefront experiment: real-time product materials, lighting presets and a checkout that never blocks the viewport.\n\nProgressive loading, texture budgets and a reduced-motion fallback are what make it usable on real devices rather than only on a laptop.\n\nSample content — replace with your own case study.',
  'Web',
  array['React', 'Three.js', 'WebGL', 'Stripe'],
  'assets/images/projects/aura3d.png',
  'https://github.com/your-username',
  'https://github.com/your-username',
  false, 4, 'published', '2025', 'rose'
),
(
  '10000000-0000-4000-a000-000000000005',
  'HealthSync — Care Companion',
  'healthsync-care-companion',
  'A telehealth companion app for appointments, vitals and secure document sharing.',
  E'HealthSync pairs a patient app with a clinician dashboard. The mobile client keeps vitals readable at a glance and makes consent explicit at every step.\n\nFocus areas: encrypted storage, audit trails, and a reading experience that works for users with low vision.\n\nSample content — replace with your own case study.',
  'Mobile',
  array['Flutter', 'FastAPI', 'PostgreSQL', 'WebRTC'],
  'assets/images/projects/healthsync.png',
  'https://github.com/your-username',
  'https://github.com/your-username',
  false, 5, 'published', '2025', 'mint'
),
(
  '10000000-0000-4000-a000-000000000006',
  'TaskMaster — Planning Board',
  'taskmaster-planning-board',
  'A kanban planning tool with sprint estimation, drag-and-drop and instant undo.',
  E'A productivity workspace built to answer one question: what should I do next?\n\nSmooth drag-and-drop with accessible keyboard alternatives, a durable undo stack, and summary views that stay fast with thousands of cards.\n\nSample content — replace with your own case study.',
  'Full-stack',
  array['React', 'Zustand', 'Node.js', 'PostgreSQL'],
  'assets/images/projects/taskmaster.png',
  'https://github.com/your-username',
  null,
  false, 6, 'published', '2024', 'violet'
),
(
  '10000000-0000-4000-a000-000000000007',
  'Your Next Project',
  'your-next-project',
  'A draft entry so the admin area has something unpublished to manage. Publish or delete it.',
  E'Use this draft to try the editor: write a case study, add tags, upload a cover image, then publish.\n\nSample content — delete this row when you add real work.',
  'Mobile',
  array['Flutter', 'Supabase'],
  'assets/images/projects/taskmaster.png',
  null,
  null,
  false, 7, 'draft', '2026', 'violet'
)
on conflict (id) do update set
  title = excluded.title,
  slug = excluded.slug,
  summary = excluded.summary,
  description = excluded.description,
  category = excluded.category,
  technologies = excluded.technologies,
  image_path = excluded.image_path,
  demo_url = excluded.demo_url,
  repo_url = excluded.repo_url,
  is_featured = excluded.is_featured,
  sort_order = excluded.sort_order,
  status = excluded.status,
  year = excluded.year,
  accent = excluded.accent;

-- -----------------------------------------------------------------------------
-- Skills
-- -----------------------------------------------------------------------------
insert into public.skills (id, name, category, proficiency, note, sort_order) values
  ('20000000-0000-4000-a000-000000000001', 'Flutter & Dart', 'Mobile', 92, 'Bloc, Riverpod, native channels', 1),
  ('20000000-0000-4000-a000-000000000002', 'React Native / Expo', 'Mobile', 88, 'Expo Router, gestures, EAS', 2),
  ('20000000-0000-4000-a000-000000000003', 'Offline-first storage', 'Mobile', 84, 'SQLite, Hive, sync queues', 3),
  ('20000000-0000-4000-a000-000000000004', 'React & Next.js', 'Web', 90, 'App Router, server components', 4),
  ('20000000-0000-4000-a000-000000000005', 'TypeScript', 'Web', 88, 'Strict types, generics', 5),
  ('20000000-0000-4000-a000-000000000006', 'Design systems', 'Web', 82, 'Tokens, theming, a11y', 6),
  ('20000000-0000-4000-a000-000000000007', 'Node.js & REST', 'Backend & Data', 86, 'Express, validation, auth', 7),
  ('20000000-0000-4000-a000-000000000008', 'PostgreSQL & Supabase', 'Backend & Data', 85, 'RLS, migrations, storage', 8),
  ('20000000-0000-4000-a000-000000000009', 'Firebase', 'Backend & Data', 78, 'Auth, Firestore, FCM', 9),
  ('20000000-0000-4000-a000-00000000000a', 'Git & CI', 'Tooling', 90, 'Actions, reviews, releases', 10),
  ('20000000-0000-4000-a000-00000000000b', 'Figma to code', 'Tooling', 84, 'Handoff, prototypes', 11)
on conflict (id) do update set
  name = excluded.name,
  category = excluded.category,
  proficiency = excluded.proficiency,
  note = excluded.note,
  sort_order = excluded.sort_order;

-- -----------------------------------------------------------------------------
-- Services
-- -----------------------------------------------------------------------------
insert into public.services (id, title, description, icon_key, technologies, is_published, sort_order) values
  ('30000000-0000-4000-a000-000000000001',
   'Cross-platform mobile apps',
   'Production Flutter and React Native apps with native-feeling motion, offline support and clean architecture.',
   'mobile', array['Flutter', 'React Native', 'Expo'], true, 1),
  ('30000000-0000-4000-a000-000000000002',
   'Full-stack web platforms',
   'Fast, accessible web front ends backed by typed APIs, authentication and a database you can audit.',
   'web', array['Next.js', 'TypeScript', 'PostgreSQL'], true, 2),
  ('30000000-0000-4000-a000-000000000003',
   'Backend & API architecture',
   'Schema design, row-level security, storage policies and API layers that keep data safe by default.',
   'backend', array['Supabase', 'Node.js', 'REST'], true, 3),
  ('30000000-0000-4000-a000-000000000004',
   'UI engineering & polish',
   'Design systems, motion and accessibility passes that make an existing product feel considered.',
   'design', array['Design tokens', 'Motion', 'A11y'], true, 4)
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon_key = excluded.icon_key,
  technologies = excluded.technologies,
  is_published = excluded.is_published,
  sort_order = excluded.sort_order;

-- -----------------------------------------------------------------------------
-- Experience & education
-- -----------------------------------------------------------------------------
insert into public.timeline (id, kind, organization, role, start_label, end_label, is_current, description, location, sort_order) values
  ('40000000-0000-4000-a000-000000000001', 'experience',
   'Add your employer (sample)', 'Mobile & Web App Developer', '2023', null, true,
   'Sample entry — describe the product, your role and one measurable outcome.',
   'Remote', 1),
  ('40000000-0000-4000-a000-000000000002', 'experience',
   'Add your employer (sample)', 'Software Developer', '2021', '2023', false,
   'Sample entry — replace with your own history.',
   'Islamabad, PK', 2),
  ('40000000-0000-4000-a000-000000000003', 'education',
   'Add your institution (sample)', 'BS Computer Science', '2017', '2021', false,
   'Sample entry — coursework, thesis or focus areas.',
   null, 3)
on conflict (id) do update set
  kind = excluded.kind,
  organization = excluded.organization,
  role = excluded.role,
  start_label = excluded.start_label,
  end_label = excluded.end_label,
  is_current = excluded.is_current,
  description = excluded.description,
  location = excluded.location,
  sort_order = excluded.sort_order;

-- -----------------------------------------------------------------------------
-- Notes
--
-- Admin access is intentionally NOT seeded: create your auth user first, then
-- grant the role (see README → "Grant admin access"):
--
--   insert into public.admin_users (user_id, email, note)
--   select id, email, 'portfolio owner'
--   from auth.users
--   where email = 'you@example.com'
--   on conflict (user_id) do nothing;
--
-- Upload your avatar to the `profile-images` bucket (path `avatar/avatar.png`)
-- and set `profiles.avatar_path` to the object path. Until then, the app falls
-- back to initials.
-- -----------------------------------------------------------------------------
