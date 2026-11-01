-- =============================================================================
-- Row Level Security
--
-- Public (anon) visitors can:
--   * read published projects, all skills, published services, the timeline,
--     and the single profile row;
--   * insert a contact message (validated + rate limited by trigger).
-- Only an admin (row in public.admin_users) can write portfolio content or
-- read/manage inquiries.
-- =============================================================================

alter table public.profiles         enable row level security;
alter table public.projects         enable row level security;
alter table public.skills           enable row level security;
alter table public.services         enable row level security;
alter table public.timeline         enable row level security;
alter table public.contact_messages enable row level security;
alter table public.admin_users      enable row level security;

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------
drop policy if exists "profiles are publicly readable" on public.profiles;
create policy "profiles are publicly readable"
  on public.profiles for select
  to anon, authenticated
  using (true);

drop policy if exists "admins can insert profile" on public.profiles;
create policy "admins can insert profile"
  on public.profiles for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "admins can update profile" on public.profiles;
create policy "admins can update profile"
  on public.profiles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins can delete profile" on public.profiles;
create policy "admins can delete profile"
  on public.profiles for delete
  to authenticated
  using (public.is_admin());

-- -----------------------------------------------------------------------------
-- projects: visitors only ever see published rows
-- -----------------------------------------------------------------------------
drop policy if exists "published projects are public" on public.projects;
create policy "published projects are public"
  on public.projects for select
  to anon, authenticated
  using (status = 'published' or public.is_admin());

drop policy if exists "admins can insert projects" on public.projects;
create policy "admins can insert projects"
  on public.projects for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "admins can update projects" on public.projects;
create policy "admins can update projects"
  on public.projects for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins can delete projects" on public.projects;
create policy "admins can delete projects"
  on public.projects for delete
  to authenticated
  using (public.is_admin());

-- -----------------------------------------------------------------------------
-- skills
-- -----------------------------------------------------------------------------
drop policy if exists "skills are publicly readable" on public.skills;
create policy "skills are publicly readable"
  on public.skills for select
  to anon, authenticated
  using (true);

drop policy if exists "admins manage skills" on public.skills;
create policy "admins manage skills"
  on public.skills for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- services
-- -----------------------------------------------------------------------------
drop policy if exists "published services are public" on public.services;
create policy "published services are public"
  on public.services for select
  to anon, authenticated
  using (is_published or public.is_admin());

drop policy if exists "admins manage services" on public.services;
create policy "admins manage services"
  on public.services for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- timeline
-- -----------------------------------------------------------------------------
drop policy if exists "timeline is publicly readable" on public.timeline;
create policy "timeline is publicly readable"
  on public.timeline for select
  to anon, authenticated
  using (true);

drop policy if exists "admins manage timeline" on public.timeline;
create policy "admins manage timeline"
  on public.timeline for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- contact_messages: visitors may insert only; nobody but the admin can read
-- -----------------------------------------------------------------------------
drop policy if exists "visitors can submit an inquiry" on public.contact_messages;
create policy "visitors can submit an inquiry"
  on public.contact_messages for insert
  to anon, authenticated
  with check (
    status = 'unread'
    and char_length(name) between 2 and 80
    and char_length(message) between 12 and 2000
    and email ~* '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]{2,}$'
  );

drop policy if exists "admins can read inquiries" on public.contact_messages;
create policy "admins can read inquiries"
  on public.contact_messages for select
  to authenticated
  using (public.is_admin());

drop policy if exists "admins can update inquiries" on public.contact_messages;
create policy "admins can update inquiries"
  on public.contact_messages for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins can delete inquiries" on public.contact_messages;
create policy "admins can delete inquiries"
  on public.contact_messages for delete
  to authenticated
  using (public.is_admin());

-- -----------------------------------------------------------------------------
-- admin_users: a signed-in user may verify their own membership; nobody can
-- modify the table through the API (manage it in the SQL editor).
-- -----------------------------------------------------------------------------
drop policy if exists "users can read their own admin row" on public.admin_users;
create policy "users can read their own admin row"
  on public.admin_users for select
  to authenticated
  using (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Table privileges (RLS still gates every row)
-- -----------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;

grant select on public.profiles, public.projects, public.skills,
  public.services, public.timeline to anon, authenticated;

grant insert on public.contact_messages to anon, authenticated;

grant select, insert, update, delete on public.projects, public.skills,
  public.services, public.timeline, public.profiles to authenticated;

grant select, update, delete on public.contact_messages to authenticated;
grant select on public.admin_users to authenticated;
