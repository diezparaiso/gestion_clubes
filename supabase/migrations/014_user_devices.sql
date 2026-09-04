do $$
begin
  create type public.device_platform as enum ('web', 'android', 'ios');
exception
  when duplicate_object then null;
end;
$$;

do $$
begin
  create type public.permission_status as enum ('unknown', 'granted', 'denied');
exception
  when duplicate_object then null;
end;
$$;

create table public.user_devices (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  platform public.device_platform not null,
  token text not null check (length(trim(token)) > 0),
  permission_status public.permission_status not null default 'unknown',
  last_seen_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (platform, token)
);

create index user_devices_profile_idx on public.user_devices (profile_id, platform);
create trigger user_devices_set_updated_at before update on public.user_devices for each row execute function public.set_updated_at();
alter table public.user_devices enable row level security;
create policy user_devices_select_own on public.user_devices for select to authenticated using (profile_id = auth.uid());
create policy user_devices_insert_own on public.user_devices for insert to authenticated with check (profile_id = auth.uid());
create policy user_devices_update_own on public.user_devices for update to authenticated using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy user_devices_delete_own on public.user_devices for delete to authenticated using (profile_id = auth.uid());