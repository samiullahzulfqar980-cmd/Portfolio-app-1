-- =============================================================================
-- Portfolio app — schema
-- Run with:  supabase db push      (or paste into the SQL editor)
-- Safe to re-run: every object is created with IF NOT EXISTS / OR REPLACE.
-- =============================================================================

create extension if not exists "pgcrypto";

-- -----------------------------------------------------------------------------
-- Shared helpers
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- admin_users — the single source of truth for owner access.
-- Rows are added manually (SQL editor / migration), never by the app.
-- -----------------------------------------------------------------------------
create table if not exists public.admin_users (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  email      text,
  note       text,
  created_at timestamptz not null default now()
);

-- Returns true when the current JWT belongs to an authorised admin.
-- SECURITY DEFINER so policies can consult the table without recursing.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users au
    where au.user_id = auth.uid()
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- -----------------------------------------------------------------------------
-- profiles — a single row describing the portfolio owner.
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id                  uuid primary key default gen_random_uuid(),
  full_name           text not null,
  headline            text not null default '',
  roles               text[] not null default '{}',
  short_intro         text not null default '',
  bio                 text not null default '',
  email               text not null,
  phone               text,
  location            text,
  timezone            text,
  availability_status text not null default 'available'
                        check (availability_status in ('available', 'open', 'unavailable')),
  availability_note   text,
  social_links        jsonb not null default '{}'::jsonb,
  avatar_path         text,
  resume_path         text,
  stats               jsonb not null default '[]'::jsonb,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint profiles_full_name_len check (char_length(full_name) between 2 and 80),
  constraint profiles_email_shape check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]{2,}$'),
  constraint profiles_bio_len check (char_length(bio) <= 6000),
  constraint profiles_roles_len check (array_length(roles, 1) is null or array_length(roles, 1) <= 8),
  constraint profiles_social_object check (jsonb_typeof(social_links) = 'object'),
  constraint profiles_stats_array check (jsonb_typeof(stats) = 'array')
);

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- Only one profile row is used, but guard against accidental duplicates.
create unique index if not exists profiles_singleton_guard on public.profiles ((true));

-- -----------------------------------------------------------------------------
-- projects
-- -----------------------------------------------------------------------------
create table if not exists public.projects (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  slug         text not null unique,
  summary      text not null default '',
  description  text not null default '',
  category     text not null default 'Mobile',
  technologies text[] not null default '{}',
  image_path   text,
  demo_url     text,
  repo_url     text,
  is_featured  boolean not null default false,
  sort_order   integer not null default 0,
  status       text not null default 'draft' check (status in ('draft', 'published')),
  year         text,
  accent       text default 'violet'
                 check (accent in ('violet', 'cyan', 'amber', 'mint', 'rose')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint projects_title_len check (char_length(title) between 2 and 90),
  constraint projects_slug_shape check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint projects_summary_len check (char_length(summary) <= 400),
  constraint projects_description_len check (char_length(description) <= 8000),
  constraint projects_tech_len check (array_length(technologies, 1) is null or array_length(technologies, 1) <= 16),
  constraint projects_links_shape check (
    (demo_url is null or demo_url ~* '^https?://')
    and (repo_url is null or repo_url ~* '^https?://')
  )
);

drop trigger if exists projects_touch_updated_at on public.projects;
create trigger projects_touch_updated_at
before update on public.projects
for each row execute function public.set_updated_at();

create index if not exists projects_published_order_idx
  on public.projects (status, sort_order) where status = 'published';

create index if not exists projects_search_idx
  on public.projects using gin (to_tsvector('english', title || ' ' || summary || ' ' || description));

-- -----------------------------------------------------------------------------
-- skills
-- -----------------------------------------------------------------------------
create table if not exists public.skills (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  category    text not null default 'General',
  proficiency integer not null default 70 check (proficiency between 0 and 100),
  note        text,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint skills_name_len check (char_length(name) between 1 and 40)
);

drop trigger if exists skills_touch_updated_at on public.skills;
create trigger skills_touch_updated_at
before update on public.skills
for each row execute function public.set_updated_at();

create index if not exists skills_order_idx on public.skills (sort_order);

-- -----------------------------------------------------------------------------
-- services
-- -----------------------------------------------------------------------------
create table if not exists public.services (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  description  text not null default '',
  icon_key     text not null default 'spark',
  technologies text[] not null default '{}',
  is_published boolean not null default true,
  sort_order   integer not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint services_title_len check (char_length(title) between 2 and 60),
  constraint services_description_len check (char_length(description) <= 600)
);

drop trigger if exists services_touch_updated_at on public.services;
create trigger services_touch_updated_at
before update on public.services
for each row execute function public.set_updated_at();

create index if not exists services_order_idx on public.services (sort_order);

-- -----------------------------------------------------------------------------
-- timeline (experience + education in one ordered list)
-- -----------------------------------------------------------------------------
create table if not exists public.timeline (
  id           uuid primary key default gen_random_uuid(),
  kind         text not null default 'experience' check (kind in ('experience', 'education')),
  organization text not null,
  role         text not null,
  start_label  text not null,
  end_label    text,
  is_current   boolean not null default false,
  description  text,
  location     text,
  sort_order   integer not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint timeline_role_len check (char_length(role) between 2 and 80),
  constraint timeline_org_len check (char_length(organization) between 2 and 80)
);

drop trigger if exists timeline_touch_updated_at on public.timeline;
create trigger timeline_touch_updated_at
before update on public.timeline
for each row execute function public.set_updated_at();

create index if not exists timeline_order_idx on public.timeline (kind, sort_order);

-- -----------------------------------------------------------------------------
-- contact_messages — write-only for visitors, read-only for the admin
-- -----------------------------------------------------------------------------
create table if not exists public.contact_messages (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  email            text not null,
  subject          text,
  service_interest text,
  budget_range     text,
  message          text not null,
  status           text not null default 'unread'
                     check (status in ('unread', 'read', 'replied', 'archived')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint messages_name_len check (char_length(name) between 2 and 80),
  constraint messages_email_shape check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]{2,}$'),
  constraint messages_email_len check (char_length(email) <= 254),
  constraint messages_body_len check (char_length(message) between 12 and 2000),
  constraint messages_subject_len check (subject is null or char_length(subject) <= 120)
);

drop trigger if exists messages_touch_updated_at on public.contact_messages;
create trigger messages_touch_updated_at
before update on public.contact_messages
for each row execute function public.set_updated_at();

create index if not exists messages_inbox_idx
  on public.contact_messages (status, created_at desc);

-- Server-side spam guard: normalises input, blocks floods and link spam.
create or replace function public.guard_contact_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recent_count integer;
  link_count   integer;
begin
  -- Trim stray whitespace / control characters.
  new.name := btrim(regexp_replace(new.name, '[\u0000-\u001F\u007F]', '', 'g'));
  new.email := lower(btrim(new.email));
  new.message := btrim(regexp_replace(new.message, '[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]', '', 'g'));
  new.subject := nullif(btrim(coalesce(new.subject, '')), '');
  new.service_interest := nullif(btrim(coalesce(new.service_interest, '')), '');
  new.budget_range := nullif(btrim(coalesce(new.budget_range, '')), '');

  -- Never allow a visitor to choose a privileged state.
  new.status := 'unread';

  -- Link-spam heuristic (the client checks too; the server is authoritative).
  link_count := (length(new.message) - length(replace(lower(new.message), 'http', ''))) / 4;
  if link_count > 3 then
    raise exception 'Too many links in the message.' using errcode = '22023';
  end if;

  if new.message ~* '\m(seo services|guest post|backlinks|crypto giveaway|casino|viagra)\M' then
    raise exception 'Message flagged as spam.' using errcode = '22023';
  end if;

  -- Simple flood control: max 3 messages per email address in 10 minutes.
  select count(*) into recent_count
  from public.contact_messages
  where email = new.email
    and created_at > now() - interval '10 minutes';

  if recent_count >= 3 then
    raise exception 'Too many messages. Please try again later.' using errcode = '22023';
  end if;

  return new;
end;
$$;

revoke all on function public.guard_contact_message() from public;

drop trigger if exists contact_messages_guard on public.contact_messages;
create trigger contact_messages_guard
before insert on public.contact_messages
for each row execute function public.guard_contact_message();

-- -----------------------------------------------------------------------------
-- Admin dashboard helpers
-- -----------------------------------------------------------------------------
create or replace function public.inbox_counts()
returns table (unread integer, read integer, replied integer, archived integer)
language sql
stable
security definer
set search_path = public
as $$
  select
    count(*) filter (where status = 'unread')::int,
    count(*) filter (where status = 'read')::int,
    count(*) filter (where status = 'replied')::int,
    count(*) filter (where status = 'archived')::int
  from public.contact_messages
  where public.is_admin();
$$;

revoke all on function public.inbox_counts() from public;
grant execute on function public.inbox_counts() to authenticated;
