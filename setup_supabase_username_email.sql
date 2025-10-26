-- setup_supabase_username_email.sql
-- Run this whole script in Supabase SQL Editor (Public schema).

-- 1) PROFILES: store username <-> email for each auth user
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (username ~ '^[A-Za-z0-9_.-]{3,30}$'),
  email text unique not null
);

-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;

-- Allow user to read/insert/update their own profile only
create policy if not exists "read own profile"
on public.profiles for select
using (auth.uid() = user_id);

create policy if not exists "insert own profile"
on public.profiles for insert
with check (auth.uid() = user_id);

create policy if not exists "update own profile"
on public.profiles for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- 2) RPC: get_email_for_username (username -> email)
create or replace function public.get_email_for_username(u text)
returns text
language sql
security definer
set search_path = public
as $$
  select email from public.profiles where username = u;
$$;

grant usage on schema public to anon, authenticated;
grant execute on function public.get_email_for_username(text) to anon, authenticated;

-- 3) READINGS table for your graphs (one row per user per day)
create table if not exists public.readings (
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  mineral double precision,
  moisture double precision,
  n_mineral integer,
  n_moisture integer,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now(),
  primary key (user_id, date)
);

-- Touch updated_at on update
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists trg_touch_readings on public.readings;
create trigger trg_touch_readings
before update on public.readings
for each row execute function public.touch_updated_at();

-- RLS for readings
alter table public.readings enable row level security;

create policy if not exists "read own readings"
on public.readings for select
using (auth.uid() = user_id);

create policy if not exists "insert own readings"
on public.readings for insert
with check (auth.uid() = user_id);

create policy if not exists "update own readings"
on public.readings for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Done.
