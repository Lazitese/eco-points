-- ============================================================
-- Eco Points — Supabase Schema
-- Run this in the Supabase SQL Editor
-- ============================================================

-- ── 1. Profiles table ─────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text not null default 'Eco Hero',
  total_points  integer not null default 0,
  created_at    timestamptz not null default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Policies
create policy "Users can read all profiles"
  on public.profiles for select
  using (true);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);


-- ── 2. Activities table ────────────────────────────────────────────────────────
create table if not exists public.activities (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles(id) on delete cascade,
  type             text not null check (type in ('walk', 'meal')),
  points           integer not null default 0,
  status           text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  -- Walk-specific
  distance_km      numeric(8, 3),
  duration_seconds integer,
  -- Meal-specific
  photo_url        text,
  created_at       timestamptz not null default now()
);

-- Enable RLS
alter table public.activities enable row level security;

-- Policies
create policy "Users can read own activities"
  on public.activities for select
  using (auth.uid() = user_id);

create policy "Users can insert own activities"
  on public.activities for insert
  with check (auth.uid() = user_id);


-- ── 3. increment_points RPC ────────────────────────────────────────────────────
-- Called after a walk is saved to atomically add points to the profile.
create or replace function public.increment_points(uid uuid, delta integer)
returns void
language plpgsql
security definer
as $$
begin
  update public.profiles
  set total_points = total_points + delta
  where id = uid;
end;
$$;


-- ── 4. Auto-create profile on sign-up ─────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', 'Eco Hero')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ── 5. Realtime ────────────────────────────────────────────────────────────────
-- Enable realtime for leaderboard and home screen live updates
alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.activities;


-- ── 6. Storage bucket ─────────────────────────────────────────────────────────
-- Run in Supabase Dashboard → Storage → New Bucket
-- Name: verification-photos
-- Public: true (so photo URLs are accessible)
--
-- Or via SQL:
insert into storage.buckets (id, name, public)
values ('verification-photos', 'verification-photos', true)
on conflict (id) do nothing;

-- Storage RLS: users can upload to their own folder
create policy "Users can upload own photos"
  on storage.objects for insert
  with check (
    bucket_id = 'verification-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Anyone can view verification photos"
  on storage.objects for select
  using (bucket_id = 'verification-photos');
