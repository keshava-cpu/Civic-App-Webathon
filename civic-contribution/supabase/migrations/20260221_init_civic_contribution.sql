-- Civic Contribution: Supabase schema + RPC + RLS + storage
-- Run this in Supabase SQL Editor (or via supabase db push)

create extension if not exists pgcrypto;

-- ─────────────────────────────────────────────────────────────
-- Tables
-- ─────────────────────────────────────────────────────────────

create table if not exists public.users (
  id uuid primary key,
  display_name text not null default '',
  avatar_url text,
  trust_score double precision not null default 0.5,
  civic_credits integer not null default 0,
  badges jsonb not null default '[]'::jsonb,
  issues_reported integer not null default 0,
  verifications_completed integer not null default 0,
  tasks_completed integer not null default 0,
  is_admin boolean not null default false,
  community_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.communities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null,
  admin_uids uuid[] not null default '{}',
  member_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'users_community_id_fkey'
  ) then
    alter table public.users
      add constraint users_community_id_fkey
      foreign key (community_id) references public.communities(id) on delete set null;
  end if;
end
$$;

create table if not exists public.issues (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null,
  category text not null,
  description text not null default '',
  latitude double precision not null,
  longitude double precision not null,
  address text not null default '',
  photo_url text,
  photo_hash text,
  p_hash_value text,
  exif_data jsonb,
  status text not null default 'pending',
  priority_score integer not null default 0,
  upvoter_ids uuid[] not null default '{}',
  merged_issue_ids uuid[] not null default '{}',
  assigned_to uuid,
  community_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint issues_reporter_fk foreign key (reporter_id) references public.users(id) on delete cascade,
  constraint issues_assigned_to_fk foreign key (assigned_to) references public.users(id) on delete set null,
  constraint issues_community_fk foreign key (community_id) references public.communities(id) on delete set null,
  constraint issues_status_check check (status in ('pending','assigned','inProgress','resolved','verified'))
);

create table if not exists public.micro_tasks (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid not null references public.issues(id) on delete cascade,
  title text not null,
  assignee_id uuid references public.users(id) on delete set null,
  completed boolean not null default false,
  completed_at timestamptz,
  completed_latitude double precision,
  completed_longitude double precision,
  created_at timestamptz not null default now()
);

create table if not exists public.verifications (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid not null references public.issues(id) on delete cascade,
  verifier_id uuid not null references public.users(id) on delete cascade,
  photo_url text,
  is_resolved boolean not null default false,
  comment text not null default '',
  verifier_trust_score double precision not null default 0.5,
  created_at timestamptz not null default now(),
  credits_awarded integer not null default 0,
  is_reversed boolean not null default false,
  is_locked boolean not null default false
);

-- ─────────────────────────────────────────────────────────────
-- Indexes
-- ─────────────────────────────────────────────────────────────

create index if not exists idx_issues_created_at on public.issues (created_at desc);
create index if not exists idx_issues_community_created on public.issues (community_id, created_at desc);
create index if not exists idx_issues_status on public.issues (status);
create index if not exists idx_micro_tasks_issue on public.micro_tasks (issue_id);
create index if not exists idx_verifications_issue on public.verifications (issue_id);
create index if not exists idx_users_credits on public.users (civic_credits desc);
create index if not exists idx_users_community on public.users (community_id);
create index if not exists idx_communities_name on public.communities (name);

-- ─────────────────────────────────────────────────────────────
-- Updated-at trigger
-- ─────────────────────────────────────────────────────────────

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_users_touch_updated_at on public.users;
create trigger trg_users_touch_updated_at
before update on public.users
for each row execute function public.touch_updated_at();

drop trigger if exists trg_issues_touch_updated_at on public.issues;
create trigger trg_issues_touch_updated_at
before update on public.issues
for each row execute function public.touch_updated_at();

drop trigger if exists trg_communities_touch_updated_at on public.communities;
create trigger trg_communities_touch_updated_at
before update on public.communities
for each row execute function public.touch_updated_at();

-- ─────────────────────────────────────────────────────────────
-- RPC functions expected by app code
-- ─────────────────────────────────────────────────────────────

create or replace function public.upvote_issue(issue_id uuid, user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.issues i
     set upvoter_ids = case
         when i.upvoter_ids @> array[user_id]::uuid[] then i.upvoter_ids
         else array_append(i.upvoter_ids, user_id)
       end,
       priority_score = case
         when i.upvoter_ids @> array[user_id]::uuid[] then i.priority_score
         else i.priority_score + 1
       end,
       updated_at = now()
   where i.id = issue_id;
end;
$$;

create or replace function public.merge_issue(target_id uuid, duplicate_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target_id = duplicate_id then
    return;
  end if;

  update public.issues t
     set merged_issue_ids = case
         when t.merged_issue_ids @> array[duplicate_id]::uuid[] then t.merged_issue_ids
         else array_append(t.merged_issue_ids, duplicate_id)
       end,
       updated_at = now()
   where t.id = target_id;

  update public.issues d
     set status = 'resolved',
       updated_at = now()
   where d.id = duplicate_id;
end;
$$;

create or replace function public.increment_user_credits(user_id uuid, points integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users
     set civic_credits = coalesce(civic_credits, 0) + coalesce(points, 0),
         updated_at = now()
   where id = user_id;
end;
$$;

create or replace function public.increment_user_stat(user_id uuid, field_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if field_name = 'issues_reported' then
    update public.users set issues_reported = issues_reported + 1, updated_at = now() where id = user_id;
  elsif field_name = 'verifications_completed' then
    update public.users set verifications_completed = verifications_completed + 1, updated_at = now() where id = user_id;
  elsif field_name = 'tasks_completed' then
    update public.users set tasks_completed = tasks_completed + 1, updated_at = now() where id = user_id;
  else
    raise exception 'Unsupported field_name: %', field_name;
  end if;
end;
$$;

create or replace function public.add_user_badge(user_id uuid, badge jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users
     set badges = coalesce(badges, '[]'::jsonb) || jsonb_build_array(badge),
         updated_at = now()
   where id = user_id;
end;
$$;

create or replace function public.reset_community_users(p_community_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users
     set community_id = null,
         is_admin = false,
         updated_at = now()
   where community_id = p_community_id;
end;
$$;

create or replace function public.increment_community_members(community_id uuid, delta integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.communities
     set member_count = greatest(0, member_count + coalesce(delta, 0)),
         updated_at = now()
   where id = community_id;
end;
$$;

create or replace function public.add_community_admin(community_id uuid, user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.communities c
     set admin_uids = case
         when c.admin_uids @> array[user_id]::uuid[] then c.admin_uids
         else array_append(c.admin_uids, user_id)
       end,
       updated_at = now()
   where c.id = community_id;
end;
$$;

create or replace function public.remove_community_admin(community_id uuid, user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.communities c
     set admin_uids = array_remove(c.admin_uids, user_id),
         updated_at = now()
   where c.id = community_id;
end;
$$;

create or replace function public.leave_community(community_id uuid, user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.communities c
     set admin_uids = array_remove(c.admin_uids, user_id),
         member_count = greatest(0, c.member_count - 1),
         updated_at = now()
   where c.id = community_id;

  update public.users u
     set community_id = null,
         is_admin = false,
         updated_at = now()
   where u.id = user_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RLS + Policies (authenticated app users)
-- ─────────────────────────────────────────────────────────────

alter table public.users enable row level security;
alter table public.communities enable row level security;
alter table public.issues enable row level security;
alter table public.micro_tasks enable row level security;
alter table public.verifications enable row level security;

-- users
DROP POLICY IF EXISTS users_select_authenticated ON public.users;
create policy users_select_authenticated on public.users
for select to authenticated using (true);

DROP POLICY IF EXISTS users_insert_own ON public.users;
create policy users_insert_own on public.users
for insert to authenticated with check (id = auth.uid());

DROP POLICY IF EXISTS users_update_own_or_admin ON public.users;
create policy users_update_own_or_admin on public.users
for update to authenticated
using (id = auth.uid() or exists (select 1 from public.users me where me.id = auth.uid() and me.is_admin = true))
with check (id = auth.uid() or exists (select 1 from public.users me where me.id = auth.uid() and me.is_admin = true));

DROP POLICY IF EXISTS users_delete_own_or_admin ON public.users;
create policy users_delete_own_or_admin on public.users
for delete to authenticated
using (id = auth.uid() or exists (select 1 from public.users me where me.id = auth.uid() and me.is_admin = true));

-- communities
DROP POLICY IF EXISTS communities_select_authenticated ON public.communities;
create policy communities_select_authenticated on public.communities
for select to authenticated using (true);

DROP POLICY IF EXISTS communities_insert_authenticated ON public.communities;
create policy communities_insert_authenticated on public.communities
for insert to authenticated with check (created_by = auth.uid());

DROP POLICY IF EXISTS communities_update_admin_only ON public.communities;
create policy communities_update_admin_only on public.communities
for update to authenticated
using (auth.uid() = any(admin_uids) or created_by = auth.uid())
with check (auth.uid() = any(admin_uids) or created_by = auth.uid());

DROP POLICY IF EXISTS communities_delete_admin_only ON public.communities;
create policy communities_delete_admin_only on public.communities
for delete to authenticated
using (auth.uid() = any(admin_uids) or created_by = auth.uid());

-- issues
DROP POLICY IF EXISTS issues_select_authenticated ON public.issues;
create policy issues_select_authenticated on public.issues
for select to authenticated using (true);

DROP POLICY IF EXISTS issues_insert_authenticated ON public.issues;
create policy issues_insert_authenticated on public.issues
for insert to authenticated with check (reporter_id = auth.uid());

DROP POLICY IF EXISTS issues_update_authenticated ON public.issues;
create policy issues_update_authenticated on public.issues
for update to authenticated using (true) with check (true);

DROP POLICY IF EXISTS issues_delete_owner_or_admin ON public.issues;
create policy issues_delete_owner_or_admin on public.issues
for delete to authenticated
using (
  reporter_id = auth.uid()
  or exists (select 1 from public.users me where me.id = auth.uid() and me.is_admin = true)
);

-- micro_tasks
DROP POLICY IF EXISTS micro_tasks_select_authenticated ON public.micro_tasks;
create policy micro_tasks_select_authenticated on public.micro_tasks
for select to authenticated using (true);

DROP POLICY IF EXISTS micro_tasks_cud_authenticated ON public.micro_tasks;
create policy micro_tasks_cud_authenticated on public.micro_tasks
for all to authenticated using (true) with check (true);

-- verifications
DROP POLICY IF EXISTS verifications_select_authenticated ON public.verifications;
create policy verifications_select_authenticated on public.verifications
for select to authenticated using (true);

DROP POLICY IF EXISTS verifications_insert_authenticated ON public.verifications;
create policy verifications_insert_authenticated on public.verifications
for insert to authenticated with check (verifier_id = auth.uid());

DROP POLICY IF EXISTS verifications_update_authenticated ON public.verifications;
create policy verifications_update_authenticated on public.verifications
for update to authenticated using (true) with check (true);

DROP POLICY IF EXISTS verifications_delete_owner_or_admin ON public.verifications;
create policy verifications_delete_owner_or_admin on public.verifications
for delete to authenticated
using (
  verifier_id = auth.uid()
  or exists (select 1 from public.users me where me.id = auth.uid() and me.is_admin = true)
);

-- ─────────────────────────────────────────────────────────────
-- Storage buckets + policies
-- ─────────────────────────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('issues', 'issues', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('verifications', 'verifications', true)
on conflict (id) do nothing;

DROP POLICY IF EXISTS storage_public_read_issues ON storage.objects;
create policy storage_public_read_issues on storage.objects
for select to public
using (bucket_id = 'issues');

DROP POLICY IF EXISTS storage_public_read_verifications ON storage.objects;
create policy storage_public_read_verifications on storage.objects
for select to public
using (bucket_id = 'verifications');

DROP POLICY IF EXISTS storage_auth_insert_issues ON storage.objects;
create policy storage_auth_insert_issues on storage.objects
for insert to authenticated
with check (bucket_id = 'issues');

DROP POLICY IF EXISTS storage_auth_insert_verifications ON storage.objects;
create policy storage_auth_insert_verifications on storage.objects
for insert to authenticated
with check (bucket_id = 'verifications');

DROP POLICY IF EXISTS storage_auth_update_issues ON storage.objects;
create policy storage_auth_update_issues on storage.objects
for update to authenticated
using (bucket_id = 'issues')
with check (bucket_id = 'issues');

DROP POLICY IF EXISTS storage_auth_update_verifications ON storage.objects;
create policy storage_auth_update_verifications on storage.objects
for update to authenticated
using (bucket_id = 'verifications')
with check (bucket_id = 'verifications');

DROP POLICY IF EXISTS storage_auth_delete_issues ON storage.objects;
create policy storage_auth_delete_issues on storage.objects
for delete to authenticated
using (bucket_id = 'issues');

DROP POLICY IF EXISTS storage_auth_delete_verifications ON storage.objects;
create policy storage_auth_delete_verifications on storage.objects
for delete to authenticated
using (bucket_id = 'verifications');

-- ─────────────────────────────────────────────────────────────
-- Grants for RPC execution
-- ─────────────────────────────────────────────────────────────

grant usage on schema public to authenticated;
grant execute on function public.upvote_issue(uuid, uuid) to authenticated;
grant execute on function public.merge_issue(uuid, uuid) to authenticated;
grant execute on function public.increment_user_credits(uuid, integer) to authenticated;
grant execute on function public.increment_user_stat(uuid, text) to authenticated;
grant execute on function public.add_user_badge(uuid, jsonb) to authenticated;
grant execute on function public.reset_community_users(uuid) to authenticated;
grant execute on function public.increment_community_members(uuid, integer) to authenticated;
grant execute on function public.add_community_admin(uuid, uuid) to authenticated;
grant execute on function public.remove_community_admin(uuid, uuid) to authenticated;
grant execute on function public.leave_community(uuid, uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- ENABLE REALTIME FOR ALL TABLES
-- ─────────────────────────────────────────────────────────────
-- Without this, Supabase .stream() subscriptions won't receive
-- real-time updates when data changes.

ALTER PUBLICATION supabase_realtime ADD TABLE public.issues;
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
ALTER PUBLICATION supabase_realtime ADD TABLE public.verifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.micro_tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.communities;
