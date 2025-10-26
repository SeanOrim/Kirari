-- fix_rpc_refresh.sql
-- Run this to DROP and RE-CREATE the RPC with properties that PostgREST sees immediately.

-- Drop then create with STABLE + SECURITY DEFINER in public schema
drop function if exists public.get_email_for_username(text);

create or replace function public.get_email_for_username(u text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select email from public.profiles where username = u;
$$;

grant usage on schema public to anon, authenticated;
grant execute on function public.get_email_for_username(text) to anon, authenticated;

-- Optional: quick sanity check
-- select public.get_email_for_username('demo');
