# Portfolio — a Flutter + Supabase mobile portfolio

A complete, production-shaped **mobile portfolio app** for a developer: dark aurora visual
language, animated navigation, an optional owner login, and a full in-app admin area that
manages the same content visitors see.

Built with **Flutter**, **Dart**, **Riverpod**, **go_router** and **Supabase**
(Auth · PostgreSQL · Storage · Row Level Security). This is a native app — not a website,
not a WebView.

---

## Table of contents

1. [What's inside](#whats-inside)
2. [Screens](#screens)
3. [Tech stack](#tech-stack)
4. [Project structure](#project-structure)
5. [Prerequisites](#prerequisites)
6. [Quick start](#quick-start)
7. [Supabase configuration](#supabase-configuration)
8. [Grant admin access](#grant-admin-access)
9. [Deep links (password reset & email confirmation)](#deep-links)
10. [Local development](#local-development)
11. [Building the app](#building-the-app)
12. [Testing & analysis](#testing--analysis)
13. [Security model](#security-model)
14. [Accessibility & motion](#accessibility--motion)
15. [Editing the placeholder content](#editing-the-placeholder-content)
16. [Troubleshooting](#troubleshooting)

---

## What's inside

- **Public portfolio, no login required.** Visitors browse Home, Projects, About, Contact
  and the résumé immediately. Authentication is only a door to the owner tools.
- **Google-style onboarding** shown once on first launch (skippable, replayable).
- **Search + filter project grid** with category, stack and featured filters, plus a detail
  screen with live demo / repository links.
- **Validated inquiry form** with honeypot, minimum fill time, device cooldown, client-side
  sanitising, and a **server-side** spam guard (trigger + RLS validation + rate limit).
- **Owner admin area** (protected): create/edit/publish/reorder/delete projects, manage
  skills, services, experience & education, edit the profile, upload the avatar and the PDF
  résumé, and triage the inquiry inbox (read / replied / archived / delete).
- **Secure sessions** in the OS keychain/keystore (not SharedPreferences), automatic token
  refresh, and a boot-time refusal to run with a `service_role` key.
- **Graceful states everywhere:** skeletons, empty states, retryable error states, offline
  copy, reduced-motion support and large-text tolerance.
- **Preview mode:** with no Supabase credentials the app still runs with bundled sample
  content, clearly labelled — nothing is a dead end.

## Screens

| Area | Route | Notes |
| --- | --- | --- |
| Splash | `/` | Decides onboarding vs. home, shows preview-mode badge when unconfigured |
| Onboarding | `/onboarding` | 3 skippable slides, replayable from About |
| Home | `/home` | Avatar, availability, name, roles, intro, socials, CTAs, stats, featured work, services |
| Projects | `/projects` | Search, category/stack/featured filters, animated list, empty + error states |
| Project detail | `/projects/:slug` | Cover, summary, case study, stack, demo/repo, "similar project" CTA |
| About | `/about` | Bio, facts, services, skills by category, experience, education |
| Contact | `/contact` | Contact details, social links, validated inquiry form, success state |
| Résumé | `/resume` | In-app summary + opens the PDF stored in Supabase Storage |
| Sign in / Sign up | `/auth/…` | Validation, password toggle, strength meter, loading + inline errors |
| Password reset / verify email | `/auth/…` | Recovery deep links, resend with cooldown |
| Admin dashboard | `/admin` | Counts, quick links, recent inquiries, sign out |
| Admin projects | `/admin/projects` | Reorder, publish/unpublish, feature, edit, delete |
| Project editor | `/admin/projects/…` | Full form + image upload to Storage |
| Inquiry inbox | `/admin/messages` | Filter by status, mark read/replied/archived, delete |
| Admin profile | `/admin/profile` | Identity, bio, availability, contact, socials, avatar, résumé PDF |
| Admin skills / services / timeline | `/admin/…` | Create, edit, reorder, delete |

Navigation uses a **bottom tab bar** (Home · Projects · About · Contact) over a shell route
that preserves each tab's scroll position and drafts, with a slide/fade transition between
tabs. Detail, résumé, auth and admin screens are pushed on the root navigator with clear
back affordances and platform-appropriate transitions.

## Tech stack

| Layer | Choice |
| --- | --- |
| Framework | Flutter (stable, 3.27+), Dart 3.6+ |
| Navigation | `go_router` (StatefulShellRoute + typed route helpers) |
| State | `flutter_riverpod` (AsyncNotifier, FutureProvider, family) |
| Backend | `supabase_flutter` — Auth, Postgres, Storage, RLS |
| Session storage | `flutter_secure_storage` via a custom `LocalStorage` |
| Media | `image_picker` (images), `file_picker` (PDF résumé), `url_launcher` (links) |
| Fonts | Sora (display), Inter (body), JetBrains Mono (code) — bundled, OFL licensed in `assets/fonts` |

## Project structure

```
lib/
  app.dart                     MaterialApp.router + deep-link listener
  main.dart                    Bootstrap, secure session storage, fatal-config screen
  core/
    auth/auth_controller.dart  Supabase Auth wrapper (sign in/up, reset, resend)
    config/app_env.dart        Compile-time env + service-role guard
    errors/app_failure.dart    Friendly error mapping (Postgrest/Auth/network)
    motion/motion.dart         Motion tokens, AnimatedEntry, reduced-motion helpers
    platform/launcher_service.dart
    providers/                 Riverpod: app, content, admin
    router/app_router.dart     All routes + admin guard
    supabase/                  Initialisation + SecureSessionStorage
    theme/                     Colours, typography, spacing, ThemeData
    utils/                     Validators + Sanitizer, formatters, storage URLs
  data/
    models/                    AppProfile, Project, Skill, Service, TimelineEntry, ContactMessage
    repositories/              Portfolio (public read), Contact (submit), Admin (CRUD + storage)
    demo/demo_content.dart     Offline preview content mirroring the seed
  features/
    splash, onboarding, shell, home, projects, about, contact, resume, auth, admin
  shared/widgets/              GlassCard, buttons, fields, states, badges, cards…
supabase/
  migrations/                  Schema, RLS, storage policies
  seed.sql                     Sample content
assets/
  fonts/ images/ branding/     Fonts, generated artwork, app icon source
```

## Prerequisites

- Flutter **3.27 or newer** (`flutter --version`), with Dart 3.6+
- Android Studio / Xcode toolchains for device or simulator builds
- A Supabase project (free tier is fine)
- Optional: Supabase CLI (`npm i -g supabase`) for migrations

## Quick start

```bash
flutter pub get

# 1. Environment (placeholders only in the committed example)
cp .env.example .env
# edit .env → SUPABASE_URL + SUPABASE_ANON_KEY

# 2. Run with the env file
flutter run --dart-define-from-file=.env
```

> Running without `.env` is supported: the app opens in **preview mode** with bundled
> sample content. Admin writes and auth are disabled until Supabase is configured, and the
> UI says so instead of failing silently.

## Supabase configuration

### 1. Create the project

1. Create a project at [supabase.com/dashboard](https://supabase.com/dashboard).
2. Open **Project Settings → API** and copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon / publishable key** → `SUPABASE_ANON_KEY`

Never use the `service_role` key in the app. `lib/core/config/app_env.dart` decodes the
JWT role at boot and refuses to start if a privileged key was supplied.

### 2. Run the migrations

**With the CLI (recommended):**

```bash
supabase link --project-ref <your-project-ref>
supabase db push          # applies supabase/migrations/*.sql
psql "$DATABASE_URL" -f supabase/seed.sql   # or paste seed.sql in the SQL editor
```

**Without the CLI:** open **SQL Editor**, paste each file in `supabase/migrations/` in
filename order, run them, then paste `supabase/seed.sql`.

The migrations are idempotent (`if not exists`, `drop policy if exists`, upserts), so they
can be re-run safely.

### 3. Storage buckets

`20260101000200_storage_policies.sql` creates three **public-read** buckets and restricts
writes to the admin:

| Bucket | Contents | Size limit | Types |
| --- | --- | --- | --- |
| `profile-images` | avatar | 5 MB | jpeg, png, webp |
| `project-images` | project covers | 5 MB | jpeg, png, webp |
| `resume-files` | résumé PDF | 10 MB | pdf |

Uploads happen from the admin screens (image picker / file picker → Storage). Stored values
are **object paths** (e.g. `projects/1712345_finpulse.png`), and the app resolves them to
public URLs with `StorageUrl`.

### 4. Auth settings

In **Authentication → Providers**, keep **Email** enabled. Recommended:

- **Confirm email**: ON for production (the app has a verification screen and resend flow).
- **Minimum password length**: 8 (matches client validation).
- **Site URL**: your app scheme/host, e.g. `portfolioapp://auth-callback`.
- **Redirect URLs**: add `portfolioapp://auth-callback` (and, for local testing,
  `http://localhost:3000`).

Emails are sent by your Supabase project. For quick local testing you can read the
confirmation/recovery link from the Supabase Auth logs or use the CLI's Inbucket.

## Grant admin access

Admin rights come from the `public.admin_users` table — nothing in the app can grant them.

1. **Create the account.** Either use the app's **Sign up** screen (then confirm the email),
   or create the user in **Authentication → Users → Add user** (tick "Auto confirm").
2. **Insert the admin row** in the SQL editor:

   ```sql
   insert into public.admin_users (user_id, email, note)
   select id, email, 'portfolio owner'
   from auth.users
   where email = 'you@example.com'
   on conflict (user_id) do nothing;
   ```

3. Sign in on the device → the app calls `public.is_admin()`, the admin area unlocks, and
   RLS lets that user write content and read inquiries.

To revoke access: `delete from public.admin_users where email = 'you@example.com';`

> Any signed-in non-admin sees a clear "No admin access" screen — they never get a broken
> UI, and the database would reject their writes anyway.

## Deep links

Password-reset and confirmation emails redirect to `portfolioapp://auth-callback`.

**Android** — `android/app/src/main/AndroidManifest.xml` already contains:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="portfolioapp" android:host="auth-callback" />
</intent-filter>
```

**iOS** — `ios/Runner/Info.plist` declares `CFBundleURLSchemes → portfolioapp`.

Change the scheme in three places if you rename it: `.env` (`APP_URL_SCHEME`), the manifest,
and Info.plist. Supabase detects the recovery token and the app routes to
`/auth/reset-password` automatically.

## Local development

```bash
flutter pub get
flutter run --dart-define-from-file=.env          # debug on device/simulator
flutter run --dart-define-from-file=.env -d ios   # or android
```

Useful commands:

```bash
flutter analyze
flutter test
flutter pub outdated
```

Preview mode (no env file):

```bash
flutter run     # bundled sample content, admin writes disabled
```

## Building the app

### Android

```bash
# App bundle for Play Store
flutter build appbundle --release --dart-define-from-file=.env

# APK for direct install / QA
flutter build apk --release --dart-define-from-file=.env
```

For a signed release, create `android/key.properties` (git-ignored):

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/absolute/path/upload-keystore.jks
```

and wire it into `android/app/build.gradle` (the template currently signs release builds
with the debug key). Bump `version:` in `pubspec.yaml` before shipping.

### iOS

```bash
cd ios && pod install && cd ..
flutter build ipa --release --dart-define-from-file=.env
```

Set your team and bundle identifier in Xcode (`ios/Runner.xcworkspace`) — the template ships
with `dev.samiullah.portfolio_app` and an empty development team.

### Environment in CI

`--dart-define-from-file` reads a local file, so in CI create `.env` from repository
secrets before the build. Only public values belong there (URL + anon key). Store the
Android keystore / iOS certificates in your CI secret store.

## Testing & analysis

```bash
flutter analyze
flutter test
```

`test/validators_test.dart` covers email/password/message validation, slug generation and
spam/sanitisation helpers.

## Security model

| Concern | Measure |
| --- | --- |
| Keys in the binary | Only the **anon** key is used; boot aborts if a `service_role` JWT is detected |
| Session storage | Keychain / EncryptedSharedPreferences via `SecureSessionStorage` |
| Public content | RLS: published projects + published services + profile/skills/timeline are readable by `anon` |
| Inquiries | `insert` for visitors only; `select/update/delete` require `is_admin()` |
| Inquiries validation | RLS `with check` constraints, DB CHECKs, and a `before insert` trigger (rate limit + spam patterns + normalisation) |
| Writes | Every content table restricts insert/update/delete to `is_admin()` |
| Storage | Public read for portfolio assets; writes restricted to `is_admin()` and bucket MIME/size limits |
| Admin discovery | Admin rows are managed in SQL; `admin_users` is unreadable except your own row |
| Error surfaces | Raw Postgrest/Auth errors are mapped to friendly copy; details only in debug logs |

## Accessibility & motion

- All interactive elements have ≥44×44pt targets and semantic labels; icons that repeat a
  label are excluded from the semantics tree.
- OS **reduce motion** (`MediaQuery.disableAnimations`) disables entrance animations, tab
  transitions, the availability pulse and shimmer skeletons.
- Text scales up to 160% before layout clamps, and lists/cards use flexible layouts rather
  than fixed heights.
- Colour pairings target ≥4.5:1 for body text on the midnight surfaces; status is never
  conveyed by colour alone (label + colour).
- Forms use `AutofillHints`, correct keyboard types and `TextInputAction` chains.

## Editing the placeholder content

Everything shipped is placeholder content and is clearly editable:

- **In the app** (recommended): sign in as admin → edit profile, projects, skills, services
  and timeline; upload avatar/project images and the résumé PDF.
- **In SQL:** edit `supabase/seed.sql` before seeding, or update rows in the Table editor.
- **Bundled demo:** `lib/data/demo/demo_content.dart` powers preview mode only.
- **Illustrations:** generated artwork lives in `assets/images/` (avatar + six project
  covers). Replace them with real screenshots, then upload to the `project-images` bucket
  and update `image_path`.
- **App icon / splash:** source is `assets/branding/app-icon.png`; generated launcher sets
  are already in `android/app/src/main/res/mipmap-*` and `ios/Runner/Assets.xcassets`.

The seeded projects describe generic engineering stories (no fabricated clients,
testimonials, metrics or employers). Experience entries are explicitly marked "(sample)".
The résumé PDF is intentionally not bundled — upload your own so the app never displays
someone else's document.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| "Preview mode" banner | `.env` missing or placeholders — add URL + anon key and restart (cold start, not hot reload) |
| Everyone can read drafts | You skipped the RLS migration — apply `20260101000100_rls_policies.sql` |
| Admin gate says "No admin access" | No `admin_users` row for that auth user (see [Grant admin access](#grant-admin-access)) |
| Reset link opens a browser | Deep-link scheme/host mismatch — check `.env`, AndroidManifest and Info.plist, then add the redirect URL in Supabase |
| Uploads fail with 403 | Signed in as a non-admin, or bucket policies were not applied |
| Images 404 | `image_path` must be an object path inside the bucket (or a bundled `assets/...` path), not a full URL unless you intend an external image |
| Inquiries rejected as spam | Links >3, promo keywords, or more than 3 messages per email per 10 minutes (server trigger) |

---

### Licensing

Bundled fonts are licensed under the SIL Open Font License — see `assets/fonts/OFL-*.txt`.
App code and generated artwork are yours to adapt.
