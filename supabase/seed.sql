-- =============================================================================
-- Portfolio content — mirrors the app's bundled demo data
--
-- This file is generated from lib/data/demo/demo_content.dart, so a freshly
-- seeded database looks exactly like the app's preview mode.
--
-- Run it with one of:
--   psql "$DATABASE_URL" -f supabase/seed.sql            -- from the CLI
--   paste the whole file into Dashboard → SQL Editor      -- no CLI needed
--   supabase db reset                                     -- local dev only
--
-- Safe to re-run: every statement upserts by a stable id, so re-running
-- refreshes the rows instead of duplicating them. Edit the values here (or in
-- the in-app admin area) — nothing is generated at runtime.
--
-- Images: paths beginning with `assets/` are bundled app assets, so the app
-- renders them with no upload needed. To use the storage buckets instead,
-- upload the file and set the value to the object path, e.g.
--   profiles.avatar_path  -> 'avatar/me.webp'      (bucket: profile-images)
--   projects.image_path   -> 'projects/finpulse.png' (bucket: project-images)
--   profiles.resume_path  -> 'resume/cv.pdf'        (bucket: resume-files)
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- Profile (single row)
-- -----------------------------------------------------------------------------
insert into public.profiles (
  id, full_name, headline, roles, short_intro, bio, email, phone, location, timezone,
  availability_status, availability_note, social_links, avatar_path, resume_path, stats
) values (
  E'00000000-0000-4000-a000-000000000001',
  E'Samiullah Zulfqar',
  E'Mobile & Web App Developer',
  array[E'Flutter Developer', E'React Native Engineer', E'Full-Stack Web'],
  E'I design and build fast, accessible cross-platform apps and the web platforms behind them.',
  E'I am a software developer focused on cross-platform mobile apps with Flutter and React Native, plus the web front ends and APIs that support them.\n\nI care about the details that make software feel premium: 60fps motion, clear information hierarchy, accessible contrast, honest loading states and code that is easy for the next engineer to change.\n\nSample content — edit this from the admin area once Supabase is connected.',
  E'samiullahzulfqar980@gmail.com',
  null,
  E'Islamabad, Pakistan',
  E'UTC+5',
  E'available',
  E'Open to freelance projects and full-time roles',
  jsonb_build_object(
    'github', jsonb_build_object('url', E'https://github.com/samiullahzulfqar980-cmd', 'label', E'GitHub'),
    'whatsapp', jsonb_build_object('url', E'+923470563895', 'label', E'WhatsApp'),
    'website', jsonb_build_object('url', E'https://portfolio-website-six-rosy-97.vercel.app/', 'label', E'Website')
  ),
  E'assets/images/avatar.png',
  null,
  jsonb_build_array(
    jsonb_build_object('label', E'Focus', 'value', E'Mobile + Web', 'icon', E'mobile'),
    jsonb_build_object('label', E'Stack', 'value', E'Flutter · RN · TS', 'icon', E'web'),
    jsonb_build_object('label', E'Based in', 'value', E'Islamabad, PK', 'icon', E'cloud')
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
-- Projects (6 published + 1 draft)
-- -----------------------------------------------------------------------------
insert into public.projects (
  id, title, slug, summary, description, category, technologies,
  image_path, demo_url, repo_url, is_featured, sort_order, status, year, accent
) values

(
  E'10000000-0000-4000-a000-000000000001',
  E'FinPulse — Fintech Wallet',
  E'finpulse-fintech-wallet',
  E'A cross-platform wallet concept with a live market feed, budget insights and biometric unlock.',
  E'FinPulse explores what a calm, trustworthy fintech app feels like. The home screen leads with balance and cashflow instead of charts, motion is used to explain change rather than decorate it, and every destructive action is guarded.\n\nBuilt as a reference architecture: feature-first folder structure, repository layer, typed API models and a design system that adapts to small phones and large text.\n\nSample content — edit this from the admin area once Supabase is connected.',
  E'Mobile',
  array[E'Flutter', E'Dart', E'Riverpod', E'Supabase'],
  E'assets/images/projects/finpulse.png',
  E'https://github.com/samiullahzulfqar980-cmd',
  E'https://github.com/samiullahzulfqar980-cmd',
  true, 1, E'published', E'2025', E'violet'
),
(
  E'10000000-0000-4000-a000-000000000002',
  E'DevFlow — Developer Workspace',
  E'devflow-developer-workspace',
  E'A web workspace for snippets, reviews and release notes with keyboard-first navigation.',
  E'DevFlow is a full-stack web app for small engineering teams: searchable snippets, a review queue and release notes that render from a single source of truth.\n\nThe interesting engineering is in the data layer — Postgres full-text search, row-level security per workspace and optimistic UI that survives a dropped websocket.\n\nSample content — edit this from the admin area once Supabase is connected.',
  E'Web',
  array[E'Next.js', E'TypeScript', E'PostgreSQL', E'Tailwind'],
  E'assets/images/projects/devflow.png',
  E'https://github.com/samiullahzulfqar980-cmd',
  E'https://github.com/samiullahzulfqar980-cmd',
  true, 2, E'published', E'2025', E'cyan'
),
(
  E'10000000-0000-4000-a000-000000000003',
  E'FoodExpress — Delivery',
  E'foodexpress-delivery',
  E'On-demand delivery flow with live order tracking, driver handoff states and offline menus.',
  E'A delivery app concept built around the 40 seconds that actually matter: choosing, paying and knowing where the order is.\n\nOffline-first cart, deterministic order state machine, and a map view that degrades gracefully when the network is slow.\n\nSample content — edit this from the admin area once Supabase is connected.',
  E'Mobile',
  array[E'React Native', E'Expo', E'Node.js', E'MongoDB'],
  E'assets/images/projects/foodexpress.png',
  null,
  E'https://github.com/samiullahzulfqar980-cmd',
  false, 3, E'published', E'2024', E'amber'
),
(
  E'10000000-0000-4000-a000-000000000004',
  E'Aura — Interactive Storefront',
  E'aura-interactive-storefront',
  E'A 3D product customiser that stays under budget on mid-range phones.',
  E'A storefront experiment: real-time product materials, lighting presets and a checkout that never blocks the viewport.\n\nProgressive loading, texture budgets and a reduced-motion fallback are what make it usable on real devices rather than only on a laptop.\n\nSample content — edit this from the admin area once Supabase is connected.',
  E'Web',
  array[E'React', E'Three.js', E'WebGL', E'Stripe'],
  E'assets/images/projects/aura3d.png',
  E'https://github.com/samiullahzulfqar980-cmd',
  null,
  false, 4, E'published', E'2024', E'rose'
),
(
  E'10000000-0000-4000-a000-000000000005',
  E'HealthSync — Care Companion',
  E'healthsync-care-companion',
  E'A telehealth companion app for appointments, vitals and secure document sharing.',
  E'HealthSync pairs a patient app with a clinician dashboard. The mobile client keeps vitals readable at a glance and makes consent explicit at every step.\n\nFocus areas: encrypted storage, audit trails, and a reading experience that works for users with low vision.\n\nSample content — edit this from the admin area once Supabase is connected.',
  E'Mobile',
  array[E'Flutter', E'FastAPI', E'PostgreSQL', E'WebRTC'],
  E'assets/images/projects/healthsync.png',
  null,
  E'https://github.com/samiullahzulfqar980-cmd',
  false, 5, E'published', E'2024', E'mint'
),
(
  E'10000000-0000-4000-a000-000000000006',
  E'TaskMaster — Planning Board',
  E'taskmaster-planning-board',
  E'A kanban planning tool with sprint estimation, drag-and-drop and instant undo.',
  E'A productivity workspace built to answer one question: what should I do next?\n\nSmooth drag-and-drop with accessible keyboard alternatives, a durable undo stack, and summary views that stay fast with thousands of cards.\n\nSample content — edit this from the admin area once Supabase is connected.',
  E'Full-stack',
  array[E'React', E'Zustand', E'Node.js', E'PostgreSQL'],
  E'assets/images/projects/taskmaster.png',
  E'https://github.com/samiullahzulfqar980-cmd',
  null,
  false, 6, E'published', E'2023', E'violet'
),
(
  E'10000000-0000-4000-a000-000000000007',
  E'Portfolio App (this app)',
  E'portfolio-app',
  E'The Flutter + Supabase app you are reading — draft entry kept for the admin demo.',
  E'A draft record so the admin area has something unpublished to manage. Publish it or delete it once Supabase is connected.\n\nSample content — edit this from the admin area once Supabase is connected.',
  E'Mobile',
  array[E'Flutter', E'Supabase', E'go_router'],
  E'assets/images/projects/taskmaster.png',
  null,
  null,
  false, 7, E'draft', E'2026', E'violet'
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
-- Skills (11)
-- -----------------------------------------------------------------------------
insert into public.skills (id, name, category, proficiency, note, sort_order) values

  (E'20000000-0000-4000-a000-000000000001', E'Flutter & Dart', E'Mobile', 92, E'Bloc, Riverpod, native channels', 1),
  (E'20000000-0000-4000-a000-000000000002', E'React Native / Expo', E'Mobile', 88, E'Expo Router, gestures, EAS', 2),
  (E'20000000-0000-4000-a000-000000000003', E'Offline-first storage', E'Mobile', 84, E'SQLite, Hive, sync queues', 3),
  (E'20000000-0000-4000-a000-000000000004', E'React & Next.js', E'Web', 90, E'App Router, server components', 4),
  (E'20000000-0000-4000-a000-000000000005', E'TypeScript', E'Web', 88, E'Strict types, generics', 5),
  (E'20000000-0000-4000-a000-000000000006', E'Design systems', E'Web', 82, E'Tokens, theming, a11y', 6),
  (E'20000000-0000-4000-a000-000000000007', E'Node.js & REST', E'Backend & Data', 86, E'Express, validation, auth', 7),
  (E'20000000-0000-4000-a000-000000000008', E'PostgreSQL & Supabase', E'Backend & Data', 85, E'RLS, migrations, storage', 8),
  (E'20000000-0000-4000-a000-000000000009', E'Firebase', E'Backend & Data', 78, E'Auth, Firestore, FCM', 9),
  (E'20000000-0000-4000-a000-00000000000a', E'Git & CI', E'Tooling', 90, E'Actions, reviews, releases', 10),
  (E'20000000-0000-4000-a000-00000000000b', E'Figma to code', E'Tooling', 84, E'Handoff, prototypes', 11)
on conflict (id) do update set
  name = excluded.name,
  category = excluded.category,
  proficiency = excluded.proficiency,
  note = excluded.note,
  sort_order = excluded.sort_order;

-- -----------------------------------------------------------------------------
-- Services (4)
-- -----------------------------------------------------------------------------
insert into public.services (id, title, description, icon_key, technologies, is_published, sort_order) values

  (E'30000000-0000-4000-a000-000000000001',
   E'Cross-platform mobile apps',
   E'Production Flutter and React Native apps with native-feeling motion, offline support and clean architecture.',
   E'mobile', array[E'Flutter', E'React Native', E'Expo'], true, 1),
  (E'30000000-0000-4000-a000-000000000002',
   E'Full-stack web platforms',
   E'Fast, accessible web front ends backed by typed APIs, authentication and a database you can audit.',
   E'web', array[E'Next.js', E'TypeScript', E'PostgreSQL'], true, 2),
  (E'30000000-0000-4000-a000-000000000003',
   E'Backend & API architecture',
   E'Schema design, row-level security, storage policies and API layers that keep data safe by default.',
   E'backend', array[E'Supabase', E'Node.js', E'REST'], true, 3),
  (E'30000000-0000-4000-a000-000000000004',
   E'UI engineering & polish',
   E'Design systems, motion and accessibility passes that make an existing product feel considered.',
   E'design', array[E'Design tokens', E'Motion', E'A11y'], true, 4)
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon_key = excluded.icon_key,
  technologies = excluded.technologies,
  is_published = excluded.is_published,
  sort_order = excluded.sort_order;

-- -----------------------------------------------------------------------------
-- Experience & education (3)
-- -----------------------------------------------------------------------------
insert into public.timeline (id, kind, organization, role, start_label, end_label, is_current, description, location, sort_order) values

  (E'40000000-0000-4000-a000-000000000001', E'experience',
   E'Independent / Freelance (sample)', E'Mobile & Web App Developer', E'2023', null, true,
   E'Sample entry — replace with your own history in Admin. Placeholder description: shipped cross-platform apps with Flutter and React Native, and web dashboards with Next.js.',
   E'Remote', 1),
  (E'40000000-0000-4000-a000-000000000002', E'experience',
   E'Add your employer (sample)', E'Software Developer', E'2022', E'2023', false,
   E'Sample entry — describe the product, your role and one measurable outcome.',
   E'Islamabad, PK', 2),
  (E'40000000-0000-4000-a000-000000000003', E'education',
   E'Add your institution (sample)', E'BS Computer Science', E'2020', E'2024', false,
   E'Sample entry — coursework, thesis or focus areas.',
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

commit;

-- -----------------------------------------------------------------------------
-- After seeding
--
-- 1. Admin access is intentionally NOT seeded — create your auth user, then:
--
--      insert into public.admin_users (user_id, email, note)
--      select id, email, 'portfolio owner'
--      from auth.users
--      where email = 'you@example.com'
--      on conflict (user_id) do nothing;
--
-- 2. Sign in to the app with that account; the Profile tab shows an Admin badge.
-- 3. Storage buckets are public-read/admin-write, so uploads from the app work
--    immediately — no extra policy setup.
-- -----------------------------------------------------------------------------
