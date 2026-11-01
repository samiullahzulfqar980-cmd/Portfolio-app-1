-- =============================================================================
-- Storage buckets + policies
--
--   profile-images  public read, admin write   (avatar)
--   project-images  public read, admin write   (project covers)
--   resume-files    public read, admin write   (PDF résumé)
--
-- Everything is public *read* because it is portfolio content; writes are
-- restricted to the authorised admin so a visitor can never upload or replace
-- an asset.
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('profile-images', 'profile-images', true, 5242880,
    array['image/jpeg', 'image/png', 'image/webp']),
  ('project-images', 'project-images', true, 5242880,
    array['image/jpeg', 'image/png', 'image/webp']),
  ('resume-files', 'resume-files', true, 10485760,
    array['application/pdf'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- -----------------------------------------------------------------------------
-- Public read for portfolio assets
-- -----------------------------------------------------------------------------
drop policy if exists "portfolio assets are publicly readable" on storage.objects;
create policy "portfolio assets are publicly readable"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id in ('profile-images', 'project-images', 'resume-files'));

-- -----------------------------------------------------------------------------
-- Admin-only writes
-- -----------------------------------------------------------------------------
drop policy if exists "admins can upload portfolio assets" on storage.objects;
create policy "admins can upload portfolio assets"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id in ('profile-images', 'project-images', 'resume-files')
    and public.is_admin()
  );

drop policy if exists "admins can replace portfolio assets" on storage.objects;
create policy "admins can replace portfolio assets"
  on storage.objects for update
  to authenticated
  using (
    bucket_id in ('profile-images', 'project-images', 'resume-files')
    and public.is_admin()
  )
  with check (
    bucket_id in ('profile-images', 'project-images', 'resume-files')
    and public.is_admin()
  );

drop policy if exists "admins can delete portfolio assets" on storage.objects;
create policy "admins can delete portfolio assets"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id in ('profile-images', 'project-images', 'resume-files')
    and public.is_admin()
  );

-- Deliberately no policy for anon insert/update/delete: visitors cannot write.
