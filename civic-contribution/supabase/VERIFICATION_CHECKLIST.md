# Supabase Verification Checklist (Civic Contribution)

Use this after running the migration SQL.

## 1) Confirm required tables exist

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('users', 'communities', 'issues', 'micro_tasks', 'verifications')
order by table_name;
```

Expected: 5 rows.

---

## 2) Confirm required RPC functions exist

```sql
select p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'upvote_issue',
    'merge_issue',
    'increment_user_credits',
    'increment_user_stat',
    'add_user_badge',
    'reset_community_users',
    'increment_community_members',
    'add_community_admin',
    'remove_community_admin',
    'leave_community'
  )
order by p.proname;
```

Expected: 10 rows.

---

## 3) Confirm RLS is enabled on all app tables

```sql
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('users', 'communities', 'issues', 'micro_tasks', 'verifications')
order by tablename;
```

Expected: `rowsecurity = true` for all 5 rows.

---

## 4) Confirm policies exist

```sql
select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname in ('public', 'storage')
  and (
    tablename in ('users', 'communities', 'issues', 'micro_tasks', 'verifications')
    or tablename = 'objects'
  )
order by schemaname, tablename, policyname;
```

Expected: policies for all public tables and storage `objects`.

---

## 5) Confirm storage buckets exist

```sql
select id, name, public
from storage.buckets
where id in ('issues', 'verifications')
order by id;
```

Expected: 2 rows, both present.

---

## 6) Confirm grants for authenticated role

```sql
select routine_name
from information_schema.role_routine_grants
where specific_schema = 'public'
  and grantee = 'authenticated'
  and routine_name in (
    'upvote_issue',
    'merge_issue',
    'increment_user_credits',
    'increment_user_stat',
    'add_user_badge',
    'reset_community_users',
    'increment_community_members',
    'add_community_admin',
    'remove_community_admin',
    'leave_community'
  )
order by routine_name;
```

Expected: 10 rows.

---

## 7) RPC smoke test (safe, with rollback)

Run the full block below in SQL Editor. It creates test rows, executes all RPCs, verifies outcomes, then rolls back.

```sql
begin;

do $$
declare
  u1 uuid := gen_random_uuid();
  u2 uuid := gen_random_uuid();
  c1 uuid := gen_random_uuid();
  issue1 uuid := gen_random_uuid();
  issue2 uuid := gen_random_uuid();
  upvoter_count integer;
  merged_count integer;
  issue2_status text;
  credits integer;
  tasks integer;
  badges_count integer;
  members integer;
  user2_community uuid;
begin
  insert into public.communities (id, name, created_by, admin_uids, member_count)
  values (c1, 'QA Community', u1, array[u1], 1);

  insert into public.users (id, display_name, community_id, is_admin)
  values
    (u1, 'QA User 1', c1, true),
    (u2, 'QA User 2', c1, false);

  insert into public.issues (
    id, reporter_id, category, description, latitude, longitude, address, status, community_id
  ) values
    (issue1, u1, 'other', 'Issue 1', 12.9716, 77.5946, 'Test Address 1', 'pending', c1),
    (issue2, u1, 'other', 'Issue 2', 12.9717, 77.5947, 'Test Address 2', 'pending', c1);

  perform public.upvote_issue(issue1, u2);
  perform public.upvote_issue(issue1, u2); -- idempotency check

  select coalesce(array_length(upvoter_ids, 1), 0)
    into upvoter_count
  from public.issues
  where id = issue1;

  if upvoter_count <> 1 then
    raise exception 'upvote_issue failed idempotency, got %', upvoter_count;
  end if;

  perform public.merge_issue(issue1, issue2);

  select coalesce(array_length(merged_issue_ids, 1), 0)
    into merged_count
  from public.issues
  where id = issue1;

  select status into issue2_status
  from public.issues
  where id = issue2;

  if merged_count < 1 then
    raise exception 'merge_issue did not append duplicate id';
  end if;

  if issue2_status <> 'resolved' then
    raise exception 'merge_issue did not mark duplicate as resolved: %', issue2_status;
  end if;

  perform public.increment_user_credits(u2, 10);
  select civic_credits into credits from public.users where id = u2;
  if credits <> 10 then
    raise exception 'increment_user_credits failed: %', credits;
  end if;

  perform public.increment_user_stat(u2, 'tasks_completed');
  select tasks_completed into tasks from public.users where id = u2;
  if tasks <> 1 then
    raise exception 'increment_user_stat failed: %', tasks;
  end if;

  perform public.add_user_badge(
    u2,
    jsonb_build_object(
      'id', 'qa-badge',
      'label', 'QA Badge',
      'emoji', '✅',
      'earned_at', now()
    )
  );

  select jsonb_array_length(badges) into badges_count from public.users where id = u2;
  if badges_count < 1 then
    raise exception 'add_user_badge failed';
  end if;

  perform public.increment_community_members(c1, 2);
  select member_count into members from public.communities where id = c1;
  if members <> 3 then
    raise exception 'increment_community_members failed: %', members;
  end if;

  perform public.add_community_admin(c1, u2);
  if not exists (
    select 1 from public.communities where id = c1 and u2 = any(admin_uids)
  ) then
    raise exception 'add_community_admin failed';
  end if;

  perform public.remove_community_admin(c1, u2);
  if exists (
    select 1 from public.communities where id = c1 and u2 = any(admin_uids)
  ) then
    raise exception 'remove_community_admin failed';
  end if;

  perform public.leave_community(c1, u2);

  select member_count into members from public.communities where id = c1;
  select community_id into user2_community from public.users where id = u2;

  if members <> 2 then
    raise exception 'leave_community member_count failed: %', members;
  end if;

  if user2_community is not null then
    raise exception 'leave_community user community not cleared';
  end if;

  perform public.reset_community_users(c1);

  if exists (
    select 1
    from public.users
    where id in (u1, u2)
      and community_id is not null
  ) then
    raise exception 'reset_community_users failed';
  end if;
end
$$;

rollback;
```

Expected: script completes with no exception.

---

## 8) App-side checks (real client/RLS path)

After SQL checks pass:

1. Sign in with Google from app.
2. Create/select a community.
3. Report an issue with photo.
4. Upvote issue from second account/device.
5. Add a micro-task and mark complete.
6. Add a verification photo.

Expected: no 401/403/permission errors in app logs.

---

## 9) Useful debug queries

```sql
select count(*) as users from public.users;
select count(*) as communities from public.communities;
select count(*) as issues from public.issues;
select count(*) as micro_tasks from public.micro_tasks;
select count(*) as verifications from public.verifications;
```
